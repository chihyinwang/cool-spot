import { deepStrictEqual, throws } from "node:assert";
import type {
  CoolSpotRow,
  DataSourceRow,
  FieldInferenceRecordRow,
  PlacePhotoRow,
} from "./database_reader.ts";
import { assembleCoolSpotsResponse } from "./response.ts";

Deno.test("V5-C01: empty v5 responses retain the dataset identity and each supplied generation time", () => {
  const responses = [
    assembleCoolSpotsResponse([], new Date("2026-10-01T12:34:56+01:00")),
    assembleCoolSpotsResponse([], new Date("2026-10-01T12:35:56+01:00")),
  ];

  deepStrictEqual(responses, [
    {
      schemaVersion: 5,
      datasetID: "cool-spot-prototype",
      generatedAt: "2026-10-01T11:34:56.000Z",
      sources: [],
      items: [],
    },
    {
      schemaVersion: 5,
      datasetID: "cool-spot-prototype",
      generatedAt: "2026-10-01T11:35:56.000Z",
      sources: [],
      items: [],
    },
  ]);
});

Deno.test("V5-C02: formal rows become public items without replacing either identity or changing adopted values", () => {
  const rows = [
    makeRow(),
    makeRow({
      id: "second-cool-spot-id",
      place_id: "22222222-2222-4222-8222-222222222222",
      name: "TEST Second Place",
      latitude: 0,
      longitude: 0,
    }),
  ];

  const response = assembleCoolSpotsResponse(
    rows,
    new Date("2026-10-01T11:34:56Z"),
  );

  deepStrictEqual(
    response,
    expectedResponse([
      expectedItem(),
      expectedItem({
        id: "second-cool-spot-id",
        placeID: "22222222-2222-4222-8222-222222222222",
        name: "TEST Second Place",
        location: { latitude: 0, longitude: 0 },
      }),
    ]),
  );
});

Deno.test("V5-C03: absent details, empty features and unknown access values remain distinct from negative facts", () => {
  const row = makeRow({
    address_formatted: null,
    address_line1: null,
    address_line2: null,
    address_locality: null,
    address_borough: null,
    address_postal_code: null,
    address_country_code: null,
    cooling_features: [],
    cooling_details: null,
    area_description: null,
    additional_information: null,
    hours_text: null,
    hours_time_zone: null,
    cost: "unknown",
    eligibility: "unknown",
    seating: "no",
    toilets: "not_on_site",
    drinking_water: "unknown",
    wheelchair_access: "unknown",
    staffed_when_open: "no",
    tables: "unknown",
    posted_stay_limit_status: "unknown",
    posted_stay_limit_minutes: null,
  });

  const response = assembleCoolSpotsResponse(
    [row],
    new Date("2026-10-01T11:34:56Z"),
  );

  deepStrictEqual(
    response,
    expectedResponse([expectedItem({
      address: {
        formatted: null,
        line1: null,
        line2: null,
        locality: null,
        borough: null,
        postalCode: null,
        countryCode: null,
      },
      coolingFeatures: [],
      coolingDetails: null,
      additionalInformation: null,
      access: {
        cost: "unknown",
        eligibility: "unknown",
        seating: "no",
        toilets: "not_on_site",
        drinkingWater: "unknown",
        wheelchairAccess: "unknown",
        staffedWhenOpen: "no",
        tables: "unknown",
        areaDescription: null,
        postedStayLimit: { status: "unknown", minutes: null },
      },
      hours: null,
    })]),
  );
});

Deno.test("V5-C04: public JSON excludes retired fields, internal columns and unexpected source data", () => {
  // Deliberately synthetic extras detect spreading an internal row into JSON.
  // These values do not come from private database tables or archived inputs.
  const row = {
    ...makeRow(),
    location_scope: "venue",
    eligibility_details: "TEST historical access statement",
    raw_record: { name: "TEST raw source name" },
    archived_item: { name: "TEST old catalogue name" },
    import_audit: { note: "TEST internal audit" },
  };

  const response = assembleCoolSpotsResponse(
    [row],
    new Date("2026-10-01T11:34:56Z"),
  );

  // Compare the entire wire value: extra keys are not silently ignored.
  deepStrictEqual(
    JSON.parse(JSON.stringify(response)),
    expectedResponse([expectedItem()]),
  );
});

Deno.test("V5-C05: public sources preserve year, example labels, hashes and known or unknown source dates", () => {
  const row = makeRow();
  const response = assembleCoolSpotsResponse([row], generationTime(), {
    sources: [
      makeSource(),
      makeSource({
        id: "test-examples",
        provider: "community",
        label: "Example cooling info",
        dataset_name: null,
        source_url: null,
        download_url: null,
        retrieved_at: new Date("2025-08-01T14:00:00+01:00"),
        source_updated_at: new Date("2025-07-31T16:00:00+01:00"),
        raw_file_sha256: null,
        is_example: true,
      }),
    ],
    sourceLinks: [
      {
        place_id: row.place_id,
        source_id: "test-gla",
        source_record_id: "18",
        position: 0,
      },
      {
        place_id: row.place_id,
        source_id: "test-examples",
        source_record_id: "example-1",
        position: 1,
      },
    ],
  });
  deepStrictEqual(response, {
    ...expectedResponse([expectedItem({
      sourceReferences: [
        { sourceID: "test-gla", recordID: "18" },
        { sourceID: "test-examples", recordID: "example-1" },
      ],
    })]),
    sources: [
      expectedSource({
        id: "test-examples",
        provider: "community",
        label: "Example cooling info",
        dataset: null,
        url: null,
        downloadURL: null,
        retrievedAt: "2025-08-01T13:00:00.000Z",
        sourceUpdatedAt: "2025-07-31T15:00:00.000Z",
        sha256: null,
        isExample: true,
      }),
      expectedSource(),
    ],
  });
});

Deno.test("V5-C06: source references use Place identity and primary-source order without leaking internal fields", () => {
  const first = makeRow();
  const second = makeRow({
    id: "second-cool-spot-id",
    place_id: "second-place-id",
  });
  const source = {
    ...makeSource(),
    raw_file_path: "TEST private archive path",
    raw_record: { note: "TEST private" },
  };
  const response = assembleCoolSpotsResponse(
    [first, second],
    generationTime(),
    {
      sources: [source],
      sourceLinks: [
        {
          place_id: first.place_id,
          source_id: "test-gla",
          source_record_id: "secondary",
          position: 1,
        },
        {
          place_id: second.place_id,
          source_id: "test-gla",
          source_record_id: "other-place",
          position: 0,
        },
        {
          place_id: first.place_id,
          source_id: "test-gla",
          source_record_id: "primary",
          position: 0,
        },
      ],
    },
  );
  deepStrictEqual(JSON.parse(JSON.stringify(response)), {
    ...expectedResponse([
      expectedItem({
        sourceReferences: [
          { sourceID: "test-gla", recordID: "primary" },
          { sourceID: "test-gla", recordID: "secondary" },
        ],
      }),
      expectedItem({
        id: "second-cool-spot-id",
        placeID: "second-place-id",
        sourceReferences: [
          { sourceID: "test-gla", recordID: "other-place" },
        ],
      }),
    ]),
    sources: [expectedSource()],
  });
});

Deno.test("V5-C07: a reference to a missing source fails instead of inventing its attribution", () => {
  const row = makeRow();
  throws(() =>
    assembleCoolSpotsResponse([row], generationTime(), {
      sources: [],
      sourceLinks: [{
        place_id: row.place_id,
        source_id: "missing",
        source_record_id: "18",
        position: 0,
      }],
    }), /Referenced catalogue source is missing/);
});

Deno.test("V5-C08: unrelated sources and Place links stay outside an empty catalogue", () => {
  deepStrictEqual(
    assembleCoolSpotsResponse([], generationTime(), {
      sources: [makeSource()],
      sourceLinks: [{
        place_id: "outside-place",
        source_id: "test-gla",
        source_record_id: "18",
        position: 0,
      }],
    }),
    expectedResponse([]),
  );
});

Deno.test("V5-C09: field acquisition records become grouped public pointers with their actual methods and recording times", () => {
  const row = makeRow();
  deepStrictEqual(
    assembleCoolSpotsResponse([row], generationTime(), {
      ...sourceRelations(row),
      inferenceRecords: [
        makeInference({ field_key: "places.location.longitude" }),
        makeInference({ field_key: "places.name" }),
        makeInference({ field_key: "places.location.latitude" }),
        makeInference({
          field_key: "cool_spots.hours_time_zone",
          derivation_method: "inferred_from_context",
          recorded_at: null,
        }),
        makeInference({
          field_key: "places.place_type",
          derivation_method: "inferred_from_name",
        }),
      ],
    }),
    {
      ...expectedResponse([expectedItem({
        sourceReferences: [{ sourceID: "test-gla", recordID: "18" }],
        provenance: [
          {
            sourceID: "test-gla",
            recordID: "18",
            method: "inferred_from_context",
            recordedAt: null,
            fields: ["/hours/timeZone"],
          },
          {
            sourceID: "test-gla",
            recordID: "18",
            method: "inferred_from_name",
            recordedAt: "2025-09-01T09:00:00.000Z",
            fields: ["/placeType"],
          },
          {
            sourceID: "test-gla",
            recordID: "18",
            method: "mapped_from_source",
            recordedAt: "2025-09-01T09:00:00.000Z",
            fields: ["/location/latitude", "/location/longitude", "/name"],
          },
        ],
      })]),
      sources: [expectedSource()],
    },
  );
});

Deno.test("V5-C10: unknown field mappings and unlinked field sources fail rather than publishing misleading evidence", () => {
  const row = makeRow();
  throws(() =>
    assembleCoolSpotsResponse([row], generationTime(), {
      ...sourceRelations(row),
      inferenceRecords: [makeInference({ field_key: "places.location_scope" })],
    }), /Unsupported catalogue field/);
  throws(() =>
    assembleCoolSpotsResponse([row], generationTime(), {
      ...sourceRelations(row),
      inferenceRecords: [makeInference({ source_record_id: "not-linked" })],
    }), /Field source is not linked to this Place/);
});

Deno.test("V5-C11: map references keep external identity, same-place or containment meaning and dates without moving the Place", () => {
  const row = makeRow();
  deepStrictEqual(
    assembleCoolSpotsResponse([row], generationTime(), {
      mapLinks: [
        {
          place_id: row.place_id,
          provider: "apple_maps",
          external_place_id: "I2",
          relationship: "within_place",
          verification: "reviewed",
          checked_at: new Date("2025-09-01T10:00:00+01:00"),
          ...{ evidence: { note: "TEST private map audit" } },
        },
        {
          place_id: "unrelated-place",
          provider: "apple_maps",
          external_place_id: "outside",
          relationship: "same_place",
          verification: "reviewed",
          checked_at: null,
        },
        {
          place_id: row.place_id,
          provider: "apple_maps",
          external_place_id: "I1",
          relationship: "same_place",
          verification: "automatic",
          checked_at: null,
        },
      ],
    }),
    expectedResponse([expectedItem({
      mapReferences: [
        {
          provider: "apple_maps",
          placeID: "I1",
          relationship: "same_place",
          verification: "automatic",
          checkedAt: null,
        },
        {
          provider: "apple_maps",
          placeID: "I2",
          relationship: "within_place",
          verification: "reviewed",
          checkedAt: "2025-09-01T09:00:00.000Z",
        },
      ],
    })]),
  );
});

Deno.test("V5-C12: ordered photo resources preserve URLs, credits, captions and known or unknown dates without invented authors", () => {
  const row = makeRow();
  const photo = { ...makePhoto(), internal_note: "TEST private photo note" };
  deepStrictEqual(
    assembleCoolSpotsResponse([row], generationTime(), {
      photos: [
        photo,
        makePhoto({
          id: "earlier-photo",
          position: 0,
          thumbnail_ref: "https://example.com/thumb.jpg",
          image_ref: "https://example.com/image.jpg",
          source_kind: "provider",
          caption: null,
          captured_at: new Date("2025-08-01T10:00:00+01:00"),
          published_at: new Date("2025-09-01T10:00:00+01:00"),
          contribution_id: "test-contribution",
        }),
        makePhoto({ id: "outside-photo", place_id: "unrelated-place" }),
      ],
    }),
    expectedResponse([expectedItem({
      photos: [
        {
          id: "earlier-photo",
          thumbnailURL: "https://example.com/thumb.jpg",
          imageURL: "https://example.com/image.jpg",
          width: 1448,
          height: 1086,
          caption: null,
          capturedAt: "2025-08-01T09:00:00.000Z",
          publishedAt: "2025-09-01T09:00:00.000Z",
          attribution: "TEST image credit",
          source: "provider",
          contributionID: "test-contribution",
        },
        {
          id: "test-photo",
          thumbnailURL: "bundle://TEST.jpg",
          imageURL: "bundle://TEST.jpg",
          width: 1448,
          height: 1086,
          caption: "TEST entrance",
          capturedAt: null,
          publishedAt: null,
          attribution: "TEST image credit",
          source: "illustration",
          contributionID: null,
        },
      ],
    })]),
  );
});

Deno.test("V5-C13: empty relations preserve catalogue items without fabricated maps, photos or evidence", () => {
  deepStrictEqual(
    assembleCoolSpotsResponse([makeRow()], generationTime(), {
      inferenceRecords: [],
      mapLinks: [],
      photos: [],
    }),
    expectedResponse([expectedItem()]),
  );
});

// MARK: - Helpers

function sourceRelations(row: CoolSpotRow) {
  return {
    sources: [makeSource()],
    sourceLinks: [
      {
        place_id: row.place_id,
        source_id: "test-gla",
        source_record_id: "18",
        position: 0,
      },
    ],
  };
}

function makeInference(
  overrides: Partial<FieldInferenceRecordRow> = {},
): FieldInferenceRecordRow {
  return {
    place_id: "11111111-1111-4111-8111-111111111111",
    field_key: "places.name",
    source_id: "test-gla",
    source_record_id: "18",
    derivation_method: "mapped_from_source",
    recorded_at: new Date("2025-09-01T10:00:00+01:00"),
    ...overrides,
  };
}

function makePhoto(overrides: Partial<PlacePhotoRow> = {}): PlacePhotoRow {
  return {
    id: "test-photo",
    place_id: "11111111-1111-4111-8111-111111111111",
    thumbnail_ref: "bundle://TEST.jpg",
    image_ref: "bundle://TEST.jpg",
    width: 1448,
    height: 1086,
    caption: "TEST entrance",
    captured_at: null,
    published_at: null,
    attribution: "TEST image credit",
    source_kind: "illustration",
    contribution_id: null,
    position: 1,
    ...overrides,
  };
}

function generationTime() {
  return new Date("2026-10-01T11:34:56Z");
}

function makeSource(overrides: Partial<DataSourceRow> = {}): DataSourceRow {
  return {
    id: "test-gla",
    provider: "gla",
    label: "GLA · 2025",
    dataset_name: "Cool Space Data 2025",
    source_url: "https://example.com/gla",
    download_url: "https://example.com/gla.json",
    retrieved_at: null,
    source_updated_at: null,
    raw_file_sha256: "a".repeat(64),
    is_example: false,
    ...overrides,
  };
}

function expectedSource(overrides: Record<string, unknown> = {}) {
  return {
    id: "test-gla",
    provider: "gla",
    label: "GLA · 2025",
    dataset: "Cool Space Data 2025",
    url: "https://example.com/gla",
    downloadURL: "https://example.com/gla.json",
    retrievedAt: null,
    sourceUpdatedAt: null,
    sha256: "a".repeat(64),
    isExample: false,
    ...overrides,
  };
}

function makeRow(overrides: Partial<CoolSpotRow> = {}): CoolSpotRow {
  return {
    id: "original-cool-spot-id",
    place_id: "11111111-1111-4111-8111-111111111111",
    name: "  TEST Current Library Name  ",
    latitude: 51.51,
    longitude: -0.12,
    address_formatted: "TEST full address",
    address_line1: "1 TEST Road",
    address_line2: "Floor 4",
    address_locality: "London",
    address_borough: "TEST Borough",
    address_postal_code: "TEST 1AA",
    address_country_code: "GB",
    place_type: "library",
    setting: "indoors",
    cost: "free",
    eligibility: "unknown",
    seating: "limited",
    toilets: "nearby",
    drinking_water: "unknown",
    wheelchair_access: "no",
    staffed_when_open: "yes",
    tables: "no",
    cooling_features: ["fans"],
    cooling_details: "Fans beside the windows",
    area_description: "Fourth-floor reading room",
    additional_information: "Ask staff about access",
    hours_text: "TEST source opening-hours text",
    hours_time_zone: "Europe/London",
    posted_stay_limit_status: "limited",
    posted_stay_limit_minutes: 30,
    ...overrides,
  };
}

function expectedResponse(items: readonly unknown[]) {
  return {
    schemaVersion: 5,
    datasetID: "cool-spot-prototype",
    generatedAt: "2026-10-01T11:34:56.000Z",
    sources: [],
    items,
  };
}

function expectedItem(overrides: Record<string, unknown> = {}) {
  return {
    id: "original-cool-spot-id",
    placeID: "11111111-1111-4111-8111-111111111111",
    sourceReferences: [],
    provenance: [],
    mapReferences: [],
    photos: [],
    name: "  TEST Current Library Name  ",
    location: { latitude: 51.51, longitude: -0.12 },
    address: {
      formatted: "TEST full address",
      line1: "1 TEST Road",
      line2: "Floor 4",
      locality: "London",
      borough: "TEST Borough",
      postalCode: "TEST 1AA",
      countryCode: "GB",
    },
    placeType: "library",
    setting: "indoors",
    coolingFeatures: ["fans"],
    coolingDetails: "Fans beside the windows",
    additionalInformation: "Ask staff about access",
    access: {
      cost: "free",
      eligibility: "unknown",
      seating: "limited",
      toilets: "nearby",
      drinkingWater: "unknown",
      wheelchairAccess: "no",
      staffedWhenOpen: "yes",
      tables: "no",
      areaDescription: "Fourth-floor reading room",
      postedStayLimit: { status: "limited", minutes: 30 },
    },
    hours: {
      text: "TEST source opening-hours text",
      timeZone: "Europe/London",
    },
    ...overrides,
  };
}
