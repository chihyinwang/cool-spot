-- Run explicitly BEFORE permanently applying the sixth migration.
-- This rehearsal executes the actual migration with legacy rows, then rolls back.
-- It is separate from database/ because normal schema tests run AFTER migrations.
begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
set local lock_timeout = '5s';
set local statement_timeout = '30s';

select plan(11);

select has_column('public', 'cool_spots', 'name',
  'DB-C19: migration rehearsal starts with the legacy source columns');
select ok(to_regclass('public.places') is null,
  'migration rehearsal starts before the Places split');

select to_regclass('public.places') is null and exists (
  select 1 from information_schema.columns
  where table_schema = 'public' and table_name = 'cool_spots' and column_name = 'name'
) as legacy_ready \gset

\if :legacy_ready
create temporary table previous_counts as
select count(*) as cool_spots from public.cool_spots;

-- Two equal names/points must remain distinct identities; no inferred merging.
insert into public.cool_spots (id, name, location) values
  ('00000000-0000-4000-8000-000000000401', 'Migration Test Library',
    'SRID=4326;POINT(0.010439996 51.516829995)'),
  ('db-migration-legacy', 'Migration Test Library',
    'SRID=4326;POINT(0.010439996 51.516829995)'),
  (U&'\0009db-migration-padded\3000', U&'\3000涼 Garden\000A',
    'SRID=4326;POINT(-0.1246 51.5007)');

-- No copied implementation: execute the owner-written migration itself.
\ir ../../migrations/20260928145903_split_places_from_cool_spots.sql

select has_table('public', 'places', 'migration creates Places');
select has_column('public', 'cool_spots', 'place_id', 'migration adds Place links');
select hasnt_column('public', 'cool_spots', 'name', 'migration removes the duplicate name');
select hasnt_column('public', 'cool_spots', 'location', 'migration removes the duplicate location');

select to_regclass('public.places') is not null and exists (
  select 1 from information_schema.columns
  where table_schema = 'public' and table_name = 'cool_spots' and column_name = 'place_id'
) as split_ready \gset

\if :split_ready
select results_eq(
  $$
    select c.id, p.name, gis.st_x(p.location::gis.geometry), gis.st_y(p.location::gis.geometry)
    from public.cool_spots c join public.places p on p.id = c.place_id
    where c.id in ('00000000-0000-4000-8000-000000000401',
      'db-migration-legacy', U&'\0009db-migration-padded\3000')
    order by c.id collate "C";
  $$,
  $$
    values
      (U&'\0009db-migration-padded\3000'::text, U&'\3000涼 Garden\000A'::text,
        -0.1246::double precision, 51.5007::double precision),
      ('00000000-0000-4000-8000-000000000401'::text, 'Migration Test Library'::text,
        0.010439996::double precision, 51.516829995::double precision),
      ('db-migration-legacy'::text, 'Migration Test Library'::text,
        0.010439996::double precision, 51.516829995::double precision);
  $$,
  'migration preserves legacy IDs, exact names and both coordinate axes'
);

select ok((
  select count(*) = 3 and count(distinct place_id) = 3
    and bool_and(substr(place_id::text, 15, 1) = '4')
  from public.cool_spots
  where id in ('00000000-0000-4000-8000-000000000401',
    'db-migration-legacy', U&'\0009db-migration-padded\3000')
), 'migration assigns distinct UUID v4 Place IDs without merging equal facts');

select is((select count(*) from public.cool_spots),
  (select cool_spots + 3 from previous_counts), 'migration preserves the Cool Spot row count');
select is((select count(*) from public.places),
  (select cool_spots + 3 from previous_counts), 'migration creates one Place per existing Cool Spot');
select is((select count(*) from public.cool_spots c
  left join public.places p on p.id = c.place_id where p.id is null),
  0::bigint, 'migration leaves no Cool Spot without its Place');
\else
select skip('data preservation requires the missing split structure', 5);
\endif
\else
select skip('run this rehearsal before applying the sixth migration', 9);
\endif

select * from finish();
rollback;
