alter table public.places
    add column address_line1 text,
    add column address_line2 text,
    add column address_locality text,
    add column address_borough text,
    add column address_postal_code text,
    add column address_country_code text,
    add column address_formatted text;
