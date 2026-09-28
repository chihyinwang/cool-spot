create role cool_spots_reader nologin;

grant usage on schema public, gis
    to cool_spots_reader;

alter table public.cool_spots
    enable row level security;

revoke all on table public.cool_spots
    from public, anon, authenticated;

grant select on table public.cool_spots
    to cool_spots_reader;

create policy cool_spots_reader_select
    on public.cool_spots
    for select
    to cool_spots_reader
    using (true);