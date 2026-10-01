import type {
  CoolSpotRow,
  DataSourceRow,
  FieldInferenceRecordRow,
  PlaceMapLinkRow,
  PlacePhotoRow,
  PlaceSourceLinkRow,
} from "./database_reader.ts";

export type CatalogueRelations = {
  sources?: readonly DataSourceRow[];
  sourceLinks?: readonly PlaceSourceLinkRow[];
  inferenceRecords?: readonly FieldInferenceRecordRow[];
  mapLinks?: readonly PlaceMapLinkRow[];
  photos?: readonly PlacePhotoRow[];
};

export function assembleCoolSpotsResponse(
  rows: readonly CoolSpotRow[],
  generatedAt: Date,
  relations: CatalogueRelations = {},
) {
  const placeIDs = new Set(rows.map((row) => row.place_id));
  const sourceLinks = [...relations.sourceLinks ?? []]
    .filter((link) => placeIDs.has(link.place_id))
    .sort((a, b) => a.position - b.position);
  const linksByPlace = groupByPlace(sourceLinks);
  const inferenceByPlace = groupByPlace(relations.inferenceRecords ?? []);
  const mapsByPlace = groupByPlace(
    [...(relations.mapLinks ?? [])].sort((a, b) =>
      compare(a.provider, b.provider) ||
      compare(a.external_place_id, b.external_place_id)
    ),
  );
  const photosByPlace = groupByPlace(
    [...(relations.photos ?? [])].sort((a, b) => a.position - b.position),
  );
  const sourceByID = new Map(
    (relations.sources ?? []).map((source) => [source.id, source]),
  );
  const sources = [...new Set(sourceLinks.map((link) => link.source_id))]
    .sort()
    .map((id) => {
      const source = sourceByID.get(id);
      if (!source) throw new Error("Referenced catalogue source is missing");
      return {
        id: source.id,
        provider: source.provider,
        label: source.label,
        dataset: source.dataset_name,
        url: source.source_url,
        downloadURL: source.download_url,
        retrievedAt: source.retrieved_at?.toISOString() ?? null,
        sourceUpdatedAt: source.source_updated_at?.toISOString() ?? null,
        sha256: source.raw_file_sha256,
        isExample: source.is_example,
      };
    });
  return {
    schemaVersion: 5,
    datasetID: "cool-spot-prototype",
    generatedAt: generatedAt.toISOString(),
    sources,
    items: rows.map((row) => ({
      id: row.id,
      placeID: row.place_id,
      sourceReferences: (linksByPlace.get(row.place_id) ?? []).map((link) => ({
        sourceID: link.source_id,
        recordID: link.source_record_id,
      })),
      provenance: assembleProvenance(
        inferenceByPlace.get(row.place_id) ?? [],
        linksByPlace.get(row.place_id) ?? [],
      ),
      mapReferences: (mapsByPlace.get(row.place_id) ?? []).map((link) => ({
        provider: link.provider,
        placeID: link.external_place_id,
        relationship: link.relationship,
        verification: link.verification,
        checkedAt: link.checked_at?.toISOString() ?? null,
      })),
      photos: (photosByPlace.get(row.place_id) ?? []).map((photo) => ({
        id: photo.id,
        thumbnailURL: photo.thumbnail_ref,
        imageURL: photo.image_ref,
        width: photo.width,
        height: photo.height,
        caption: photo.caption,
        capturedAt: photo.captured_at?.toISOString() ?? null,
        publishedAt: photo.published_at?.toISOString() ?? null,
        attribution: photo.attribution,
        source: photo.source_kind,
        contributionID: photo.contribution_id,
      })),
      name: row.name,
      location: {
        latitude: row.latitude,
        longitude: row.longitude,
      },
      address: {
        formatted: row.address_formatted,
        line1: row.address_line1,
        line2: row.address_line2,
        locality: row.address_locality,
        borough: row.address_borough,
        postalCode: row.address_postal_code,
        countryCode: row.address_country_code,
      },
      placeType: row.place_type,
      setting: row.setting,
      coolingFeatures: row.cooling_features,
      coolingDetails: row.cooling_details,
      additionalInformation: row.additional_information,
      access: {
        cost: row.cost,
        eligibility: row.eligibility,
        seating: row.seating,
        toilets: row.toilets,
        drinkingWater: row.drinking_water,
        wheelchairAccess: row.wheelchair_access,
        staffedWhenOpen: row.staffed_when_open,
        tables: row.tables,
        areaDescription: row.area_description,
        postedStayLimit: {
          status: row.posted_stay_limit_status,
          minutes: row.posted_stay_limit_minutes,
        },
      },
      hours: row.hours_text === null ? null : {
        text: row.hours_text,
        timeZone: row.hours_time_zone,
      },
    })),
  };
}

function groupByPlace<T extends { place_id: string }>(rows: readonly T[]) {
  const groups = new Map<string, T[]>();
  for (const row of rows) {
    const group = groups.get(row.place_id) ?? [];
    group.push(row);
    groups.set(row.place_id, group);
  }
  return groups;
}

function compare(a: string, b: string) {
  return a < b ? -1 : a > b ? 1 : 0;
}

function assembleProvenance(
  records: readonly FieldInferenceRecordRow[],
  links: readonly PlaceSourceLinkRow[],
) {
  const linkedRecords = new Set(
    links.map((link) =>
      JSON.stringify([link.source_id, link.source_record_id])
    ),
  );
  const groups = new Map<
    string,
    {
      sourceID: string;
      recordID: string;
      method: string;
      recordedAt: string | null;
      fields: string[];
    }
  >();
  for (const record of records) {
    const pointer = fieldPointers.get(record.field_key);
    if (!pointer) throw new Error("Unsupported catalogue field");
    if (
      !linkedRecords.has(
        JSON.stringify([record.source_id, record.source_record_id]),
      )
    ) {
      throw new Error("Field source is not linked to this Place");
    }
    const recordedAt = record.recorded_at?.toISOString() ?? null;
    const key = JSON.stringify([
      record.source_id,
      record.source_record_id,
      record.derivation_method,
      recordedAt,
    ]);
    const group = groups.get(key) ?? {
      sourceID: record.source_id,
      recordID: record.source_record_id,
      method: record.derivation_method,
      recordedAt,
      fields: [],
    };
    group.fields.push(pointer);
    groups.set(key, group);
  }
  return [...groups.entries()].sort(([a], [b]) => compare(a, b)).map((
    [, group],
  ) => ({ ...group, fields: group.fields.sort() }));
}

const fieldPointers = new Map(Object.entries({
  "places.name": "/name",
  "places.place_type": "/placeType",
  "places.location.latitude": "/location/latitude",
  "places.location.longitude": "/location/longitude",
  "places.address_formatted": "/address/formatted",
  "places.address_line1": "/address/line1",
  "places.address_line2": "/address/line2",
  "places.address_locality": "/address/locality",
  "places.address_borough": "/address/borough",
  "places.address_postal_code": "/address/postalCode",
  "places.address_country_code": "/address/countryCode",
  "cool_spots.setting": "/setting",
  "cool_spots.cooling_features": "/coolingFeatures",
  "cool_spots.cooling_details": "/coolingDetails",
  "cool_spots.additional_information": "/additionalInformation",
  "cool_spots.cost": "/access/cost",
  "cool_spots.eligibility": "/access/eligibility",
  "cool_spots.seating": "/access/seating",
  "cool_spots.toilets": "/access/toilets",
  "cool_spots.drinking_water": "/access/drinkingWater",
  "cool_spots.wheelchair_access": "/access/wheelchairAccess",
  "cool_spots.staffed_when_open": "/access/staffedWhenOpen",
  "cool_spots.tables": "/access/tables",
  "cool_spots.area_description": "/access/areaDescription",
  "cool_spots.posted_stay_limit_status": "/access/postedStayLimit/status",
  "cool_spots.posted_stay_limit_minutes": "/access/postedStayLimit/minutes",
  "cool_spots.hours_text": "/hours/text",
  "cool_spots.hours_time_zone": "/hours/timeZone",
}));
