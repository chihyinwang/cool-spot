begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(47);

select ok(exists (select 1 from pg_roles where rolname = 'cool_spots_reader'), 'DB-C13: provides the dedicated backend reader');

select ok(coalesce((select relrowsecurity from pg_class where oid = to_regclass('public.cool_spots')), false), 'enables RLS on Cool Spots');

select ok(coalesce((select relrowsecurity from pg_class where oid = to_regclass('public.places')), false), 'DB-C20: enables RLS on public Places');

select to_regclass('public.places') is not null and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'cool_spots' and column_name = 'place_id') and exists (select 1 from pg_roles where rolname = 'cool_spots_reader') as schema_ready \gset
\if :schema_ready

-- Valid rows ensure permission failures are not missing-parent failures.
insert into public.places (id, name, location) values
  ('00000000-0000-4000-8000-000000000301', 'Published Cooling Place', 'SRID=4326;POINT(-0.125 51.5)'),
  ('00000000-0000-4000-8000-000000000302', 'Public Place Without Cooling', 'SRID=4326;POINT(1 52)'),
  ('00000000-0000-4000-8000-000000000303', 'Available Link Target', 'SRID=4326;POINT(2 53)');
insert into public.cool_spots (id, place_id) values ('db-permissions-cooling', '00000000-0000-4000-8000-000000000301');

-- DB-C14 / DB-C20: Execute as the actual client role.
set local role anon;

select is(current_user::text, 'anon', 'executes checks as anon');

select throws_ok(
  $$ select id, name from public.places; $$,
  '42501', null, 'anon cannot directly read places'
);

select throws_ok(
  $$ insert into public.places (name, location) values ('Unauthorized Place', 'SRID=4326;POINT(0 51)'); $$,
  '42501', null, 'anon cannot directly insert places'
);

select throws_ok(
  $$ update public.places set name = 'Unauthorized Change' where id = '00000000-0000-4000-8000-000000000301'; $$,
  '42501', null, 'anon cannot directly update places'
);

select throws_ok(
  $$ delete from public.places where id = '00000000-0000-4000-8000-000000000302'; $$,
  '42501', null, 'anon cannot directly delete places'
);

select throws_ok(
  $$ truncate table public.places; $$,
  '42501', null, 'anon cannot directly truncate places'
);

select throws_ok(
  $$ select id, place_id from public.cool_spots; $$,
  '42501', null, 'anon cannot directly read cool_spots'
);

select throws_ok(
  $$ insert into public.cool_spots (id, place_id) values ('db-permissions-new', '00000000-0000-4000-8000-000000000303'); $$,
  '42501', null, 'anon cannot directly insert cool_spots'
);

select throws_ok(
  $$ update public.cool_spots set place_id = '00000000-0000-4000-8000-000000000303' where id = 'db-permissions-cooling'; $$,
  '42501', null, 'anon cannot directly update cool_spots'
);

select throws_ok(
  $$ delete from public.cool_spots where id = 'db-permissions-cooling'; $$,
  '42501', null, 'anon cannot directly delete cool_spots'
);

select throws_ok(
  $$ truncate table public.cool_spots; $$,
  '42501', null, 'anon cannot directly truncate cool_spots'
);

reset role;

-- DB-C14 / DB-C20: Execute as the actual client role.
set local role authenticated;

select is(current_user::text, 'authenticated', 'executes checks as authenticated');

select throws_ok(
  $$ select id, name from public.places; $$,
  '42501', null, 'authenticated cannot directly read places'
);

select throws_ok(
  $$ insert into public.places (name, location) values ('Unauthorized Place', 'SRID=4326;POINT(0 51)'); $$,
  '42501', null, 'authenticated cannot directly insert places'
);

select throws_ok(
  $$ update public.places set name = 'Unauthorized Change' where id = '00000000-0000-4000-8000-000000000301'; $$,
  '42501', null, 'authenticated cannot directly update places'
);

select throws_ok(
  $$ delete from public.places where id = '00000000-0000-4000-8000-000000000302'; $$,
  '42501', null, 'authenticated cannot directly delete places'
);

select throws_ok(
  $$ truncate table public.places; $$,
  '42501', null, 'authenticated cannot directly truncate places'
);

select throws_ok(
  $$ select id, place_id from public.cool_spots; $$,
  '42501', null, 'authenticated cannot directly read cool_spots'
);

select throws_ok(
  $$ insert into public.cool_spots (id, place_id) values ('db-permissions-new', '00000000-0000-4000-8000-000000000303'); $$,
  '42501', null, 'authenticated cannot directly insert cool_spots'
);

select throws_ok(
  $$ update public.cool_spots set place_id = '00000000-0000-4000-8000-000000000303' where id = 'db-permissions-cooling'; $$,
  '42501', null, 'authenticated cannot directly update cool_spots'
);

select throws_ok(
  $$ delete from public.cool_spots where id = 'db-permissions-cooling'; $$,
  '42501', null, 'authenticated cannot directly delete cool_spots'
);

select throws_ok(
  $$ truncate table public.cool_spots; $$,
  '42501', null, 'authenticated cannot directly truncate cool_spots'
);

reset role;

select ok((select not rolcanlogin and not rolsuper and not rolbypassrls and not rolcreatedb and not rolcreaterole and not rolreplication from pg_roles where rolname = 'cool_spots_reader'), 'DB-C15: reader has no login or administrative privileges');

-- Test harness access only. Neither grant gives the reader domain-table access.
-- Both grants are rolled back, including the test session's SET ROLE membership.
grant usage on schema extensions to cool_spots_reader;
grant cool_spots_reader to current_user with inherit false, set true;
set local role cool_spots_reader;

select is(current_user::text, 'cool_spots_reader', 'executes reads as the dedicated backend role');

select results_eq(
  $$ select id, name, gis.st_x(location::gis.geometry), gis.st_y(location::gis.geometry) from public.places where id in ('00000000-0000-4000-8000-000000000301', '00000000-0000-4000-8000-000000000302') order by id; $$,
  $$ values ('00000000-0000-4000-8000-000000000301'::uuid, 'Published Cooling Place'::text, -0.125::double precision, 51.5::double precision), ('00000000-0000-4000-8000-000000000302'::uuid, 'Public Place Without Cooling'::text, 1::double precision, 52::double precision); $$,
  'reader sees accepted public Places with and without cooling information'
);

select results_eq(
  $$ select c.id, p.name, gis.st_x(p.location::gis.geometry), gis.st_y(p.location::gis.geometry) from public.cool_spots c join public.places p on p.id = c.place_id where c.id = 'db-permissions-cooling'; $$,
  $$ values ('db-permissions-cooling'::text, 'Published Cooling Place'::text, -0.125::double precision, 51.5::double precision); $$,
  'reader joins published cooling information to the adopted Place facts'
);

select throws_ok(
  $$ insert into public.places (name, location) values ('Unauthorized Place', 'SRID=4326;POINT(0 51)'); $$,
  '42501', null, 'reader cannot insert places'
);

select throws_ok(
  $$ update public.places set name = 'Unauthorized Change' where id = '00000000-0000-4000-8000-000000000301'; $$,
  '42501', null, 'reader cannot update places'
);

select throws_ok(
  $$ delete from public.places where id = '00000000-0000-4000-8000-000000000302'; $$,
  '42501', null, 'reader cannot delete places'
);

select throws_ok(
  $$ truncate table public.places; $$,
  '42501', null, 'reader cannot truncate places'
);

select throws_ok(
  $$ insert into public.cool_spots (id, place_id) values ('db-permissions-new', '00000000-0000-4000-8000-000000000303'); $$,
  '42501', null, 'reader cannot insert cool_spots'
);

select throws_ok(
  $$ update public.cool_spots set place_id = '00000000-0000-4000-8000-000000000303' where id = 'db-permissions-cooling'; $$,
  '42501', null, 'reader cannot update cool_spots'
);

select throws_ok(
  $$ delete from public.cool_spots where id = 'db-permissions-cooling'; $$,
  '42501', null, 'reader cannot delete cool_spots'
);

select throws_ok(
  $$ truncate table public.cool_spots; $$,
  '42501', null, 'reader cannot truncate cool_spots'
);

reset role;

select ok(not pg_has_role('anon', 'cool_spots_reader', 'MEMBER'), 'anon cannot inherit or assume the reader role');

select ok(not pg_has_role('authenticated', 'cool_spots_reader', 'MEMBER'), 'authenticated cannot inherit or assume the reader role');

select ok(not pg_has_role('authenticator', 'cool_spots_reader', 'MEMBER'), 'authenticator cannot inherit or assume the reader role');

-- DB-C25: New address columns keep the existing public-place access boundary.
select count(*) = 7 as address_ready from information_schema.columns where table_schema = 'public' and table_name = 'places' and column_name in ('address_line1', 'address_line2', 'address_locality', 'address_borough', 'address_postal_code', 'address_country_code', 'address_formatted') \gset
\if :address_ready

update public.places set address_line1 = '10 Example Road', address_line2 = 'Room 2', address_locality = 'Example Town', address_borough = 'Example Borough', address_postal_code = 'EX1 2AB', address_country_code = 'GB', address_formatted = 'Room 2, 10 Example Road, Example Town EX1 2AB' where id = '00000000-0000-4000-8000-000000000301';
update public.places set address_formatted = 'Example Garden, Example Town' where id = '00000000-0000-4000-8000-000000000302';

set local role anon;
select throws_ok(
  $$ select address_line1, address_line2, address_locality, address_borough, address_postal_code, address_country_code, address_formatted from public.places; $$,
  '42501', null, 'DB-C25: anon cannot directly read address columns'
);
select throws_ok(
  $$ update public.places set address_formatted = 'Unauthorized Address' where id = '00000000-0000-4000-8000-000000000301'; $$,
  '42501', null, 'anon cannot directly change an address'
);
reset role;

set local role authenticated;
select throws_ok(
  $$ select address_line1, address_line2, address_locality, address_borough, address_postal_code, address_country_code, address_formatted from public.places; $$,
  '42501', null, 'authenticated cannot directly read address columns'
);
select throws_ok(
  $$ update public.places set address_formatted = 'Unauthorized Address' where id = '00000000-0000-4000-8000-000000000301'; $$,
  '42501', null, 'authenticated cannot directly change an address'
);
reset role;

set local role cool_spots_reader;
select results_eq(
  $$ select id, address_line1, address_line2, address_locality, address_borough, address_postal_code, address_country_code, address_formatted from public.places where id in ('00000000-0000-4000-8000-000000000301', '00000000-0000-4000-8000-000000000302') order by id; $$,
  $$ values ('00000000-0000-4000-8000-000000000301'::uuid, '10 Example Road'::text, 'Room 2'::text, 'Example Town'::text, 'Example Borough'::text, 'EX1 2AB'::text, 'GB'::text, 'Room 2, 10 Example Road, Example Town EX1 2AB'::text), ('00000000-0000-4000-8000-000000000302'::uuid, null::text, null::text, null::text, null::text, null::text, null::text, 'Example Garden, Example Town'::text); $$,
  'reader sees address values for public Places with and without cooling information'
);
select throws_ok(
  $$ update public.places set address_formatted = 'Unauthorized Address' where id = '00000000-0000-4000-8000-000000000301'; $$,
  '42501', null, 'reader cannot change an address'
);
reset role;

select results_eq(
  $$ select address_formatted from public.places where id = '00000000-0000-4000-8000-000000000301'; $$,
  $$ values ('Room 2, 10 Example Road, Example Town EX1 2AB'::text); $$,
  'rejected address changes leave the published value intact'
);

\else
select skip('address permissions require the seven missing address columns', 7);
\endif

\else
select skip('behavior requires the missing places/cool_spots structure', 44);
\endif

select * from finish();
rollback;
