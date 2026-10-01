import type postgres from "npm:postgres@3.4.9";

export type PlacePhotoRow = {
  id: string;
  place_id: string;
  thumbnail_ref: string;
  image_ref: string;
  width: number;
  height: number;
  caption: string | null;
  captured_at: Date | null;
  published_at: Date | null;
  attribution: string;
  source_kind: string;
  contribution_id: string | null;
  position: number;
};

export type PlaceMapLinkRow = {
  place_id: string;
  provider: string;
  external_place_id: string;
  relationship: string;
  verification: string;
  checked_at: Date | null;
};

export type FieldInferenceRecordRow = {
  place_id: string;
  field_key: string;
  source_id: string;
  source_record_id: string;
  derivation_method: string;
  recorded_at: Date | null;
};

export type PlaceSourceLinkRow = {
  place_id: string;
  source_id: string;
  source_record_id: string;
  position: number;
};

export type DataSourceRow = {
  id: string;
  provider: string;
  label: string;
  dataset_name: string | null;
  source_url: string | null;
  download_url: string | null;
  retrieved_at: Date | null;
  source_updated_at: Date | null;
  raw_file_sha256: string | null;
  is_example: boolean;
};

export type CoolSpotRow = {
  id: string;
  place_id: string;
  name: string;
  latitude: number;
  longitude: number;
  address_formatted: string | null;
  address_line1: string | null;
  address_line2: string | null;
  address_locality: string | null;
  address_borough: string | null;
  address_postal_code: string | null;
  address_country_code: string | null;
  place_type: string;
  setting: string;
  cost: string;
  eligibility: string;
  seating: string;
  toilets: string;
  drinking_water: string;
  wheelchair_access: string;
  staffed_when_open: string;
  tables: string;
  cooling_features: string[];
  cooling_details: string | null;
  area_description: string | null;
  additional_information: string | null;
  hours_text: string | null;
  hours_time_zone: string | null;
  posted_stay_limit_status: string;
  posted_stay_limit_minutes: number | null;
};

export async function loadCoolSpotRows(
  sql: postgres.Sql | postgres.TransactionSql,
): Promise<CoolSpotRow[]> {
  const rows = await sql<CoolSpotRow[]>`
    select
      c.id,
      c.place_id,
      p.name,
      gis.st_y(p.location::gis.geometry) as latitude,
      gis.st_x(p.location::gis.geometry) as longitude,
      p.address_formatted,
      p.address_line1,
      p.address_line2,
      p.address_locality,
      p.address_borough,
      p.address_postal_code,
      p.address_country_code,
      p.place_type,
      c.setting,
      c.cost,
      c.eligibility,
      c.seating,
      c.toilets,
      c.drinking_water,
      c.wheelchair_access,
      c.staffed_when_open,
      c.tables,
      c.cooling_features,
      c.cooling_details,
      c.area_description,
      c.additional_information,
      c.hours_text,
      c.hours_time_zone,
      c.posted_stay_limit_status,
      c.posted_stay_limit_minutes
    from public.cool_spots c
    join public.places p on p.id = c.place_id
    order by c.id
  `;

  return [...rows];
}

export async function loadDataSourceRows(
  sql: postgres.Sql | postgres.TransactionSql,
): Promise<DataSourceRow[]> {
  const rows = await sql<DataSourceRow[]>`
    select
      id,
      provider,
      label,
      dataset_name,
      source_url,
      download_url,
      retrieved_at,
      source_updated_at,
      raw_file_sha256,
      is_example
    from public.data_sources
    order by id
  `;

  return [...rows];
}

export async function loadPlaceSourceLinks(
  sql: postgres.Sql | postgres.TransactionSql,
): Promise<PlaceSourceLinkRow[]> {
  const rows = await sql<PlaceSourceLinkRow[]>`
    select
      l.place_id,
      l.source_id,
      l.source_record_id,
      l.position
    from public.place_source_links l
    join public.cool_spots c on c.place_id = l.place_id
    order by l.place_id, l.position
  `;

  return [...rows];
}

export async function loadFieldInferenceRecordRows(
  sql: postgres.Sql | postgres.TransactionSql,
): Promise<FieldInferenceRecordRow[]> {
  const rows = await sql<FieldInferenceRecordRow[]>`
    select
      e.place_id,
      e.field_key,
      e.source_id,
      e.source_record_id,
      e.derivation_method,
      e.recorded_at
    from public.place_field_inference_records e
    join public.cool_spots c on c.place_id = e.place_id
    order by e.place_id, e.field_key
  `;

  return [...rows];
}

export async function loadPlaceMapLinkRows(
  sql: postgres.Sql | postgres.TransactionSql,
): Promise<PlaceMapLinkRow[]> {
  const rows = await sql<PlaceMapLinkRow[]>`
    select
      m.place_id,
      m.provider,
      m.external_place_id,
      m.relationship,
      m.verification,
      m.checked_at
    from public.place_map_links m
    join public.cool_spots c on c.place_id = m.place_id
    order by m.place_id, m.provider, m.external_place_id
  `;

  return [...rows];
}

export async function loadPlacePhotoRows(
  sql: postgres.Sql | postgres.TransactionSql,
): Promise<PlacePhotoRow[]> {
  const rows = await sql<PlacePhotoRow[]>`
    select
      f.id,
      f.place_id,
      f.thumbnail_ref,
      f.image_ref,
      f.width,
      f.height,
      f.caption,
      f.captured_at,
      f.published_at,
      f.attribution,
      f.source_kind,
      f.contribution_id,
      f.position
    from public.place_photos f
    join public.cool_spots c on c.place_id = f.place_id
    order by f.place_id, f.position
  `;

  return [...rows];
}
