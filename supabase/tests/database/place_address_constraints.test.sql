begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(223);

-- DB-C26: Unknown is NULL; empty and whitespace-only text is not an address.
create temporary table address_columns (column_name text);
insert into address_columns values
  ('address_line1'), ('address_line2'), ('address_locality'),
  ('address_borough'), ('address_postal_code'), ('address_formatted');

-- The same fixed 26-character whitespace set already agreed for Place names.
create temporary table blank_samples (sample_order integer, sample text);
insert into blank_samples values (0, '');
insert into blank_samples select code_point, chr(code_point) from (values
  (9), (10), (11), (12), (13), (32), (133), (160), (5760),
  (8192), (8193), (8194), (8195), (8196), (8197), (8198), (8199),
  (8200), (8201), (8202), (8203), (8232), (8233), (8239), (8287), (12288)
) as characters(code_point);
insert into blank_samples select 30000, string_agg(sample, '' order by sample_order) from blank_samples where sample_order > 0;

select throws_ok(
  format('insert into public.places (name, location, %I) values (%L, %L, %L)', column_name, 'DB Invalid Address Insert', 'SRID=4326;POINT(0 51)', sample),
  '23514', null, format('DB-C26: rejects %s blank sample %s on INSERT', column_name, sample_order)
) from address_columns cross join blank_samples order by column_name, sample_order;

-- DB-C27: Rejected updates cannot overwrite the existing address.
insert into public.places (id, name, location, address_line1, address_line2, address_locality, address_borough, address_postal_code, address_formatted)
values ('00000000-0000-4000-8000-000000000501', 'DB Address Update Validation', 'SRID=4326;POINT(0 51)', '10 Example Road', 'Room 2', 'Example Town', 'Example Borough', 'EX1 2AB', 'Room 2, 10 Example Road, Example Town EX1 2AB');

select throws_ok(
  format('update public.places set %I = %L where id = %L', column_name, sample, '00000000-0000-4000-8000-000000000501'),
  '23514', null, format('DB-C27: rejects %s blank sample %s on UPDATE', column_name, sample_order)
) from address_columns cross join blank_samples where sample_order in (0, 30000) order by column_name, sample_order;

select results_eq(
  $$ select address_line1, address_line2, address_locality, address_borough, address_postal_code, address_formatted from public.places where id = '00000000-0000-4000-8000-000000000501'; $$,
  $$ values ('10 Example Road'::text, 'Room 2'::text, 'Example Town'::text, 'Example Borough'::text, 'EX1 2AB'::text, 'Room 2, 10 Example Road, Example Town EX1 2AB'::text); $$,
  'failed address changes preserve all original values'
);

-- DB-C28: Validation does not trim, transliterate or truncate meaningful text.
select lives_ok(
  $$ insert into public.places (id, name, location, address_line1, address_line2, address_locality, address_borough, address_postal_code, address_formatted) values ('00000000-0000-4000-8000-000000000502', 'DB Address Exact Text', 'SRID=4326;POINT(0 51)', E' 10 O''Brien Road ', '涼爽室 2', '臺北', 'Example Borough', ' EX1 2AB ', E'涼爽室 2\n10 O''Brien Road '); $$,
  'DB-C28: accepts meaningful address text with Unicode, apostrophes and whitespace'
);

select results_eq(
  $$ select address_line1, address_line2, address_locality, address_borough, address_postal_code, address_formatted from public.places where id = '00000000-0000-4000-8000-000000000502'; $$,
  $$ values (E' 10 O''Brien Road '::text, '涼爽室 2'::text, '臺北'::text, 'Example Borough'::text, ' EX1 2AB '::text, E'涼爽室 2\n10 O''Brien Road '::text); $$,
  'preserves meaningful address text exactly as supplied'
);

select lives_ok(
  $$ insert into public.places (name, location, address_line1, address_line2, address_locality, address_borough, address_postal_code, address_formatted) values ('DB One Character Address', 'SRID=4326;POINT(0 51)', 'X', 'Y', 'Z', 'A', '1', '涼'); $$,
  'accepts one meaningful character in each general address field'
);

select lives_ok(
  $$ insert into public.places (id, name, location, address_line1, address_line2, address_locality, address_borough, address_postal_code, address_formatted) values ('00000000-0000-4000-8000-000000000503', 'DB Long Address', 'SRID=4326;POINT(0 51)', repeat('街', 301), repeat('室', 301), repeat('市', 301), repeat('區', 301), repeat('1', 301), repeat('址', 301)); $$,
  'address fields do not inherit the unrelated 300-character Place-name limit'
);

select results_eq(
  $$ select address_line1, address_line2, address_locality, address_borough, address_postal_code, address_formatted from public.places where id = '00000000-0000-4000-8000-000000000503'; $$,
  $$ values (repeat('街', 301), repeat('室', 301), repeat('市', 301), repeat('區', 301), repeat('1', 301), repeat('址', 301)); $$,
  'does not truncate long address components'
);

-- DB-C29: Match the existing v4 format, not a country membership registry.
create temporary table invalid_country_codes (sample_order integer, sample text);
insert into invalid_country_codes values
  (1, ''), (2, ' '), (3, U&'\00A0'), (4, 'gb'), (5, 'Gb'), (6, 'gB'),
  (7, 'G'), (8, 'GBR'), (9, 'G1'), (10, '1B'), (11, 'G-'), (12, 'ＧＢ'),
  (13, E'GB\n'), (14, E'\nGB'), (15, ' GB'), (16, 'GB ');

select throws_ok(
  format('insert into public.places (name, location, address_country_code) values (%L, %L, %L)', 'DB Invalid Country Insert', 'SRID=4326;POINT(0 51)', sample),
  '23514', null, format('DB-C29: rejects invalid country-code sample %s on INSERT', sample_order)
) from invalid_country_codes order by sample_order;

insert into public.places (id, name, location, address_country_code) values ('00000000-0000-4000-8000-000000000504', 'DB Country Update Validation', 'SRID=4326;POINT(0 51)', 'GB');

select throws_ok(
  format('update public.places set address_country_code = %L where id = %L', sample, '00000000-0000-4000-8000-000000000504'),
  '23514', null, format('rejects invalid country-code sample %s on UPDATE', sample_order)
) from invalid_country_codes order by sample_order;

select results_eq(
  $$ select address_country_code from public.places where id = '00000000-0000-4000-8000-000000000504'; $$,
  $$ values ('GB'::text); $$,
  'failed country-code changes preserve the original value'
);

select lives_ok(
  $$ insert into public.places (name, location, address_country_code) values ('DB Valid Country GB', 'SRID=4326;POINT(0 51)', 'GB'), ('DB Valid Country TW', 'SRID=4326;POINT(1 52)', 'TW'), ('DB Valid Country US', 'SRID=4326;POINT(2 53)', 'US'); $$,
  'accepts two uppercase ASCII letters without restricting Places to GB'
);

select results_eq(
  $$ select address_country_code from public.places where name like 'DB Valid Country %' order by address_country_code; $$,
  $$ values ('GB'::text), ('TW'::text), ('US'::text); $$,
  'preserves valid country codes'
);

select lives_ok(
  $$ update public.places set address_country_code = 'FR' where id = '00000000-0000-4000-8000-000000000504'; $$,
  'accepts a country-code correction in the existing v4 format'
);

select results_eq(
  $$ select address_country_code from public.places where id = '00000000-0000-4000-8000-000000000504'; $$,
  $$ values ('FR'::text); $$,
  'reads the corrected country code'
);

select * from finish();
rollback;
