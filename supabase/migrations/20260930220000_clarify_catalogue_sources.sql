-- Clarify current source storage without rewriting immutable initial snapshots.
-- The CLI applies this entire migration in one local transaction.
do $$ begin
    -- Removing a duplicate is safe only when every item is already archived.
    if exists (
        select 1 from public.source_records r where not exists (
            select 1 from public.place_source_links l
            join public.catalogue_import_history h on h.place_id = l.place_id
            where l.source_id = r.source_id and l.record_id = r.record_id
                and h.evidence_snapshot->'item' = r.mapped_data
        )
    ) then
        raise exception 'Source item is not fully archived; source cleanup aborted';
    end if;
    -- The original header (including any extra keys) must remain archived.
    if exists (
        select 1 from public.data_sources s where not exists (
            select 1 from public.catalogue_import_history h
            cross join lateral jsonb_array_elements(
                h.evidence_snapshot#>'{document_metadata,sources}') header
            where header = s.metadata
        )
        or s.metadata->>'id' is distinct from s.id
        or s.metadata->>'provider' is distinct from s.provider
        or s.metadata->>'label' is distinct from s.label
        or (s.metadata->>'sha256' is not null
            and s.metadata->>'sha256' is distinct from s.raw_sha256)
    ) then
        raise exception 'Source header/hash is not consistently archived; source cleanup aborted';
    end if;
    -- Only labelled examples used this legacy code. Do not relabel real reviews.
    if exists (
        select 1 from public.place_field_evidence e
        join public.data_sources s on s.id = e.source_id
        where e.method = 'reviewed_contribution'
            and coalesce((s.metadata->>'isExample')::boolean, false) is not true
    ) then
        raise exception 'Non-example review needs separate migration; source cleanup aborted';
    end if;
end $$;

alter table public.data_sources
    add column dataset_name text check (length(btrim(dataset_name)) > 0),
    add column source_url text check (length(btrim(source_url)) > 0),
    add column download_url text check (length(btrim(download_url)) > 0),
    add column retrieved_at timestamptz,
    add column source_updated_at timestamptz,
    add column is_example boolean;
update public.data_sources set
    dataset_name = metadata->>'dataset',
    source_url = metadata->>'url',
    download_url = metadata->>'downloadURL',
    retrieved_at = (metadata->>'retrievedAt')::timestamptz,
    source_updated_at = (metadata->>'sourceUpdatedAt')::timestamptz,
    is_example = coalesce((metadata->>'isExample')::boolean, false);
alter table public.data_sources
    alter column is_example set not null,
    alter column is_example set default false,
    drop column metadata;
alter table public.data_sources rename column raw_sha256 to raw_file_sha256;
alter table public.data_sources rename constraint data_sources_raw_sha256_check to data_sources_raw_file_sha256_check;

-- Public source metadata does not include the administrator's local file path.
revoke select on public.data_sources from cool_spots_reader;
grant select(id,provider,label,dataset_name,source_url,download_url,retrieved_at,
    source_updated_at,is_example,raw_file_sha256) on public.data_sources to cool_spots_reader;

alter table public.source_records
    drop column mapped_data;
alter table public.source_records rename column record_id to source_record_id;
alter table public.source_records rename column raw_data to raw_record;
alter table public.source_records rename column mapping_evidence to import_audit;
alter table public.source_records rename constraint source_records_record_id_check to source_records_source_record_id_check;
alter table public.source_records rename constraint source_records_raw_data_check to source_records_raw_record_check;
alter table public.source_records rename constraint source_records_mapping_evidence_check to source_records_import_audit_check;
alter table public.place_source_links rename column record_id to source_record_id;
alter table public.place_source_links rename constraint place_source_links_source_id_record_id_fkey to place_source_links_source_record_fkey;

alter table public.place_field_evidence rename to place_field_inference_records;
alter table public.place_field_inference_records rename column record_id to source_record_id;
alter table public.place_field_inference_records rename column method to derivation_method;
alter table public.place_field_inference_records
    drop constraint place_field_evidence_method_check;
update public.place_field_inference_records set derivation_method = case derivation_method
    when 'imported' then 'mapped_from_source'
    when 'dataset_context' then 'inferred_from_context'
    when 'name_rule' then 'inferred_from_name'
    when 'reviewed_contribution' then 'example_data'
end;
alter table public.place_field_inference_records
    add constraint place_field_inference_records_derivation_method_check
    check (derivation_method in ('mapped_from_source','inferred_from_context','inferred_from_name','example_data'));
alter table public.place_field_inference_records rename constraint place_field_evidence_pkey to place_field_inference_records_pkey;
alter table public.place_field_inference_records rename constraint place_field_evidence_field_key_check to place_field_inference_records_field_key_check;
alter table public.place_field_inference_records rename constraint place_field_evidence_place_id_source_id_record_id_fkey to place_field_inference_records_place_source_link_fkey;
comment on table public.place_field_inference_records is
    'How current adopted fields were obtained: direct mapping, inference or labelled examples. Not all records are inferences; not a verification/history service.';
comment on column public.place_field_inference_records.recorded_at is
    'When the acquisition record was made, not a source download or an on-site verification.';

alter table public.catalogue_import_history rename column input_sha256 to import_payload_sha256;
alter table public.catalogue_import_history rename constraint catalogue_import_history_input_sha256_check to catalogue_import_history_import_payload_sha256_check;
comment on table public.catalogue_import_history is
    'Immutable first-import snapshots only. General correction history is not implemented.';
comment on column public.catalogue_import_history.import_payload_sha256 is
    'Fingerprint of the canonical initial importer payload. Preserve legacy canonicalization for identical retries.';
