import copy
import json
import subprocess
import unittest
from unittest.mock import patch
from pathlib import Path
from import_catalogue import ROOT, digest, load_catalogue, render_import, require_local_docker, validate_item

DOCKER = ['docker', 'exec', '-i', 'supabase_db_cool-spot-prototype', 'psql', '-U', 'postgres', '-d', 'postgres', '-X', '--no-password', '-v', 'ON_ERROR_STOP=1', '-qAt']

def sql(statement):
    return subprocess.run(DOCKER, input=statement, text=True, capture_output=True)


def disposable_catalogue():
    plan=load_catalogue()
    for source in plan['sources']:
        source['id']='db-import-test-'+source['id']
        source['metadata']['id']=source['id']
    for record in plan['records']:
        item=record['item']
        item['id']='db-import-test-'+item['id']
        record['source_id']='db-import-test-'+record['source_id']
        for reference in item['sourceReferences']+item['provenance']:
            reference['sourceID']='db-import-test-'+reference['sourceID']
        for evidence in record['fields']: evidence['source_id']=record['source_id']
        for link in item['mapReferences']: link['placeID']='db-import-test-'+link['placeID']
        for photo in item['photos']: photo['id']='db-import-test-'+photo['id']
        record.pop('fingerprint')
        record['fingerprint']=digest(record)
    return plan

class InputTests(unittest.TestCase):
    def setUp(self):
        self.item = json.loads((ROOT/'cool-spot/Resources/CoolSpots.prototype.json').read_text())['items'][0]

    def test_preserves_all_catalogue_identities_and_source_snapshots(self):
        plan = load_catalogue()
        self.assertEqual(len(plan['records']), 253)
        self.assertEqual(len(plan['sources']), 2)
        first = plan['records'][0]
        self.assertEqual(first['item']['id'], '5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab')
        self.assertEqual(first['record_id'], '18')
        self.assertEqual(first['raw_data']['properties']['cs_name'], 'Canning Town Library')
        self.assertEqual(first['item'], self.item)
        self.assertEqual(first['document_metadata']['datasetID'], 'gla-2025-all')
        self.assertEqual(first['document_metadata']['schemaVersion'], 4)
        self.assertEqual(first['item']['mapReferences'][0]['placeID'], 'I7E8561E6022ED614')
        self.assertNotIn('places.location_scope', [x['field_key'] for x in first['fields']])

    def test_rejects_invalid_original_coordinates_before_geography_conversion(self):
        for key, values in [('latitude', [90.001, -90.001, float('nan'), float('inf'), True, '51']), ('longitude', [180.001, -180.001, float('-inf'), None])]:
            for value in values:
                with self.subTest(key=key, value=value):
                    item = copy.deepcopy(self.item)
                    item['location'][key] = value
                    with self.assertRaises(ValueError): validate_item(item)

    def test_accepts_zero_and_geographic_boundaries_without_swapping(self):
        for lat, lon in [(0, 0), (-90, -180), (90, 180), (51.516829995, 0.010439996)]:
            item = copy.deepcopy(self.item)
            item['location'].update(latitude=lat, longitude=lon)
            before = copy.deepcopy(item)
            validate_item(item)
            self.assertEqual(item, before)

    def test_rejects_invalid_content_and_accepts_null_optional_area(self):
        validate_item(self.item)
        mutations = [lambda i: i.update(name=' \u3000'), lambda i: i.update(coolingFeatures=['drinking_water']),
                     lambda i: i['access'].update(cost='maybe'), lambda i: i['access'].update(postedStayLimit={'status':'limited','minutes':0}),
                     lambda i: i['address'].update(countryCode='gb'), lambda i: i.update(additionalInformation='\t')]
        for mutate in mutations:
            item = copy.deepcopy(self.item); mutate(item)
            with self.subTest(item=item['name']):
                with self.assertRaises(ValueError): validate_item(item)

class LocalTargetTests(unittest.TestCase):
    def test_remote_docker_host_is_rejected_before_inspecting_or_writing(self):
        with patch.dict('os.environ', {'DOCKER_HOST':'ssh://remote.example'}), patch('import_catalogue.subprocess.run') as run:
            with self.assertRaises(ValueError): require_local_docker()
            run.assert_not_called()

    def test_remote_context_is_rejected_and_local_context_name_is_pinned(self):
        for endpoint, allowed in [('ssh://remote.example',False),('tcp://remote.example:2376',False),('unix:///var/run/docker.sock',True)]:
            completed=subprocess.CompletedProcess([],0,json.dumps([{'Name':'verified-context','Endpoints':{'docker':{'Host':endpoint}}}]),'')
            with self.subTest(endpoint=endpoint), patch.dict('os.environ',{'DOCKER_HOST':''}), patch('import_catalogue.subprocess.run',return_value=completed):
                if allowed: self.assertEqual(require_local_docker(),'verified-context')
                else:
                    with self.assertRaises(ValueError): require_local_docker()

class LocalImportTests(unittest.TestCase):
    def test_original_catalogue_retry_preserves_all_existing_rows_and_snapshots(self):
        # Original records were imported before the naming migration. A retry
        # must recognize their existing hashes, not manufacture a new import.
        tables = ['places', 'cool_spots', 'data_sources', 'source_records',
                  'place_source_links', 'place_field_inference_records',
                  'place_map_links', 'place_photos', 'catalogue_import_history']
        before = '\n'.join('create temporary table retry_before_'+table+
            ' as select to_jsonb(t) as row from public.'+table+' t;' for table in tables)
        after = '\n'.join("do $$ begin if exists ((select row from retry_before_"+table+
            ") except all (select to_jsonb(t) from public."+table+" t)) or exists ((select to_jsonb(t) from public."+table+
            " t) except all (select row from retry_before_"+table+")) then raise exception 'Retry changed "+table+
            "'; end if; end $$;" for table in tables)
        imported = render_import(load_catalogue(), commit=False).removeprefix('begin;\n').removesuffix('rollback;\n')
        result = sql('begin;\n'+before+'\n'+imported+'\n'+after+'\nrollback;')
        self.assertEqual(result.returncode,0,result.stderr)

    def test_imports_full_content_evidence_photos_and_stable_id_links_then_rolls_back(self):
        checks = """
do $$ begin
 if (select count(*) from catalogue_import_history where cool_spot_id like 'db-import-test-%') <> 253 then raise exception 'expected 253 imports'; end if;
 if not exists(select 1 from places p join cool_spots c on c.place_id=p.id where c.id='db-import-test-5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab' and p.name='Canning Town Library' and p.address_borough='Newham' and c.cooling_features=array['air_conditioning'] and c.drinking_water='yes' and abs(gis.st_x(p.location::gis.geometry)-0.010439996)<0.000000001 and abs(gis.st_y(p.location::gis.geometry)-51.516829995)<0.000000001) then raise exception 'incorrect adopted facts or coordinates'; end if;

 if exists (
  select 1 from source_records s join place_source_links l on l.source_id=s.source_id and l.source_record_id=s.source_record_id
  join places p on p.id=l.place_id join cool_spots c on c.place_id=p.id
  join catalogue_import_history h on h.cool_spot_id=c.id
  where s.source_id like 'db-import-test-%' and (
   (p.name,p.place_type,p.address_line1,p.address_line2,p.address_locality,p.address_borough,p.address_postal_code,p.address_country_code,p.address_formatted)
   is distinct from ((h.evidence_snapshot->'item')->>'name',(h.evidence_snapshot->'item')->>'placeType',(h.evidence_snapshot->'item')#>>'{address,line1}',(h.evidence_snapshot->'item')#>>'{address,line2}',(h.evidence_snapshot->'item')#>>'{address,locality}',(h.evidence_snapshot->'item')#>>'{address,borough}',(h.evidence_snapshot->'item')#>>'{address,postalCode}',(h.evidence_snapshot->'item')#>>'{address,countryCode}',(h.evidence_snapshot->'item')#>>'{address,formatted}')
   or abs(gis.st_x(p.location::gis.geometry)-((h.evidence_snapshot->'item')#>>'{location,longitude}')::double precision)>1e-9
   or abs(gis.st_y(p.location::gis.geometry)-((h.evidence_snapshot->'item')#>>'{location,latitude}')::double precision)>1e-9
   or (to_jsonb(c)-'id'-'place_id') is distinct from jsonb_build_object(
     'setting',(h.evidence_snapshot->'item')->'setting','cooling_features',(h.evidence_snapshot->'item')->'coolingFeatures',
     'cooling_details',(h.evidence_snapshot->'item')->'coolingDetails','additional_information',(h.evidence_snapshot->'item')->'additionalInformation',
     'area_description',(h.evidence_snapshot->'item')#>'{access,areaDescription}','cost',(h.evidence_snapshot->'item')#>'{access,cost}',
     'eligibility',(h.evidence_snapshot->'item')#>'{access,eligibility}','seating',(h.evidence_snapshot->'item')#>'{access,seating}',
     'drinking_water',(h.evidence_snapshot->'item')#>'{access,drinkingWater}','toilets',(h.evidence_snapshot->'item')#>'{access,toilets}',
     'wheelchair_access',(h.evidence_snapshot->'item')#>'{access,wheelchairAccess}','staffed_when_open',(h.evidence_snapshot->'item')#>'{access,staffedWhenOpen}',
     'tables',(h.evidence_snapshot->'item')#>'{access,tables}','posted_stay_limit_status',(h.evidence_snapshot->'item')#>'{access,postedStayLimit,status}',
     'posted_stay_limit_minutes',(h.evidence_snapshot->'item')#>'{access,postedStayLimit,minutes}',
     'hours_text',(h.evidence_snapshot->'item')#>'{hours,text}','hours_time_zone',(h.evidence_snapshot->'item')#>'{hours,timeZone}')
  )
 ) then raise exception 'one or more adopted fields differ from the input'; end if;
 if (select count(*) from place_photos where id like 'db-import-test-%') <> 3 then raise exception 'expected three labelled photos'; end if;
 if (select count(*) from place_map_links where external_place_id like 'db-import-test-%') <> 145 then raise exception 'accepted Apple links not preserved'; end if;
 if (select count(*) from place_map_links where relationship='within_place' and external_place_id like 'db-import-test-%') <> 1 then raise exception 'containment evidence changed'; end if;
 if (select count(*) from source_records where source_id like 'db-import-test-%') <> 253 then raise exception 'raw records missing'; end if;
 if exists(select 1 from catalogue_import_history h join places p on p.id=h.place_id join cool_spots c on c.id=h.cool_spot_id where h.cool_spot_id like 'db-import-test-%' and (h.place_snapshot<>to_jsonb(p) or h.cool_spot_snapshot<>to_jsonb(c))) then raise exception 'initial history differs from current facts'; end if;
end $$;
"""
        result=sql(render_import(disposable_catalogue(), commit=False, checks=checks))
        self.assertEqual(result.returncode,0,result.stderr)

    def test_identical_retry_does_not_duplicate_or_overwrite_a_later_local_value(self):
        plan=disposable_catalogue()
        second=render_import(plan, commit=False)
        # Exercise the same import statements twice in one disposable transaction.
        second=second.removeprefix('begin;\n').removesuffix('rollback;\n')
        checks="""create temporary table expected_place_ids as select id,place_id from cool_spots;
update places set name='A later adopted name' where id=(select place_id from cool_spots where id='db-import-test-5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab');
"""+second+"""
do $$ begin
 if (select count(*) from catalogue_import_history where cool_spot_id like 'db-import-test-%')<>253 then raise exception 'retry duplicated history'; end if;
 if exists(select 1 from expected_place_ids e join cool_spots c on c.id=e.id where c.place_id<>e.place_id) then raise exception 'retry changed Place identities'; end if;
 if not exists(select 1 from places p join cool_spots c on c.place_id=p.id where c.id='db-import-test-5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab' and p.name='A later adopted name') then raise exception 'retry overwrote later facts'; end if;
end $$;"""
        result=sql(render_import(plan,commit=False,checks=checks))
        self.assertEqual(result.returncode,0,result.stderr)

    def test_changed_source_rejects_retry_and_rolls_back(self):
        plan=disposable_catalogue()
        changed=copy.deepcopy(plan)
        record=changed['records'][0]
        record['item']['name']='A changed source needs review'
        record.pop('fingerprint'); record['fingerprint']=digest(record)
        second=render_import(changed,commit=False).removeprefix('begin;\n').removesuffix('rollback;\n')
        before=sql('select count(*) from places; select count(*) from catalogue_import_history;').stdout
        result=sql(render_import(plan,commit=False,checks=second))
        self.assertNotEqual(result.returncode,0)
        self.assertIn('Changed catalogue input requires review',result.stderr)
        self.assertEqual(sql('select count(*) from places; select count(*) from catalogue_import_history;').stdout,before)

    def test_changed_source_header_rejects_retry_without_overwriting_existing_metadata(self):
        plan = disposable_catalogue()
        changed = copy.deepcopy(plan)
        changed['sources'][0]['metadata']['url'] = 'https://example.org/a-different-source'
        second = render_import(changed,commit=False).removeprefix('begin;\n').removesuffix('rollback;\n')
        result = sql(render_import(plan,commit=False,checks=second))
        self.assertNotEqual(result.returncode,0)
        self.assertIn('Changed source metadata requires a separate source revision',result.stderr)

    def test_quotes_backslashes_and_sql_like_text_remain_data(self):
        plan=disposable_catalogue()
        record=plan['records'][0]
        name="O'Reilly \\ data\n'); SELECT 1/0; --"
        record['item']['name']=name
        record.pop('fingerprint'); record['fingerprint']=digest(record)
        checks="select to_json(p.name) from places p join cool_spots c on c.place_id=p.id where c.id='db-import-test-5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab';"
        result=sql(render_import(plan,commit=False,checks=checks))
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(json.loads(result.stdout),name)

    def test_failure_after_writes_rolls_back_all_new_data(self):
        before=sql('select count(*) from places; select count(*) from source_records; select count(*) from catalogue_import_history;').stdout
        result=sql(render_import(disposable_catalogue(),checks='select 1/0;'))
        self.assertNotEqual(result.returncode,0)
        self.assertIn("division by zero",result.stderr)
        after=sql('select count(*) from places; select count(*) from source_records; select count(*) from catalogue_import_history;').stdout
        self.assertEqual(after,before)

if __name__=='__main__': unittest.main()
