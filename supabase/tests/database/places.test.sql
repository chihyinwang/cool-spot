begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(53);

select has_table('public', 'places', 'DB-C16: provides independent public Places');

select col_type_is('public', 'places', 'id', 'uuid', 'Place identities use the uuid type');

select count(*) = 3 as schema_ready from information_schema.columns where table_schema = 'public' and table_name = 'places' and column_name in ('id', 'name', 'location') \gset
\if :schema_ready

-- DB-C16: Same facts do not imply the same identity. No cooling row is required.

select lives_ok(
  $$ insert into public.places (name, location) values ('DB Independent Place', 'SRID=4326;POINT(0 51)'), ('DB Independent Place', 'SRID=4326;POINT(0 51)'); $$,
  'stores independent Places without providing IDs or cooling information'
);

select ok((select count(*) = 2 and count(distinct id) = 2 and bool_and(substr(id::text, 15, 1) = '4') from public.places where name = 'DB Independent Place'), 'generates distinct UUID v4 identities for new Places');

insert into public.places (id, name, location) values ('00000000-0000-4000-8000-000000000100', 'Original Place', 'SRID=4326;POINT(0 51)');

select throws_ok(
  $$ insert into public.places (id, name, location) values ('00000000-0000-4000-8000-000000000100', 'Different Name', 'SRID=4326;POINT(1 52)'); $$,
  '23505', null, 'rejects a duplicate Place identity'
);

select throws_ok(
  $$ insert into public.places (id, name, location) values ('not-a-uuid', 'Invalid Identity', 'SRID=4326;POINT(0 51)'); $$,
  '22P02', null, 'rejects a malformed Place UUID'
);

-- DB-C03: Required fields now belong to the independent Place.

select throws_ok(
  $$ insert into public.places (id, name, location) values (null, 'Required Values', 'SRID=4326;POINT(0 51)'); $$,
  '23502', null, 'rejects a Place with NULL id'
);

select throws_ok(
  $$ insert into public.places (id, name, location) values ('00000000-0000-4000-8000-000000000101', null, 'SRID=4326;POINT(0 51)'); $$,
  '23502', null, 'rejects a Place with NULL name'
);

select throws_ok(
  $$ insert into public.places (id, name, location) values ('00000000-0000-4000-8000-000000000101', 'Required Values', null); $$,
  '23502', null, 'rejects a Place with NULL location'
);

-- DB-C04-C08: Carry the approved name rules to their new owner.

select throws_ok(
  $$ insert into public.places (name, location) values ('', 'SRID=4326;POINT(0 51)'); $$,
  '23514', null, 'rejects an empty name'
);

select throws_ok(
  $$ insert into public.places (name, location) values (repeat('涼', 301), 'SRID=4326;POINT(0 51)'); $$,
  '23514', null, 'rejects a 301-character name'
);

create temporary table whitespace_samples as select code_point, chr(code_point) as sample from (values (9), (10), (11), (12), (13), (32), (133), (160), (5760), (8192), (8193), (8194), (8195), (8196), (8197), (8198), (8199), (8200), (8201), (8202), (8203), (8232), (8233), (8239), (8287), (12288)) as characters(code_point);

select throws_ok(format('insert into public.places (name, location) values (%L, %L)', sample, 'SRID=4326;POINT(0 51)'), '23514', null, 'rejects a name containing only U+' || upper(lpad(to_hex(code_point), 4, '0'))) from whitespace_samples order by code_point;

select throws_ok(format('insert into public.places (name, location) values (%L, %L)', string_agg(sample, '' order by code_point), 'SRID=4326;POINT(0 51)'), '23514', null, 'rejects a name containing mixed whitespace') from whitespace_samples;

select throws_ok(
  $$ update public.places set name = '' where id = '00000000-0000-4000-8000-000000000100'; $$,
  '23514', null, 'rejects changing a Place name to empty'
);

select throws_ok(
  $$ update public.places set name = U&'\0020\0009\3000' where id = '00000000-0000-4000-8000-000000000100'; $$,
  '23514', null, 'rejects changing a Place name to whitespace-only'
);

select lives_ok(
  $$ insert into public.places (name, location) values ('X', 'SRID=4326;POINT(0 51)'), (repeat('涼', 300), 'SRID=4326;POINT(0 51)'); $$,
  'accepts one-character and 300-character names'
);

-- DB-C09: Keep nonblank text exactly as supplied.

select lives_ok(
  $$ insert into public.places (id, name, location) values ('00000000-0000-4000-8000-000000000102', U&'\3000涼 Library\00A0\000A', 'SRID=4326;POINT(0 51)'); $$,
  'accepts a meaningful name surrounded by whitespace'
);

select results_eq(
  $$ select name from public.places where id = '00000000-0000-4000-8000-000000000102'; $$,
  $$ values (U&'\3000涼 Library\00A0\000A'::text); $$,
  'preserves the original name without trimming'
);

-- DB-C10: Preserve the geographic limits and zero coordinates.

select lives_ok(
  $$ insert into public.places (name, location) values ('DB Coordinate 0', 'SRID=4326;POINT(-180 -90)'), ('DB Coordinate 1', 'SRID=4326;POINT(-180 90)'), ('DB Coordinate 2', 'SRID=4326;POINT(180 -90)'), ('DB Coordinate 3', 'SRID=4326;POINT(180 90)'), ('DB Coordinate 4', 'SRID=4326;POINT(0 0)'); $$,
  'accepts valid boundary and zero coordinates'
);

select results_eq(
  $$ select name, gis.st_x(location::gis.geometry), gis.st_y(location::gis.geometry) from public.places where name like 'DB Coordinate %' order by name; $$,
  $$ values ('DB Coordinate 0'::text, -180::double precision, -90::double precision), ('DB Coordinate 1'::text, -180::double precision, 90::double precision), ('DB Coordinate 2'::text, 180::double precision, -90::double precision), ('DB Coordinate 3'::text, 180::double precision, 90::double precision), ('DB Coordinate 4'::text, 0::double precision, 0::double precision); $$,
  'reads back boundary and zero coordinates unchanged'
);

-- DB-C11-C12: Stored-point checks do not validate raw input before conversion.

select throws_ok(
  $$ insert into public.places (name, location) values ('Invalid Location', 'SRID=4326;POINT EMPTY'); $$,
  '23514', null, 'rejects inserting an empty point'
);

select throws_ok(
  $$ update public.places set location = 'SRID=4326;POINT EMPTY' where id = '00000000-0000-4000-8000-000000000100'; $$,
  '23514', null, 'rejects updating to an empty point'
);

select throws_ok(
  $$ insert into public.places (name, location) values ('Invalid Location', 'SRID=4326;POINT(NaN 51)'); $$,
  '23514', null, 'rejects inserting an NaN longitude'
);

select throws_ok(
  $$ update public.places set location = 'SRID=4326;POINT(NaN 51)' where id = '00000000-0000-4000-8000-000000000100'; $$,
  '23514', null, 'rejects updating to an NaN longitude'
);

select throws_ok(
  $$ insert into public.places (name, location) values ('Invalid Location', 'SRID=4326;POINT(0 NaN)'); $$,
  '23514', null, 'rejects inserting an NaN latitude'
);

select throws_ok(
  $$ update public.places set location = 'SRID=4326;POINT(0 NaN)' where id = '00000000-0000-4000-8000-000000000100'; $$,
  '23514', null, 'rejects updating to an NaN latitude'
);

select lives_ok(
  $$ update public.places set name = 'Changed Place', location = 'SRID=4326;POINT(1 52)' where id = '00000000-0000-4000-8000-000000000100'; $$,
  'allows adopted Place facts to change'
);

select results_eq(
  $$ select id, name, gis.st_x(location::gis.geometry), gis.st_y(location::gis.geometry) from public.places where id = '00000000-0000-4000-8000-000000000100'; $$,
  $$ values ('00000000-0000-4000-8000-000000000100'::uuid, 'Changed Place'::text, 1::double precision, 52::double precision); $$,
  'changing facts preserves the Place identity'
);

\else
select skip('behavior requires the missing places/cool_spots structure', 51);
\endif

select * from finish();
rollback;
