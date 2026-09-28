begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(51);

select has_table('public', 'places', 'Place records exist separately from cooling information');

select has_column('public', 'cool_spots', 'place_id', 'DB-C17: links cooling information to a Place');

select hasnt_column('public', 'cool_spots', 'name', 'the adopted name has one owner: places');

select hasnt_column('public', 'cool_spots', 'location', 'the adopted location has one owner: places');

select to_regclass('public.places') is not null and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'cool_spots' and column_name = 'place_id') as schema_ready \gset
\if :schema_ready

-- Test fixture helper: each Cool Spot ID gets a different valid Place.
-- This prevents place_id uniqueness from masking a broken ID constraint.
create function pg_temp.insert_cool_spot(test_id text) returns void language plpgsql as $fixture$
declare
  new_place_id uuid;
begin
  insert into public.places (name, location)
  values ('Database Test Place', 'SRID=4326;POINT(0.010439996 51.516829995)')
  returning id into new_place_id;
  insert into public.cool_spots (id, place_id) values (test_id, new_place_id);
end;
$fixture$;

-- DB-C01-C02: Legacy string IDs remain Cool Spot identities.

select lives_ok(
  $$ select pg_temp.insert_cool_spot('00000000-0000-4000-8000-000000000001'); select pg_temp.insert_cool_spot('db-test-legacy-place'); $$,
  'stores UUID-shaped and legacy text Cool Spot identities'
);

select results_eq(
  $$ select c.id, p.name, gis.st_x(p.location::gis.geometry), gis.st_y(p.location::gis.geometry) from public.cool_spots c join public.places p on p.id = c.place_id where c.id in ('00000000-0000-4000-8000-000000000001', 'db-test-legacy-place') order by c.id; $$,
  $$ values ('00000000-0000-4000-8000-000000000001'::text, 'Database Test Place'::text, 0.010439996::double precision, 51.516829995::double precision), ('db-test-legacy-place'::text, 'Database Test Place'::text, 0.010439996::double precision, 51.516829995::double precision); $$,
  'joins Place facts without changing the public Cool Spot IDs'
);

select throws_ok(
  $$ select pg_temp.insert_cool_spot('db-test-duplicate'); select pg_temp.insert_cool_spot('db-test-duplicate'); $$,
  '23505', null, 'rejects a duplicate Cool Spot identity on different Places'
);

select throws_ok(
  $$ select pg_temp.insert_cool_spot(null); $$,
  '23502', null, 'DB-C03: rejects a NULL Cool Spot identity'
);

select throws_ok(
  $$ select pg_temp.insert_cool_spot(''); $$,
  '23514', null, 'DB-C04: rejects an empty Cool Spot identity'
);

select lives_ok(
  $$ select pg_temp.insert_cool_spot('x'); $$,
  'DB-C05: accepts a one-character Cool Spot identity'
);

create temporary table whitespace_samples as select code_point, chr(code_point) as sample from (values (9), (10), (11), (12), (13), (32), (133), (160), (5760), (8192), (8193), (8194), (8195), (8196), (8197), (8198), (8199), (8200), (8201), (8202), (8203), (8232), (8233), (8239), (8287), (12288)) as characters(code_point);

select throws_ok(format('select pg_temp.insert_cool_spot(%L)', sample), '23514', null, 'DB-C07: rejects a Cool Spot ID containing only U+' || upper(lpad(to_hex(code_point), 4, '0'))) from whitespace_samples order by code_point;

select throws_ok(format('select pg_temp.insert_cool_spot(%L)', string_agg(sample, '' order by code_point)), '23514', null, 'rejects a Cool Spot ID containing mixed whitespace') from whitespace_samples;

select pg_temp.insert_cool_spot('db-test-id-update');

select throws_ok(
  $$ update public.cool_spots set id = U&'\0020\0009\3000' where id = 'db-test-id-update'; $$,
  '23514', null, 'DB-C08: rejects changing a Cool Spot ID to whitespace'
);

select lives_ok(
  $$ select pg_temp.insert_cool_spot(U&'\0009\00A0db-test-preserved\200B\3000'); select pg_temp.insert_cool_spot('db-test-preserved'); $$,
  'DB-C09: accepts distinct padded and unpadded Cool Spot IDs'
);

select results_eq(
  $$ select id from public.cool_spots where id in (U&'\0009\00A0db-test-preserved\200B\3000', 'db-test-preserved') order by id collate "C"; $$,
  $$ values (U&'\0009\00A0db-test-preserved\200B\3000'::text), ('db-test-preserved'::text); $$,
  'reads back Cool Spot identities without trimming'
);

-- DB-C17-C18: Use explicit independent fixtures for relationship checks.
insert into public.places (id, name, location) values
  ('00000000-0000-4000-8000-000000000201', 'Linked Place A', 'SRID=4326;POINT(0 51)'),
  ('00000000-0000-4000-8000-000000000202', 'Linked Place B', 'SRID=4326;POINT(1 52)');
insert into public.cool_spots (id, place_id) values
  ('db-link-a', '00000000-0000-4000-8000-000000000201'),
  ('db-link-b', '00000000-0000-4000-8000-000000000202');

select throws_ok(
  $$ insert into public.cool_spots (id, place_id) values ('db-link-null', null); $$,
  '23502', null, 'rejects a Cool Spot without a Place'
);

select throws_ok(
  $$ insert into public.cool_spots (id, place_id) values ('db-link-missing', '00000000-0000-4000-8000-000000000299'); $$,
  '23503', null, 'rejects a Cool Spot linked to a missing Place'
);

select throws_ok(
  $$ insert into public.cool_spots (id, place_id) values ('db-link-duplicate', '00000000-0000-4000-8000-000000000201'); $$,
  '23505', null, 'rejects a second Cool Spot for the same Place'
);

select throws_ok(
  $$ update public.cool_spots set place_id = null where id = 'db-link-b'; $$,
  '23502', null, 'rejects removing a required Place link'
);

select throws_ok(
  $$ update public.cool_spots set place_id = '00000000-0000-4000-8000-000000000299' where id = 'db-link-b'; $$,
  '23503', null, 'rejects changing a link to a missing Place'
);

select throws_ok(
  $$ update public.cool_spots set place_id = '00000000-0000-4000-8000-000000000201' where id = 'db-link-b'; $$,
  '23505', null, 'rejects changing a link to a Place already used by another Cool Spot'
);

select throws_ok(
  $$ delete from public.places where id = '00000000-0000-4000-8000-000000000201'; $$,
  '23503', null, 'rejects deleting a Place while a Cool Spot references it'
);

select lives_ok(
  $$ delete from public.cool_spots where id = 'db-link-b'; $$,
  'allows removal of cooling information'
);

select results_eq(
  $$ select p.id, c.id from public.places p left join public.cool_spots c on c.place_id = p.id where p.id = '00000000-0000-4000-8000-000000000202'; $$,
  $$ values ('00000000-0000-4000-8000-000000000202'::uuid, null::text); $$,
  'removing cooling information preserves its independent Place'
);

select lives_ok(
  $$ update public.places set name = 'Renamed Linked Place', location = 'SRID=4326;POINT(2 53)' where id = '00000000-0000-4000-8000-000000000201'; $$,
  'allows changes to the facts of a linked Place'
);

select results_eq(
  $$ select c.id, c.place_id, p.name, gis.st_x(p.location::gis.geometry), gis.st_y(p.location::gis.geometry) from public.cool_spots c join public.places p on p.id = c.place_id where c.id = 'db-link-a'; $$,
  $$ values ('db-link-a'::text, '00000000-0000-4000-8000-000000000201'::uuid, 'Renamed Linked Place'::text, 2::double precision, 53::double precision); $$,
  'linked reads use the changed facts while both identities stay stable'
);

\else
select skip('behavior requires the missing places/cool_spots structure', 47);
\endif

select * from finish();
rollback;
