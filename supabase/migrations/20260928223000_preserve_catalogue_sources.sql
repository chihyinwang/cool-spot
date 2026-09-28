-- Initial catalogue evidence. Public facts remain in places and cool_spots.
-- No application login, reader implementation or public write entry point is added.
create table public.data_sources (
    id text primary key check (length(btrim(id)) > 0),
    provider text not null check (length(btrim(provider)) > 0),
    label text not null check (length(btrim(label)) > 0),
    metadata jsonb not null check (jsonb_typeof(metadata) = 'object'),
    raw_file_path text,
    raw_sha256 text check (raw_sha256 ~ '^[0-9a-f]{64}$')
);
create table public.source_records (
    source_id text not null references public.data_sources(id) on delete restrict,
    record_id text not null check (length(btrim(record_id)) > 0),
    raw_data jsonb not null check (jsonb_typeof(raw_data) = 'object'),
    mapped_data jsonb not null check (jsonb_typeof(mapped_data) = 'object'),
    mapping_evidence jsonb not null check (jsonb_typeof(mapping_evidence) = 'object'),
    primary key (source_id, record_id)
);
create table public.place_source_links (
    place_id uuid not null references public.places(id) on delete restrict,
    source_id text not null,
    record_id text not null,
    position integer not null check (position >= 0),
    primary key (place_id, source_id, record_id),
    unique (place_id, position),
    foreign key (source_id, record_id) references public.source_records(source_id, record_id) on delete restrict
);
create table public.place_map_links (
    place_id uuid not null references public.places(id) on delete restrict,
    provider text not null check (provider = 'apple_maps'),
    external_place_id text not null check (length(btrim(external_place_id)) > 0),
    relationship text not null check (relationship in ('same_place','within_place')),
    verification text not null check (verification in ('automatic','reviewed')),
    checked_at timestamptz,
    evidence jsonb not null default '{}' check (jsonb_typeof(evidence) = 'object'),
    primary key (place_id, provider, external_place_id)
);
create unique index place_map_links_same_place_identity on public.place_map_links(provider,external_place_id)
    where relationship = 'same_place';
create table public.place_field_evidence (
    place_id uuid not null,
    field_key text not null check (field_key ~ '^(places|cool_spots)\.[a-z_.]+$' and field_key not in ('places.location_scope','cool_spots.eligibility_details')),
    source_id text not null,
    record_id text not null,
    method text not null check (method in ('imported','dataset_context','name_rule','reviewed_contribution')),
    recorded_at timestamptz,
    primary key (place_id, field_key),
    foreign key (place_id,source_id,record_id) references public.place_source_links(place_id,source_id,record_id) on delete restrict
);
create table public.place_photos (
    id text primary key check (length(btrim(id)) > 0),
    place_id uuid not null references public.places(id) on delete restrict,
    thumbnail_ref text not null check (length(btrim(thumbnail_ref)) > 0),
    image_ref text not null check (length(btrim(image_ref)) > 0),
    width integer not null check (width > 0),
    height integer not null check (height > 0),
    caption text,
    captured_at timestamptz,
    published_at timestamptz,
    attribution text not null,
    source_kind text not null check (source_kind in ('community','provider','illustration')),
    contribution_id text,
    position integer not null check (position >= 0),
    unique(place_id, position)
);
-- A retained initial event, not a general correction/moderation history workflow.
create table public.catalogue_import_history (
    id bigint generated always as identity primary key,
    place_id uuid not null references public.places(id) on delete restrict,
    cool_spot_id text not null unique references public.cool_spots(id) on delete restrict,
    input_sha256 text not null check (input_sha256 ~ '^[0-9a-f]{64}$'),
    place_snapshot jsonb not null check (jsonb_typeof(place_snapshot) = 'object'),
    cool_spot_snapshot jsonb not null check (jsonb_typeof(cool_spot_snapshot) = 'object'),
    evidence_snapshot jsonb not null check (jsonb_typeof(evidence_snapshot) = 'object'),
    imported_at timestamptz not null default now()
);

do $$
declare table_name text;
begin
    foreach table_name in array array['data_sources','source_records','place_source_links','place_map_links','place_field_evidence','place_photos','catalogue_import_history'] loop
        execute format('alter table public.%I enable row level security', table_name);
        execute format('revoke all on table public.%I from public, anon, authenticated, cool_spots_reader', table_name);
        if table_name <> 'catalogue_import_history' then
            execute format('create policy reader_select on public.%I for select to cool_spots_reader using (true)', table_name);
        end if;
    end loop;
end $$;
grant select on public.data_sources, public.place_source_links, public.place_field_evidence, public.place_photos to cool_spots_reader;
grant select(source_id,record_id) on public.source_records to cool_spots_reader;
grant select(place_id,provider,external_place_id,relationship,verification,checked_at) on public.place_map_links to cool_spots_reader;
revoke all on sequence public.catalogue_import_history_id_seq from public,anon,authenticated,cool_spots_reader;
