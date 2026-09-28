begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(24);

-- DB-C13: Public places are read through the custom API's dedicated role.
select ok(
  exists (select 1 from pg_roles where rolname = 'cool_spots_reader'),
  'provides a dedicated role for the Cool Spots API reader'
);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.cool_spots'::regclass),
  'enables row-level security on published Cool Spots'
);

-- DB-C14: Valid fixtures ensure permission checks are not constraint failures.
insert into public.cool_spots (id, name, location) values
  ('db-permissions-anon-update', 'Original Place', 'SRID=4326;POINT(0 51)'),
  ('db-permissions-anon-delete', 'Another Place', 'SRID=4326;POINT(1 52)');

set local role anon;

select is(current_user::text, 'anon', 'executes client checks as anon');

select throws_ok(
  $$select id, name from public.cool_spots;$$,
  '42501', null, 'anon cannot directly read published places'
);

select throws_ok(
  $$
    insert into public.cool_spots (id, name, location)
    values ('db-permissions-anon-insert', 'New Place', 'SRID=4326;POINT(2 53)');
  $$,
  '42501', null, 'anon cannot insert published places'
);

select throws_ok(
  $$
    update public.cool_spots set name = 'Changed Place'
    where id = 'db-permissions-anon-update';
  $$,
  '42501', null, 'anon cannot update published places'
);

select throws_ok(
  $$delete from public.cool_spots where id = 'db-permissions-anon-delete';$$,
  '42501', null, 'anon cannot delete published places'
);

select throws_ok(
  $$truncate table public.cool_spots;$$,
  '42501', null, 'anon cannot truncate published places'
);

reset role;

-- DB-C14: Valid fixtures ensure permission checks are not constraint failures.
insert into public.cool_spots (id, name, location) values
  ('db-permissions-authenticated-update', 'Original Place', 'SRID=4326;POINT(0 51)'),
  ('db-permissions-authenticated-delete', 'Another Place', 'SRID=4326;POINT(1 52)');

set local role authenticated;

select is(current_user::text, 'authenticated', 'executes client checks as authenticated');

select throws_ok(
  $$select id, name from public.cool_spots;$$,
  '42501', null, 'authenticated cannot directly read published places'
);

select throws_ok(
  $$
    insert into public.cool_spots (id, name, location)
    values ('db-permissions-authenticated-insert', 'New Place', 'SRID=4326;POINT(2 53)');
  $$,
  '42501', null, 'authenticated cannot insert published places'
);

select throws_ok(
  $$
    update public.cool_spots set name = 'Changed Place'
    where id = 'db-permissions-authenticated-update';
  $$,
  '42501', null, 'authenticated cannot update published places'
);

select throws_ok(
  $$delete from public.cool_spots where id = 'db-permissions-authenticated-delete';$$,
  '42501', null, 'authenticated cannot delete published places'
);

select throws_ok(
  $$truncate table public.cool_spots;$$,
  '42501', null, 'authenticated cannot truncate published places'
);

reset role;

-- DB-C15: Missing role is reported above; do not misreport skipped behavior as tested.
select exists (
  select 1 from pg_roles where rolname = 'cool_spots_reader'
) as reader_exists \gset

\if :reader_exists
select ok(
  (
    select not rolcanlogin and not rolsuper and not rolbypassrls
      and not rolcreatedb and not rolcreaterole and not rolreplication
    from pg_roles where rolname = 'cool_spots_reader'
  ),
  'reader is a non-login permission role without administrative privileges'
);

-- Test harness only: allow pgTAP calls, without granting access to place data.
grant usage on schema extensions to cool_spots_reader;

-- Supabase's postgres role can administer reader membership but cannot SET ROLE by default.
-- Temporarily allow the test session to switch identity; ROLLBACK restores membership.
grant cool_spots_reader to current_user with inherit false, set true;

insert into public.cool_spots (id, name, location) values
  ('db-permissions-reader-a', 'First Reader Place', 'SRID=4326;POINT(-0.125 51.5)'),
  ('db-permissions-reader-b', 'Second Reader Place', 'SRID=4326;POINT(1 52)');

set local role cool_spots_reader;

select is(
  current_user::text, 'cool_spots_reader',
  'executes API database checks as the dedicated reader'
);

select results_eq(
  $$
    select id, name,
      gis.st_x(location::gis.geometry),
      gis.st_y(location::gis.geometry)
    from public.cool_spots
    where id in ('db-permissions-reader-a', 'db-permissions-reader-b')
    order by id;
  $$,
  $$
    values
      ('db-permissions-reader-a'::text, 'First Reader Place'::text,
        -0.125::double precision, 51.5::double precision),
      ('db-permissions-reader-b'::text, 'Second Reader Place'::text,
        1::double precision, 52::double precision);
  $$,
  'reader can retrieve published identities, names and coordinates'
);

select throws_ok(
  $$
    insert into public.cool_spots (id, name, location)
    values ('db-permissions-reader-insert', 'New Place', 'SRID=4326;POINT(2 53)');
  $$,
  '42501', null, 'reader cannot insert published places'
);

select throws_ok(
  $$
    update public.cool_spots set name = 'Changed Place'
    where id = 'db-permissions-reader-a';
  $$,
  '42501', null, 'reader cannot update published places'
);

select throws_ok(
  $$delete from public.cool_spots where id = 'db-permissions-reader-b';$$,
  '42501', null, 'reader cannot delete published places'
);

select throws_ok(
  $$truncate table public.cool_spots;$$,
  '42501', null, 'reader cannot truncate published places'
);

reset role;

-- Check named role membership: the test session itself belongs to the administrator.
select ok(
  not pg_has_role('anon', 'cool_spots_reader', 'MEMBER'),
  'anonymous clients cannot inherit or assume the reader role'
);

select ok(
  not pg_has_role('authenticated', 'cool_spots_reader', 'MEMBER'),
  'signed-in clients cannot inherit or assume the reader role'
);

select ok(
  not pg_has_role('authenticator', 'cool_spots_reader', 'MEMBER'),
  'the Data API authenticator cannot assume the reader role'
);
\else
select skip('reader behavior requires the missing cool_spots_reader role', 10);
\endif

select * from finish();
rollback;
