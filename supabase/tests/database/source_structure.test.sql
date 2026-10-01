begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

select columns_are('public', 'data_sources', array[
    'id', 'provider', 'label', 'dataset_name', 'source_url', 'download_url',
    'retrieved_at', 'source_updated_at', 'is_example', 'raw_file_path', 'raw_file_sha256'
], 'DB-C63: source headers have explicit fields without duplicated metadata');
select col_type_is('public', 'data_sources', 'retrieved_at', 'timestamp with time zone',
    'source retrieval time is an instant, not arbitrary text');
select col_type_is('public', 'data_sources', 'source_updated_at', 'timestamp with time zone',
    'source update time is an instant, not response generation time');
select col_not_null('public', 'data_sources', 'is_example',
    'every source explicitly distinguishes examples from real source data');
select columns_are('public', 'source_records', array[
    'source_id', 'source_record_id', 'raw_record', 'import_audit'
], 'DB-C64: source records retain originals and audit without duplicate mapped items');
select has_table('public', 'place_field_inference_records',
    'DB-C65: uses the owner-selected name for field acquisition records');
select hasnt_table('public', 'place_field_evidence', 'the former table name is retired');
select columns_are('public', 'place_source_links', array[
    'place_id', 'source_id', 'source_record_id', 'position'
], 'source-record identifiers have consistent names across relations');
select columns_are('public', 'catalogue_import_history', array[
    'id', 'place_id', 'cool_spot_id', 'import_payload_sha256', 'place_snapshot',
    'cool_spot_snapshot', 'evidence_snapshot', 'imported_at'
], 'history keeps its name and distinguishes the import payload hash from the raw file hash');

select to_regclass('public.place_field_inference_records') is not null
    and exists(select 1 from information_schema.columns where table_schema='public'
        and table_name='data_sources' and column_name='is_example') as ready \gset
\if :ready
select columns_are('public', 'place_field_inference_records', array[
    'place_id', 'field_key', 'source_id', 'source_record_id', 'derivation_method', 'recorded_at'
], 'field records explain acquisition without duplicating current adopted values');
insert into places(id,name,location) values
    ('00000000-0000-4000-8000-000000000701','Source structure fixture','SRID=4326;POINT(0 51)'),
    ('00000000-0000-4000-8000-000000000702','Unrelated source fixture','SRID=4326;POINT(1 52)');
insert into data_sources(id,provider,label,is_example) values
    ('db-structure','test','Test source',false),
    ('db-structure-example','test','Example source',true);
insert into source_records(source_id,source_record_id,raw_record,import_audit)
    values ('db-structure','18','{"name":"Original fixture"}','{}'),
    ('db-structure-example','18','{"name":"Example fixture"}','{}');
insert into place_source_links(place_id,source_id,source_record_id,position)
    values ('00000000-0000-4000-8000-000000000701','db-structure','18',0),
    ('00000000-0000-4000-8000-000000000701','db-structure-example','18',1);
select lives_ok($$insert into place_field_inference_records
    (place_id,field_key,source_id,source_record_id,derivation_method) values
    ('00000000-0000-4000-8000-000000000701','places.name','db-structure','18','mapped_from_source'),
    ('00000000-0000-4000-8000-000000000701','places.place_type','db-structure','18','inferred_from_name'),
    ('00000000-0000-4000-8000-000000000701','cool_spots.hours_time_zone','db-structure','18','inferred_from_context'),
    ('00000000-0000-4000-8000-000000000701','cool_spots.cooling_features','db-structure-example','18','example_data')$$,
    'direct mapping, two inference methods and examples remain distinct');
select throws_ok($$update place_field_inference_records set derivation_method='dataset_context'
    where source_id='db-structure'$$,'23514',null,'retired ambiguous method codes are rejected');
select throws_ok($$insert into place_field_inference_records
    (place_id,field_key,source_id,source_record_id,derivation_method) values
    ('00000000-0000-4000-8000-000000000702','places.name','db-structure','18','mapped_from_source')$$,
    '23503',null,'a field source must still be linked to the same Place');
select throws_ok($$insert into place_field_inference_records
    (place_id,field_key,source_id,source_record_id,derivation_method) values
    ('00000000-0000-4000-8000-000000000701','places.location_scope','db-structure','18','mapped_from_source')$$,
    '23514',null,'retired domain fields stay excluded');
select is((select recorded_at from place_field_inference_records
    where source_id='db-structure' and field_key='places.name'),null::timestamptz,
    'unknown field-record time remains null');
select is((select retrieved_at from data_sources where id='db-structure'),null::timestamptz,
    'unknown source retrieval time remains null');
select ok((select relrowsecurity from pg_class where oid='public.place_field_inference_records'::regclass),
    'DB-C66: renaming retains row-level security');
select ok(has_column_privilege('cool_spots_reader','public.data_sources','source_url','SELECT')
    and not has_column_privilege('cool_spots_reader','public.data_sources','raw_file_path','SELECT'),
    'reader can read public source fields but not local archive paths');
select ok(has_column_privilege('cool_spots_reader','public.source_records','source_record_id','SELECT')
    and not has_column_privilege('cool_spots_reader','public.source_records','raw_record','SELECT')
    and not has_column_privilege('cool_spots_reader','public.source_records','import_audit','SELECT'),
    'reader retains only source-record identity access');
\else
select skip('behavior requires the new source structure', 10);
\endif

select * from finish();
rollback;
