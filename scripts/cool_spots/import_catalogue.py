"""Import the checked-in catalogue into the named local database, never the cloud.

Default: validate files without accessing PostgreSQL. --apply-local commits one
transaction. Identical retries do nothing; changed source inputs require review.
This is an administrative importer, not an API reader or publication endpoint.
"""
import argparse
import hashlib
import json
import math
import os
import re
import subprocess
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

ROOT = Path(__file__).resolve().parents[2]
GLA = 'cool-spot/Resources/CoolSpots.prototype.json'
COMMUNITY = 'cool-spot/Resources/CommunityCoolSpots.prototype.json'
RAW = 'data/cool-spots/gla-cool-spaces-2025.geojson'
DOCKER = ['docker', 'exec', '-i', 'supabase_db_cool-spot-prototype', 'psql', '-U', 'postgres', '-d', 'postgres', '-X', '--no-password', '-v', 'ON_ERROR_STOP=1', '-qAt']
WHITESPACE = ''.join(chr(c) for c in [*range(9,14),32,133,160,5760,*range(8192,8204),8232,8233,8239,8287,12288])
FEATURES = {'air_conditioning','fans','natural_ventilation','tree_shade','structural_shade','cooler_indoors','water_nearby'}
PLACE_TYPES = {'library','community','faith','culture','leisure','shop','food','park','square','waterside','transport','other','unknown'}
ACCESS_CODES = {
    'cost': {'free','purchase_required','entry_fee','unknown'},
    'eligibility': {'everyone','limited','unknown'},
    'seating': {'yes','limited','no','unknown'},
    'toilets': {'on_site','nearby','not_on_site','none','unknown'},
    **{key: {'yes','no','unknown'} for key in ['drinkingWater','wheelchairAccess','staffedWhenOpen','tables']},
}
ADDRESS = {'line1':'address_line1','line2':'address_line2','locality':'address_locality','borough':'address_borough','postalCode':'address_postal_code','countryCode':'address_country_code','formatted':'address_formatted'}
COOLING = {'setting':'setting','coolingFeatures':'cooling_features','coolingDetails':'cooling_details','additionalInformation':'additional_information'}
ACCESS = {'cost':'cost','eligibility':'eligibility','seating':'seating','drinkingWater':'drinking_water','toilets':'toilets','wheelchairAccess':'wheelchair_access','staffedWhenOpen':'staffed_when_open','tables':'tables','areaDescription':'area_description'}
FIELD_KEYS = {
    '/name':'places.name', '/placeType':'places.place_type',
    '/location/latitude':'places.location.latitude', '/location/longitude':'places.location.longitude',
    **{'/address/'+key: 'places.'+column for key,column in ADDRESS.items()},
    **{'/'+key: 'cool_spots.'+column for key,column in COOLING.items()},
    **{'/access/'+key: 'cool_spots.'+column for key,column in ACCESS.items()},
    '/access/postedStayLimit/status':'cool_spots.posted_stay_limit_status',
    '/access/postedStayLimit/minutes':'cool_spots.posted_stay_limit_minutes',
    '/hours/text':'cool_spots.hours_text','/hours/timeZone':'cool_spots.hours_time_zone',
}
# Retained exclusively in the immutable input snapshot, never as new domain columns.
LEGACY_POINTERS = {'/location/scope','/access/eligibilityDetails'}
# The input plan deliberately keeps its original keys/method codes. Existing
# import hashes and immutable snapshots use this canonical format. SQL maps it
# to the current storage names; renaming the input would break identical retries.

def require(condition, message):
    if not condition: raise ValueError(message)

def text(value, name, nullable=False):
    if value is None and nullable: return
    require(isinstance(value,str) and bool(value.strip(WHITESPACE)) and '\x00' not in value, name+' must contain nonblank text')

def timestamp(value, name):
    if value is None: return
    require(isinstance(value,str), name+' must be an ISO timestamp')
    try: parsed=datetime.fromisoformat(value.replace('Z','+00:00'))
    except ValueError as error: raise ValueError(name+' must be an ISO timestamp') from error
    require(parsed.tzinfo is not None, name+' must include a time zone')

def validate_item(item):
    text(item['id'],'id'); text(item['name'],'name')
    require(len(item['name'])<=300,'name exceeds 300 characters')
    for key,limit in [('latitude',90),('longitude',180)]:
        value=item['location'][key]
        require(type(value) in (int,float) and math.isfinite(value) and -limit<=value<=limit, 'invalid original '+key)
    for key in ADDRESS: text(item['address'][key],'address.'+key,nullable=True)
    country=item['address']['countryCode']
    require(country is None or re.fullmatch('[A-Z]{2}',country) is not None,'invalid country code')
    require(item['placeType'] in PLACE_TYPES,'invalid place type')
    require(item['setting'] in {'indoors','outdoors','both','unknown'},'invalid setting')
    features=item['coolingFeatures']
    require(isinstance(features,list) and all(isinstance(x,str) and x in FEATURES for x in features),'invalid feature list')
    for key,values in ACCESS_CODES.items(): require(item['access'][key] in values,'invalid access.'+key)
    for key in ['coolingDetails','additionalInformation']: text(item[key],key,nullable=True)
    text(item['access']['areaDescription'],'areaDescription',nullable=True)
    limit=item['access']['postedStayLimit']
    require(limit['status'] in {'limited','no_stated_limit','unknown'},'invalid stay limit status')
    require((type(limit['minutes']) is int and limit['minutes']>0) if limit['status']=='limited' else limit['minutes'] is None,'invalid stay limit minutes')
    if item['hours'] is not None:
        text(item['hours']['text'],'hours.text'); text(item['hours']['timeZone'],'hours.timeZone')
        try: ZoneInfo(item['hours']['timeZone'])
        except (ZoneInfoNotFoundError,ValueError) as error: raise ValueError('unknown hours time zone') from error
    for link in item['mapReferences']:
        text(link['placeID'],'external Place ID')
        require(link['provider']=='apple_maps' and link['relationship'] in {'same_place','within_place'} and link['verification'] in {'automatic','reviewed'},'unaccepted map relationship')
        timestamp(link.get('checkedAt'),'checkedAt')
    for photo in item['photos']:
        for key in ['id','thumbnailURL','imageURL']: text(photo[key],'photo.'+key)
        require(all(type(photo[k]) is int and photo[k]>0 for k in ['width','height']),'invalid photo dimensions')
        require(photo['source'] in {'community','provider','illustration'},'invalid photo source')
        require(isinstance(photo['attribution'],str),'invalid attribution')
        require(photo['caption'] is None or isinstance(photo['caption'],str) and len(photo['caption'])<=500,'invalid caption')
        timestamp(photo['capturedAt'],'capturedAt'); timestamp(photo['publishedAt'],'publishedAt')
    for evidence in item['provenance']:
        require(evidence['method'] in {'imported','dataset_context','name_rule','reviewed_contribution'},'unknown provenance method')
        timestamp(evidence['recordedAt'],'recordedAt')
    json.dumps(item,allow_nan=False)

def read_json(path):
    def pairs(values):
        result={}
        for key,value in values:
            require(key not in result,'duplicate JSON key: '+key); result[key]=value
        return result
    def invalid_constant(value): raise ValueError('non-finite JSON value: '+value)
    return json.loads(path.read_text(),object_pairs_hook=pairs,parse_constant=invalid_constant)

def digest(value):
    return hashlib.sha256(json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=False,allow_nan=False).encode()).hexdigest()

def load_catalogue(root=ROOT):
    gla,community=read_json(root/GLA),read_json(root/COMMUNITY)
    mapping=read_json(root/'data/cool-spots/cool-spots-mapping.json')
    registry=read_json(root/'data/cool-spots/identity-registry.json')
    manifest=read_json(root/'data/cool-spots/source-manifest.json')
    raw=read_json(root/RAW)
    raw_sha=hashlib.sha256((root/RAW).read_bytes()).hexdigest()
    require(raw_sha==manifest['sha256']==gla['sources'][0]['sha256'],'raw GLA hash differs from its retained evidence')
    require(gla['schemaVersion']==community['schemaVersion']==4,'unsupported input version')
    require(gla['items']==mapping['items'],'mapping export and App fixture disagree')
    require(len(gla['items'])==250 and len(community['items'])==3,'initial catalogue must contain 250 GLA and three examples')
    raw_records={str(f['properties']['cs_indoor_site_id']):f for f in raw['features']}
    audits={row['coolSpotID']:row for row in mapping['mapping']['results']}
    require(len(raw_records)==len(raw['features'])==250,'duplicate/missing source identities')
    require(len(audits)==len(mapping['mapping']['results'])==250,'duplicate/missing mapping identities')
    sources=[]; records=[]; identities=set(); external_ids=set(); photo_ids=set()
    for document,path in [(gla,GLA),(community,COMMUNITY)]:
        for source in document['sources']:
            for key in ['id','provider','label']: text(source[key],'source.'+key)
            example=document is community
            require(source.get('isExample',False) is example,'source example distinction changed')
            sources.append({'id':source['id'],'provider':source['provider'],'label':source['label'],'metadata':source,
                            'raw_file_path':COMMUNITY if example else RAW,
                            'raw_sha256':hashlib.sha256((root/COMMUNITY).read_bytes()).hexdigest() if example else raw_sha})
        source_ids={x['id'] for x in document['sources']}
        for item in document['items']:
            validate_item(item)
            require(item['id'] not in identities,'duplicate Cool Spot ID'); identities.add(item['id'])
            require(len(item['sourceReferences'])==1,'initial importer needs one original source per record; review multi-source changes separately')
            ref=item['sourceReferences'][0]; sid,rid=ref['sourceID'],ref['recordID']
            text(rid,'source record ID'); require(sid in source_ids,'missing source metadata')
            if document is gla:
                require(rid in raw_records and registry[rid]==item['id'],'source/identity registry mismatch')
                evidence=audits[item['id']]
                require(evidence['sourceRecordID']==rid,'mapping refers to a different source record')
                accepted=evidence['status'] in {'auto_matched','reviewed_matched','reviewed_related'}
                links=item['mapReferences']
                require((len(links)==1 and links[0]['placeID']==evidence['selectedPlaceID'] and links[0]['relationship']==('within_place' if evidence['status']=='reviewed_related' else 'same_place')) if accepted else not links and evidence['selectedPlaceID'] is None,'accepted Apple mapping changed')
                raw_data=raw_records[rid]
            else:
                raw_data=item; evidence={}
            fields=[]; field_keys=set()
            for entry in item['provenance']:
                require(entry['sourceID']==sid and entry['recordID']==rid,'unrelated field evidence')
                require(entry['method']!='reviewed_contribution' or document is community,
                        'legacy reviewed_contribution is reserved for labelled examples')
                for pointer in entry['fields']:
                    value=item
                    for part in pointer.lstrip('/').split('/'): value=value[part]
                    if pointer in LEGACY_POINTERS: continue
                    require(pointer in FIELD_KEYS,'unmapped provenance field: '+pointer)
                    key=FIELD_KEYS[pointer]
                    require(key not in field_keys,'ambiguous current field evidence'); field_keys.add(key)
                    fields.append({'field_key':key,'source_id':sid,'record_id':rid,'method':entry['method'],'recorded_at':entry['recordedAt']})
            for link in item['mapReferences']:
                if link['relationship']=='same_place':
                    key=(link['provider'],link['placeID'])
                    require(key not in external_ids,'conflicting same-place Apple identities'); external_ids.add(key)
            for photo in item['photos']:
                require(photo['id'] not in photo_ids,'duplicate photo identity'); photo_ids.add(photo['id'])
                require(not photo['imageURL'].startswith('bundle://') or document is community,'bundle photos are labelled examples only')
            record={'document_metadata':{key:value for key,value in document.items() if key!='items'},'item':item,'source_id':sid,'record_id':rid,'raw_data':raw_data,'mapping_evidence':evidence,'fields':fields}
            record['fingerprint']=digest(record)
            records.append(record)
    require(len({s['id'] for s in sources})==len(sources),'duplicate source metadata')
    require({r['record_id'] for r in records[:250]}==set(raw_records),'missing GLA source records')
    return {'sources':sources,'records':records}

def render_import(catalogue, commit=True, checks=''):
    for record in catalogue['records']: validate_item(record['item'])
    payload=json.dumps(catalogue,ensure_ascii=False,separators=(',',':'),allow_nan=False).replace("'","''")
    return "begin;\nset local standard_conforming_strings=on;\n" + "create temporary table cs_import_document(data jsonb) on commit drop;\ninsert into cs_import_document values ('"+payload+"'::jsonb);\n" + IMPORT_SQL + checks + '\n' + ('commit;\n' if commit else 'rollback;\n')

IMPORT_SQL = r"""
-- Serialize administrative imports, preserving existing identities on retry.
lock table public.cool_spots in share row exclusive mode;
create temporary table cs_import_rows on commit drop as
select value as payload, coalesce(c.place_id,gen_random_uuid()) as place_id, h.id is null as is_new
from cs_import_document d cross join lateral jsonb_array_elements(d.data->'records') r(value)
left join public.cool_spots c on c.id=value->'item'->>'id'
left join public.catalogue_import_history h on h.cool_spot_id=value->'item'->>'id';
do $$ begin
 if exists(select 1 from cs_import_rows r join public.cool_spots c on c.id=r.payload->'item'->>'id' where r.is_new) then
  raise exception 'Existing Cool Spot has no initial import history; review before importing';
 end if;
 if exists(select 1 from cs_import_rows r join public.catalogue_import_history h on h.cool_spot_id=r.payload->'item'->>'id' where h.import_payload_sha256<>r.payload->>'fingerprint') then
  raise exception 'Changed catalogue input requires review; existing facts were not overwritten';
 end if;
 if exists(
  select 1 from cs_import_document d
  cross join lateral jsonb_array_elements(d.data->'sources') s(value)
  join public.data_sources old on old.id=s.value->>'id'
  where (old.provider,old.label,old.raw_file_path,old.raw_file_sha256,
         old.dataset_name,old.source_url,old.download_url,old.retrieved_at,
         old.source_updated_at,old.is_example)
  is distinct from
        (s.value->>'provider',s.value->>'label',s.value->>'raw_file_path',s.value->>'raw_sha256',
         s.value#>>'{metadata,dataset}',s.value#>>'{metadata,url}',s.value#>>'{metadata,downloadURL}',
         (s.value#>>'{metadata,retrievedAt}')::timestamptz,
         (s.value#>>'{metadata,sourceUpdatedAt}')::timestamptz,
         coalesce((s.value#>>'{metadata,isExample}')::boolean,false))
 ) then
  raise exception 'Changed source metadata requires a separate source revision';
 end if;
end $$;
insert into public.data_sources(id,provider,label,raw_file_path,raw_file_sha256,
 dataset_name,source_url,download_url,retrieved_at,source_updated_at,is_example)
select value->>'id',value->>'provider',value->>'label',value->>'raw_file_path',value->>'raw_sha256',
 value#>>'{metadata,dataset}',value#>>'{metadata,url}',value#>>'{metadata,downloadURL}',
 (value#>>'{metadata,retrievedAt}')::timestamptz,(value#>>'{metadata,sourceUpdatedAt}')::timestamptz,
 coalesce((value#>>'{metadata,isExample}')::boolean,false)
from cs_import_document cross join lateral jsonb_array_elements(data->'sources') on conflict do nothing;
insert into public.source_records(source_id,source_record_id,raw_record,import_audit)
select payload->>'source_id',payload->>'record_id',payload->'raw_data',payload->'mapping_evidence'
from cs_import_rows where is_new;
insert into public.places(id,name,location,place_type,address_line1,address_line2,address_locality,address_borough,address_postal_code,address_country_code,address_formatted)
select place_id,item->>'name',gis.st_setsrid(gis.st_makepoint((item->'location'->>'longitude')::double precision,(item->'location'->>'latitude')::double precision),4326)::gis.geography,
 item->>'placeType',item->'address'->>'line1',item->'address'->>'line2',item->'address'->>'locality',item->'address'->>'borough',item->'address'->>'postalCode',item->'address'->>'countryCode',item->'address'->>'formatted'
from cs_import_rows cross join lateral (select payload->'item' as item) i where is_new;
insert into public.cool_spots(id,place_id,setting,cooling_features,cooling_details,area_description,cost,eligibility,seating,drinking_water,toilets,wheelchair_access,staffed_when_open,tables,posted_stay_limit_status,posted_stay_limit_minutes,additional_information,hours_text,hours_time_zone)
select item->>'id',place_id,item->>'setting',array(select jsonb_array_elements_text(item->'coolingFeatures')),item->>'coolingDetails',item->'access'->>'areaDescription',item->'access'->>'cost',item->'access'->>'eligibility',item->'access'->>'seating',item->'access'->>'drinkingWater',item->'access'->>'toilets',item->'access'->>'wheelchairAccess',item->'access'->>'staffedWhenOpen',item->'access'->>'tables',item->'access'->'postedStayLimit'->>'status',(item->'access'->'postedStayLimit'->>'minutes')::integer,item->>'additionalInformation',item->'hours'->>'text',item->'hours'->>'timeZone'
from cs_import_rows cross join lateral (select payload->'item' as item) i where is_new;
insert into public.place_source_links(place_id,source_id,source_record_id,position)
select place_id,payload->>'source_id',payload->>'record_id',0 from cs_import_rows where is_new;
insert into public.place_field_inference_records(place_id,field_key,source_id,source_record_id,derivation_method,recorded_at)
select place_id,value->>'field_key',value->>'source_id',value->>'record_id',
 case value->>'method'
  when 'imported' then 'mapped_from_source'
  when 'dataset_context' then 'inferred_from_context'
  when 'name_rule' then 'inferred_from_name'
  when 'reviewed_contribution' then case when
   (select is_example from public.data_sources where id=value->>'source_id') then 'example_data' end
 end,
 (value->>'recorded_at')::timestamptz
from cs_import_rows cross join lateral jsonb_array_elements(payload->'fields') where is_new;
insert into public.place_map_links(place_id,provider,external_place_id,relationship,verification,checked_at,evidence)
select place_id,value->>'provider',value->>'placeID',value->>'relationship',value->>'verification',(value->>'checkedAt')::timestamptz,payload->'mapping_evidence'
from cs_import_rows cross join lateral jsonb_array_elements(payload->'item'->'mapReferences') where is_new;
insert into public.place_photos(id,place_id,thumbnail_ref,image_ref,width,height,caption,captured_at,published_at,attribution,source_kind,contribution_id,position)
select photo->>'id',place_id,photo->>'thumbnailURL',photo->>'imageURL',(photo->>'width')::integer,(photo->>'height')::integer,photo->>'caption',(photo->>'capturedAt')::timestamptz,(photo->>'publishedAt')::timestamptz,photo->>'attribution',photo->>'source',photo->>'contributionID',(position-1)::integer
from cs_import_rows cross join lateral jsonb_array_elements(payload->'item'->'photos') with ordinality as photos(photo,position) where is_new;
insert into public.catalogue_import_history(place_id,cool_spot_id,import_payload_sha256,place_snapshot,cool_spot_snapshot,evidence_snapshot)
select r.place_id,c.id,r.payload->>'fingerprint',to_jsonb(p),to_jsonb(c),jsonb_build_object('document_metadata',r.payload->'document_metadata','item',r.payload->'item','fields',r.payload->'fields','sourceID',r.payload->>'source_id','recordID',r.payload->>'record_id')
from cs_import_rows r join public.places p on p.id=r.place_id join public.cool_spots c on c.id=r.payload->'item'->>'id' where r.is_new;
drop table cs_import_rows;
drop table cs_import_document;
"""

def require_local_docker():
    # An inherited remote context must never turn --apply-local into a remote write.
    require(not os.environ.get('DOCKER_HOST'), 'unset DOCKER_HOST before a local import')
    inspection=subprocess.run(['docker','context','inspect'],text=True,capture_output=True,check=True)
    context=json.loads(inspection.stdout)[0]
    host=context['Endpoints']['docker']['Host']
    require(host.startswith('unix://'), 'local import requires a Unix-socket Docker context')
    return context['Name']

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply-local',action='store_true',help='commit to supabase_db_cool-spot-prototype only')
    args=parser.parse_args()
    catalogue=load_catalogue()
    if args.apply_local:
        context=require_local_docker()
        result=subprocess.run(['docker','--context',context,*DOCKER[1:]],input=render_import(catalogue),text=True,capture_output=True)
        if result.returncode:
            raise SystemExit('Local import failed; transaction rolled back.\n'+result.stderr)
    print(json.dumps({'validated_records':len(catalogue['records']),'sources':len(catalogue['sources']),'local_transaction_committed':args.apply_local}))

if __name__=='__main__': main()
