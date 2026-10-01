begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(24);

select ok(
    exists (select 1 from pg_roles where rolname = 'cool_spots_api'),
    'DB-C43: provides a dedicated backend login role'
);

select ok(
    coalesce((select not rolcanlogin from pg_roles where rolname = 'cool_spots_reader'), false),
    'the existing reader remains a permission role without login'
);

select exists (select 1 from pg_roles where rolname = 'cool_spots_api') as login_ready \gset
\if :login_ready

select ok(
    (select rolcanlogin and not rolsuper and not rolcreatedb and not rolcreaterole
        and not rolreplication and not rolbypassrls
     from pg_roles where rolname = 'cool_spots_api'),
    'DB-C43: backend login has no administrative or RLS bypass attributes'
);

select ok(
    not has_schema_privilege('cool_spots_api', 'public', 'CREATE')
        and not has_schema_privilege('cool_spots_api', 'gis', 'CREATE'),
    'DB-C45: backend login cannot create objects in the application schemas'
);

select ok(not pg_has_role('cool_spots_api', 'postgres', 'MEMBER'),
    'DB-C45: backend login cannot inherit or assume the database administrator');
select ok(not pg_has_role('anon', 'cool_spots_api', 'MEMBER'),
    'anon cannot inherit or assume the backend login');
select ok(not pg_has_role('authenticated', 'cool_spots_api', 'MEMBER'),
    'authenticated cannot inherit or assume the backend login');
select ok(not pg_has_role('authenticator', 'cool_spots_api', 'MEMBER'),
    'the Data API authenticator cannot inherit or assume the backend login');

-- Independent fixtures; all writes and temporary grants roll back at the end.
insert into public.places (id, name, location) values
    ('00000000-0000-4000-8000-000000000601', 'Backend Login Cooling Place', 'SRID=4326;POINT(-0.125 51.5)'),
    ('00000000-0000-4000-8000-000000000602', 'Backend Login Ordinary Place', 'SRID=4326;POINT(1 52)');
insert into public.cool_spots (id, place_id) values
    ('db-backend-login-cooling', '00000000-0000-4000-8000-000000000601');

-- Harness access only: do not grant any domain-table rights in this test.
grant usage on schema extensions to cool_spots_api;
grant cool_spots_api to current_user with inherit false, set true;
set local role cool_spots_api;

select ok(current_user = 'cool_spots_api',
    'executes permission checks as the backend login');

select results_eq(
    $$ select name from public.places
       where id in ('00000000-0000-4000-8000-000000000601', '00000000-0000-4000-8000-000000000602')
       order by id $$,
    $$ values ('Backend Login Cooling Place'::text), ('Backend Login Ordinary Place'::text) $$,
    'DB-C44: backend login reads accepted Places with and without cooling information'
);

select results_eq(
    $$ select c.id, p.name,
              gis.st_y(p.location::gis.geometry), gis.st_x(p.location::gis.geometry)
       from public.cool_spots c join public.places p on p.id = c.place_id
       where c.id = 'db-backend-login-cooling' $$,
    $$ values ('db-backend-login-cooling'::text,
               'Backend Login Cooling Place'::text, 51.5::double precision, -0.125::double precision) $$,
    'backend login reads the joined current facts through its own effective permissions'
);

select throws_ok(
    $$ insert into public.places (name, location) values ('Unauthorized Place', 'SRID=4326;POINT(0 51)') $$,
    '42501', null, 'backend login cannot insert Places');
select throws_ok(
    $$ update public.places set name = 'Unauthorized Change' where id = '00000000-0000-4000-8000-000000000601' $$,
    '42501', null, 'backend login cannot update Places');
select throws_ok(
    $$ delete from public.places where id = '00000000-0000-4000-8000-000000000602' $$,
    '42501', null, 'backend login cannot delete Places');
select throws_ok(
    $$ truncate table public.places $$,
    '42501', null, 'backend login cannot truncate Places');

select throws_ok(
    $$ insert into public.cool_spots (id, place_id) values ('db-backend-login-new', '00000000-0000-4000-8000-000000000602') $$,
    '42501', null, 'backend login cannot insert Cool Spots');
select throws_ok(
    $$ update public.cool_spots set cost = 'entry_fee' where id = 'db-backend-login-cooling' $$,
    '42501', null, 'backend login cannot update Cool Spots');
select throws_ok(
    $$ delete from public.cool_spots where id = 'db-backend-login-cooling' $$,
    '42501', null, 'backend login cannot delete Cool Spots');
select throws_ok(
    $$ truncate table public.cool_spots $$,
    '42501', null, 'backend login cannot truncate Cool Spots');

select throws_ok($$ select raw_record from public.source_records $$,
    '42501', null, 'backend login cannot read raw source payloads');
select throws_ok($$ select raw_file_path from public.data_sources $$,
    '42501', null, 'backend login cannot read local archive paths');
select throws_ok($$ select import_audit from public.source_records $$,
    '42501', null, 'backend login cannot read private source reconciliation evidence');
select throws_ok($$ select * from public.catalogue_import_history $$,
    '42501', null, 'backend login cannot read initial import history');
select throws_ok($$ select evidence from public.place_map_links $$,
    '42501', null, 'backend login cannot read private map reconciliation evidence');

reset role;

\else
select skip('behavior requires the missing backend login role', 22);
\endif

select * from finish();
rollback;
