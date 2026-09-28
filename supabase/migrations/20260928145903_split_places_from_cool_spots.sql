create table public.places (
    id uuid default gen_random_uuid() primary key,
    name text not null,
    location gis.geography(Point, 4326) not null,

    constraint places_name_length
        check (char_length(name) between 1 and 300),

    constraint places_name_not_blank
        check (
            name collate "C" ~
            U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200B\2028\2029\202F\205F\3000]'
        ),

    constraint places_location_valid
        check (
            not gis.st_isempty(location::gis.geometry)
            and gis.st_isvalid(location::gis.geometry)
        )
);

-- Assign and retain the mapping before moving existing facts.
alter table public.cool_spots
    add column place_id uuid;

update public.cool_spots
    set place_id = gen_random_uuid();

insert into public.places (id, name, location)
    select place_id, name, location
    from public.cool_spots;

-- Require one existing Place per Cool Spot, with no duplicate links.
alter table public.cool_spots
    alter column place_id set not null,

    add constraint cool_spots_place_id_key
        unique (place_id),

    add constraint cool_spots_place_id_fkey
        foreign key (place_id)
        references public.places (id)
        on delete restrict,

    drop column name,
    drop column location;

-- Accepted public Places are readable only through the backend role.
alter table public.places
    enable row level security;

revoke all on table public.places
    from public, anon, authenticated;

grant select on table public.places
    to cool_spots_reader;

create policy places_reader_select
    on public.places
    for select
    to cool_spots_reader
    using (true);