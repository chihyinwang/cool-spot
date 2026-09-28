begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(78);

-- DB-C01: Test-only identities do not overlap with the bundled place data.
select lives_ok(
  $$
    insert into public.cool_spots (id, name, location) values
      (
        '00000000-0000-4000-8000-000000000001',
        'Database Test Library',
        'SRID=4326;POINT(0.010439996 51.516829995)'
      ),
      (
        'db-test-legacy-place',
        'Database Test Garden',
        'SRID=4326;POINT(-0.1246 51.5007)'
      );
  $$,
  'stores places with UUID-shaped and legacy text identities'
);

-- A missing table is reported by the write assertions, not a query bailout.
select to_regclass('public.cool_spots') is not null as cool_spots_exists \gset
\if :cool_spots_exists
select results_eq(
  $$
    select id, name,
      gis.st_x(location::gis.geometry) as longitude,
      gis.st_y(location::gis.geometry) as latitude
    from public.cool_spots
    where id in (
      '00000000-0000-4000-8000-000000000001',
      'db-test-legacy-place'
    )
    order by id;
  $$,
  $$
    values
      (
        '00000000-0000-4000-8000-000000000001'::text,
        'Database Test Library'::text,
        0.010439996::double precision,
        51.516829995::double precision
      ),
      (
        'db-test-legacy-place'::text,
        'Database Test Garden'::text,
        -0.1246::double precision,
        51.5007::double precision
      );
  $$,
  'reads back the same identities, names, longitudes and latitudes'
);
\else
select skip('read-back requires the missing cool_spots table', 1);
\endif

-- DB-C02: This case prepares its own row, independently of DB-C01.
select throws_ok(
  $$
    do $duplicate$
    begin
      insert into public.cool_spots (id, name, location)
      values ('db-test-duplicate', 'First Place', 'SRID=4326;POINT(0 51)');

      insert into public.cool_spots (id, name, location)
      values ('db-test-duplicate', 'Second Place', 'SRID=4326;POINT(1 52)');
    end;
    $duplicate$;
  $$,
  '23505',
  null,
  'rejects a second place with an existing identity'
);

-- DB-C03: Each missing required value must produce a NOT NULL violation.
select throws_ok(
  $$
    insert into public.cool_spots (id, name, location)
    values (null, 'Missing Identity', 'SRID=4326;POINT(0 51)');
  $$,
  '23502',
  null,
  'rejects a place without an identity'
);

select throws_ok(
  $$
    insert into public.cool_spots (id, name, location)
    values ('db-test-missing-name', null, 'SRID=4326;POINT(0 51)');
  $$,
  '23502',
  null,
  'rejects a place without a name'
);

select throws_ok(
  $$
    insert into public.cool_spots (id, name, location)
    values ('db-test-missing-location', 'Missing Location', null);
  $$,
  '23502',
  null,
  'rejects a place without a location'
);

-- DB-C04: Empty strings are values, so NOT NULL alone does not reject them.
select throws_ok(
  $$
    insert into public.cool_spots (id, name, location)
    values ('', 'Empty Identity', 'SRID=4326;POINT(0 51)');
  $$,
  '23514',
  null,
  'rejects an empty identity'
);

select throws_ok(
  $$
    insert into public.cool_spots (id, name, location)
    values ('db-test-empty-name', '', 'SRID=4326;POINT(0 51)');
  $$,
  '23514',
  null,
  'rejects an empty name'
);

-- DB-C05: The name limit counts characters, not UTF-8 bytes.
select lives_ok(
  $$
    insert into public.cool_spots (id, name, location)
    values ('x', 'X', 'SRID=4326;POINT(0 51)');
  $$,
  'accepts a one-character identity and name'
);

select lives_ok(
  $$
    insert into public.cool_spots (id, name, location)
    values ('db-test-name-300', repeat('涼', 300), 'SRID=4326;POINT(0 51)');
  $$,
  'accepts a name containing 300 multibyte characters'
);

select throws_ok(
  $$
    insert into public.cool_spots (id, name, location)
    values ('db-test-name-301', repeat('涼', 301), 'SRID=4326;POINT(0 51)');
  $$,
  '23514',
  null,
  'rejects a name containing 301 characters'
);

-- DB-C06: Validation also applies to changes after insertion.
select throws_ok(
  $$
    do $invalid_update$
    begin
      insert into public.cool_spots (id, name, location)
      values ('db-test-update-name', 'Valid Name', 'SRID=4326;POINT(0 51)');

      update public.cool_spots
      set name = ''
      where id = 'db-test-update-name';
    end;
    $invalid_update$;
  $$,
  '23514',
  null,
  'rejects changing an existing name to an empty string'
);

-- DB-C07: Match the whitespace/newline set used by the current Swift reader.
-- Explicit code points keep the fixtures independent of SQL regex classes.
-- This temporary table and all test rows disappear on rollback.
create temporary table whitespace_samples as
select code_point, chr(code_point) as sample
from (values
  (9), (10), (11), (12), (13), (32), (133), (160), (5760),
  (8192), (8193), (8194), (8195), (8196), (8197), (8198), (8199),
  (8200), (8201), (8202), (8203), (8232), (8233), (8239), (8287), (12288)
) as characters(code_point);

select throws_ok(
  format(
    'insert into public.cool_spots (id, name, location) values (%L, %L, %L)',
    sample, 'Blank Identity', 'SRID=4326;POINT(0 51)'
  ),
  '23514',
  null,
  'rejects an identity containing only U+' || upper(lpad(to_hex(code_point), 4, '0'))
)
from whitespace_samples
order by code_point;

select throws_ok(
  format(
    'insert into public.cool_spots (id, name, location) values (%L, %L, %L)',
    'db-test-blank-name-' || code_point, sample, 'SRID=4326;POINT(0 51)'
  ),
  '23514',
  null,
  'rejects a name containing only U+' || upper(lpad(to_hex(code_point), 4, '0'))
)
from whitespace_samples
order by code_point;

select throws_ok(
  format(
    'insert into public.cool_spots (id, name, location) values (%L, %L, %L)',
    string_agg(sample, '' order by code_point),
    'Mixed Blank Identity', 'SRID=4326;POINT(0 51)'
  ),
  '23514',
  null,
  'rejects an identity containing a mixture of whitespace characters'
)
from whitespace_samples;

select throws_ok(
  format(
    'insert into public.cool_spots (id, name, location) values (%L, %L, %L)',
    'db-test-mixed-blank-name',
    string_agg(sample, '' order by code_point), 'SRID=4326;POINT(0 51)'
  ),
  '23514',
  null,
  'rejects a name containing a mixture of whitespace characters'
)
from whitespace_samples;

-- DB-C08: Each update arranges its own valid row.
select throws_ok(
  $$
    do $blank_identity_update$
    begin
      insert into public.cool_spots (id, name, location)
      values ('db-test-update-blank-id', 'Valid Name', 'SRID=4326;POINT(0 51)');

      update public.cool_spots
      set id = U&'\0020\0009\3000'
      where id = 'db-test-update-blank-id';
    end;
    $blank_identity_update$;
  $$,
  '23514',
  null,
  'rejects changing an existing identity to whitespace only'
);

select throws_ok(
  $$
    do $blank_name_update$
    begin
      insert into public.cool_spots (id, name, location)
      values ('db-test-update-blank-name', 'Valid Name', 'SRID=4326;POINT(0 51)');

      update public.cool_spots
      set name = U&'\0020\0009\3000'
      where id = 'db-test-update-blank-name';
    end;
    $blank_name_update$;
  $$,
  '23514',
  null,
  'rejects changing an existing name to whitespace only'
);

-- DB-C09: Validation must preserve meaningful input, not trim or merge IDs.
select lives_ok(
  $$
    insert into public.cool_spots (id, name, location) values
      (
        U&'\0009\00A0db-test-preserved\200B\3000',
        U&'\3000涼 Library\00A0\000A',
        'SRID=4326;POINT(0 51)'
      ),
      ('db-test-preserved', 'Unpadded Identity', 'SRID=4326;POINT(1 52)');
  $$,
  'accepts nonblank padded text and a distinct unpadded identity'
);

select results_eq(
  $$
    select id, name from public.cool_spots
    where id in (U&'\0009\00A0db-test-preserved\200B\3000', 'db-test-preserved')
    order by id collate "C";
  $$,
  $$
    values
      (U&'\0009\00A0db-test-preserved\200B\3000'::text, U&'\3000涼 Library\00A0\000A'::text),
      ('db-test-preserved'::text, 'Unpadded Identity'::text);
  $$,
  'reads back the original identities and names without trimming'
);

-- DB-C10: Geographic limits and zero coordinates are valid values.
select lives_ok(
  $$
    insert into public.cool_spots (id, name, location) values
      ('db-test-coordinate-1', 'Southwest Limit', 'SRID=4326;POINT(-180 -90)'),
      ('db-test-coordinate-2', 'Northwest Limit', 'SRID=4326;POINT(-180 90)'),
      ('db-test-coordinate-3', 'Southeast Limit', 'SRID=4326;POINT(180 -90)'),
      ('db-test-coordinate-4', 'Northeast Limit', 'SRID=4326;POINT(180 90)'),
      ('db-test-coordinate-5', 'Zero Coordinate', 'SRID=4326;POINT(0 0)');
  $$,
  'accepts longitude and latitude limits and the zero coordinate'
);

select results_eq(
  $$
    select id,
      gis.st_x(location::gis.geometry) as longitude,
      gis.st_y(location::gis.geometry) as latitude
    from public.cool_spots
    where id in (
      'db-test-coordinate-1', 'db-test-coordinate-2', 'db-test-coordinate-3',
      'db-test-coordinate-4', 'db-test-coordinate-5'
    )
    order by id;
  $$,
  $$
    values
      ('db-test-coordinate-1'::text, -180::double precision, -90::double precision),
      ('db-test-coordinate-2'::text, -180::double precision, 90::double precision),
      ('db-test-coordinate-3'::text, 180::double precision, -90::double precision),
      ('db-test-coordinate-4'::text, 180::double precision, 90::double precision),
      ('db-test-coordinate-5'::text, 0::double precision, 0::double precision);
  $$,
  'reads back the original boundary and zero coordinates'
);

-- DB-C11: An empty point is not NULL but cannot locate a place.
-- DB-C12: Neither coordinate may be NaN.
select throws_ok(
  format(
    'insert into public.cool_spots (id, name, location) values (%L, %L, %L)',
    'db-test-location-insert-' || label, 'Invalid Location', point
  ),
  '23514',
  null,
  'rejects inserting a location with ' || label
)
from (values
  ('empty-point', 'SRID=4326;POINT EMPTY'),
  ('nan-longitude', 'SRID=4326;POINT(NaN 51)'),
  ('nan-latitude', 'SRID=4326;POINT(0 NaN)')
) as invalid_locations(label, point)
order by label;

-- Every update prepares its own valid row, independently of earlier cases.
select throws_ok(
  format(
    $statement$
      do $invalid_location_update$
      begin
        insert into public.cool_spots (id, name, location)
        values (%1$L, 'Valid Location', 'SRID=4326;POINT(0 51)');

        update public.cool_spots
        set location = %2$L
        where id = %1$L;
      end;
      $invalid_location_update$;
    $statement$,
    'db-test-location-update-' || label, point
  ),
  '23514',
  null,
  'rejects changing an existing location to ' || label
)
from (values
  ('empty-point', 'SRID=4326;POINT EMPTY'),
  ('nan-longitude', 'SRID=4326;POINT(NaN 51)'),
  ('nan-latitude', 'SRID=4326;POINT(0 NaN)')
) as invalid_locations(label, point)
order by label;

select * from finish();
rollback;
