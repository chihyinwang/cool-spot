-- Current adopted facts; this does not add an API or a publication workflow.
alter table public.places add column place_type text not null default 'unknown'
    check (place_type in ('library','community','faith','culture','leisure','shop','food','park','square','waterside','transport','other','unknown'));

alter table public.cool_spots
    add column setting text not null default 'unknown' check (setting in ('indoors','outdoors','both','unknown')),
    add column cost text not null default 'unknown' check (cost in ('free','purchase_required','entry_fee','unknown')),
    add column eligibility text not null default 'unknown' check (eligibility in ('everyone','limited','unknown')),
    add column seating text not null default 'unknown' check (seating in ('yes','limited','no','unknown')),
    add column toilets text not null default 'unknown' check (toilets in ('on_site','nearby','not_on_site','none','unknown')),
    add column drinking_water text not null default 'unknown' check (drinking_water in ('yes','no','unknown')),
    add column wheelchair_access text not null default 'unknown' check (wheelchair_access in ('yes','no','unknown')),
    add column staffed_when_open text not null default 'unknown' check (staffed_when_open in ('yes','no','unknown')),
    add column tables text not null default 'unknown' check (tables in ('yes','no','unknown')),
    add column cooling_features text[] not null default '{}' check ((cardinality(cooling_features)=0 or array_ndims(cooling_features)=1) and cooling_features <@ array['air_conditioning','fans','natural_ventilation','tree_shade','structural_shade','cooler_indoors','water_nearby']::text[]),
    add column cooling_details text check (cooling_details collate "C" ~ U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200B\2028\2029\202F\205F\3000]'),
    add column area_description text check (area_description collate "C" ~ U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200B\2028\2029\202F\205F\3000]'),
    add column additional_information text check (additional_information collate "C" ~ U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200B\2028\2029\202F\205F\3000]'),
    add column hours_text text check (hours_text collate "C" ~ U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200B\2028\2029\202F\205F\3000]'),
    add column hours_time_zone text check (hours_time_zone collate "C" ~ U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200B\2028\2029\202F\205F\3000]'),
    add column posted_stay_limit_status text not null default 'unknown' check (posted_stay_limit_status in ('limited','no_stated_limit','unknown')),
    add column posted_stay_limit_minutes integer,
    add constraint cool_spots_stay_limit_valid check (case when posted_stay_limit_status='limited' then posted_stay_limit_minutes is not null and posted_stay_limit_minutes>0 else posted_stay_limit_minutes is null end),
    add constraint cool_spots_hours_pair check ((hours_text is null) = (hours_time_zone is null));
