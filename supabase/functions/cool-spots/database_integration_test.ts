import {
  AssertionError,
  deepStrictEqual,
  notStrictEqual,
  ok,
  strictEqual,
} from "node:assert";
import { createDatabaseClient } from "./database.ts";
import {
  type CoolSpotRow,
  loadCoolSpotRows,
  loadDataSourceRows,
  loadFieldInferenceRecordRows,
  loadPlaceMapLinkRows,
  loadPlacePhotoRows,
  loadPlaceSourceLinks,
} from "./database_reader.ts";
import glaCatalogue from "../../../cool-spot/Resources/CoolSpots.prototype.json" with {
  type: "json",
};
import exampleCatalogue from "../../../cool-spot/Resources/CommunityCoolSpots.prototype.json" with {
  type: "json",
};

Deno.test("DB-C46: backend login reads current place values over a real connection", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const identity = await sql`
      select current_user as role, session_user as login,
             inet_client_addr() is not null as uses_tcp
    `;
    deepStrictEqual([...identity], [{
      role: "cool_spots_api",
      login: "cool_spots_api",
      uses_tcp: true,
    }]);

    const coolSpotID = "5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab";
    const places = await sql`
      select c.id, p.name,
             gis.st_y(p.location::gis.geometry) as latitude,
             gis.st_x(p.location::gis.geometry) as longitude
      from public.cool_spots c
      join public.places p on p.id = c.place_id
      where c.id = ${coolSpotID}
    `;
    deepStrictEqual([...places], [{
      id: coolSpotID,
      name: "Canning Town Library",
      latitude: 51.516829995,
      longitude: 0.010439996,
    }]);
  });
});

Deno.test("DB-C47: an incorrect backend password is rejected", async () => {
  const url = new URL(localDatabaseURL());
  url.password = `intentionally-invalid-${crypto.randomUUID()}`;

  await withDatabase(url.toString(), async (sql) => {
    await expectDatabaseError(() => sql`select 1`, "28P01");
  });
});

Deno.test("DB-C48: the authenticated connection cannot write or read private snapshots", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const identity = await sql`select session_user as login`;
    strictEqual(identity[0].login, "cool_spots_api");

    // No row can change even if a permission regression makes UPDATE succeed.
    await expectDatabaseError(
      () => sql`update public.places set name = name where false`,
      "42501",
    );
    // LIMIT 0 checks access without retrieving private values if access regresses.
    await expectDatabaseError(
      () => sql`select raw_record from public.source_records limit 0`,
      "42501",
    );
    await expectDatabaseError(
      () => sql`select import_audit from public.source_records limit 0`,
      "42501",
    );
    await expectDatabaseError(
      () => sql`select raw_file_path from public.data_sources limit 0`,
      "42501",
    );
    await expectDatabaseError(
      () => sql`select * from public.catalogue_import_history limit 0`,
      "42501",
    );
  });
});

Deno.test("DB-C49: the reader returns all 253 original Cool Spot IDs in stable order", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    // Import inputs establish identity expectations only, never runtime values.
    const expectedIDs = [...glaCatalogue.items, ...exampleCatalogue.items]
      .map((item) => item.id)
      .sort();
    strictEqual(expectedIDs.length, 253);

    const rows = await loadCoolSpotRows(sql);

    strictEqual(rows.length, 253);
    deepStrictEqual(rows.map((row) => row.id), expectedIDs);
    strictEqual(new Set(rows.map((row) => row.place_id)).size, 253);
  });
});

Deno.test("DB-C50: the reader joins place facts while keeping both identities distinct", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const rows = await loadCoolSpotRows(sql);
    const library = rows.find((row) =>
      row.id === "5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab"
    );

    ok(library, "Expected Canning Town Library in the database reader result");
    deepStrictEqual({
      id: library.id,
      name: library.name,
      latitude: library.latitude,
      longitude: library.longitude,
    }, {
      id: "5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab",
      name: "Canning Town Library",
      latitude: 51.516829995,
      longitude: 0.010439996,
    });
    ok(
      /^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/.test(library.place_id),
      "Expected a Place UUID",
    );
    notStrictEqual(library.place_id, library.id);
  });
});

Deno.test("DB-C51: the reader preserves adopted address components and library type", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const rows = await loadCoolSpotRows(sql);
    const library = rows.find((row) =>
      row.id === "5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab"
    );
    ok(library, "Expected the library fixture");

    deepStrictEqual({
      address_formatted: library.address_formatted,
      address_line1: library.address_line1,
      address_line2: library.address_line2,
      address_locality: library.address_locality,
      address_borough: library.address_borough,
      address_postal_code: library.address_postal_code,
      address_country_code: library.address_country_code,
      place_type: library.place_type,
    }, {
      address_formatted: null,
      address_line1: "18 Rathbone Market",
      address_line2: null,
      address_locality: "London",
      address_borough: "Newham",
      address_postal_code: null,
      address_country_code: "GB",
      place_type: "library",
    });
  });
});

Deno.test("DB-C52: the reader preserves formatted address without inventing missing components", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const rows = await loadCoolSpotRows(sql);
    const example = rows.find((row) =>
      row.id === "f536167c-f689-4e46-8e2d-9a144ac03b7e"
    );
    ok(example, "Expected the Tate Modern example fixture");

    deepStrictEqual({
      address_formatted: example.address_formatted,
      address_line1: example.address_line1,
      address_line2: example.address_line2,
      address_locality: example.address_locality,
      address_borough: example.address_borough,
      address_postal_code: example.address_postal_code,
      address_country_code: example.address_country_code,
      place_type: example.place_type,
    }, {
      address_formatted: "Bankside, London SE1 9TG",
      address_line1: null,
      address_line2: null,
      address_locality: "London",
      address_borough: null,
      address_postal_code: null,
      address_country_code: "GB",
      place_type: "culture",
    });
  });
});

Deno.test("DB-C53: the reader preserves cooling facts, access codes and original hours", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const rows = await loadCoolSpotRows(sql);
    const library = rows.find((row) =>
      row.id === "5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab"
    );
    ok(library, "Expected the library fixture");

    deepStrictEqual(coolingValues(library), {
      setting: "indoors",
      cost: "free",
      eligibility: "unknown",
      seating: "yes",
      toilets: "on_site",
      drinking_water: "yes",
      wheelchair_access: "yes",
      staffed_when_open: "yes",
      tables: "unknown",
      cooling_features: ["air_conditioning"],
      cooling_details: null,
      area_description: null,
      additional_information: null,
      hours_text:
        "Monday - Saturday -9am-8pm, Sunday closed, Public Holidays - Closed",
      hours_time_zone: "Europe/London",
      posted_stay_limit_status: "unknown",
      posted_stay_limit_minutes: null,
    });
  });
});

Deno.test("DB-C54: the reader distinguishes unavailable, unknown and limited example facilities", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const rows = await loadCoolSpotRows(sql);
    const room = rows.find((row) =>
      row.id === "bc21d832-6796-46ac-81ac-c96dc242dd18"
    );
    const garden = rows.find((row) =>
      row.id === "23e2f374-3e18-445c-8f2a-db3fb7a8c130"
    );
    ok(room, "Expected the community room example fixture");
    ok(garden, "Expected the shaded garden example fixture");

    deepStrictEqual(coolingValues(room), {
      setting: "indoors",
      cost: "free",
      eligibility: "everyone",
      seating: "yes",
      toilets: "none",
      drinking_water: "yes",
      wheelchair_access: "no",
      staffed_when_open: "yes",
      tables: "yes",
      cooling_features: ["fans"],
      cooling_details: null,
      area_description: null,
      additional_information: null,
      hours_text: null,
      hours_time_zone: null,
      posted_stay_limit_status: "no_stated_limit",
      posted_stay_limit_minutes: null,
    });
    deepStrictEqual(coolingValues(garden), {
      setting: "outdoors",
      cost: "free",
      eligibility: "everyone",
      seating: "limited",
      toilets: "unknown",
      drinking_water: "unknown",
      wheelchair_access: "unknown",
      staffed_when_open: "no",
      tables: "unknown",
      cooling_features: ["tree_shade", "water_nearby"],
      cooling_details: null,
      area_description: null,
      additional_information: null,
      hours_text: null,
      hours_time_zone: null,
      posted_stay_limit_status: "unknown",
      posted_stay_limit_minutes: null,
    });
  });
});

Deno.test("DB-C55: the reader preserves an empty feature list and the adopted cooling description", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const rows = await loadCoolSpotRows(sql);
    const church = rows.find((row) =>
      row.id === "02672c40-a746-5cb5-975d-29024449e970"
    );
    ok(church, "Expected the church fixture");

    deepStrictEqual(coolingValues(church), {
      setting: "indoors",
      cost: "free",
      eligibility: "unknown",
      seating: "yes",
      toilets: "on_site",
      drinking_water: "yes",
      wheelchair_access: "no",
      staffed_when_open: "yes",
      tables: "unknown",
      cooling_features: [],
      cooling_details:
        "1830s church building that is naturally cooler than the outside temperature",
      area_description: null,
      additional_information: null,
      hours_text:
        "Mon - Friday 9.30am - 4.30pm Open to the public when not in use for private event.",
      hours_time_zone: "Europe/London",
      posted_stay_limit_status: "unknown",
      posted_stay_limit_minutes: null,
    });
  });
});

Deno.test("DB-C56: the source reader returns public GLA metadata with original year and unknown dates", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const sources = await loadDataSourceRows(sql);
    strictEqual(sources.length, 2);
    deepStrictEqual(sources.map((source) => source.id), [
      "gla-cool-spaces-2025",
      "prototype-community-examples",
    ]);
    const gla = sources.find((source) => source.id === "gla-cool-spaces-2025");
    ok(gla, "Expected the GLA 2025 source");

    // Exact public shape excludes local raw file paths and the whole metadata object.
    deepStrictEqual(gla, {
      id: "gla-cool-spaces-2025",
      provider: "gla",
      label: "GLA · 2025",
      dataset_name: "Cool Space Data 2025",
      source_url:
        "https://data.london.gov.uk/dataset/cool-space-data-2025-2z19p",
      download_url:
        "https://data.london.gov.uk/download/2z19p/blw/CoolSpaceSites_2025.json",
      retrieved_at: null,
      source_updated_at: null,
      raw_file_sha256:
        "070a3e86c54728da1c27bdab8a0a2e972d68a5aeee65276b50c350ddff980c14",
      is_example: false,
    });
  });
});

Deno.test("DB-C57: the source reader preserves the example flag and leaves missing metadata null", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const sources = await loadDataSourceRows(sql);
    const example = sources.find((source) =>
      source.id === "prototype-community-examples"
    );
    ok(example, "Expected the prototype example source");

    deepStrictEqual(example, {
      id: "prototype-community-examples",
      provider: "community",
      label: "Example cooling info",
      dataset_name: null,
      source_url: null,
      download_url: null,
      retrieved_at: null,
      source_updated_at: null,
      raw_file_sha256:
        "8d337b2307e8bb60e09ad77cee8c8f113cbbe1200dfbb7fc9f98b0565aec862d",
      is_example: true,
    });
  });
});

Deno.test("DB-C58: source links cover the imported catalogue with 250 GLA and three example records", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const spots = await loadCoolSpotRows(sql);
    const links = await loadPlaceSourceLinks(sql);

    strictEqual(links.length, 253);
    const expectedPlaceIDs = spots.map((spot) => spot.place_id).sort();
    deepStrictEqual(
      [...new Set(links.map((link) => link.place_id))].sort(),
      expectedPlaceIDs,
    );
    deepStrictEqual(links.map((link) => link.place_id), expectedPlaceIDs);
    strictEqual(
      links.filter((link) => link.source_id === "gla-cool-spaces-2025").length,
      250,
    );
    strictEqual(
      links.filter((link) => link.source_id === "prototype-community-examples")
        .length,
      3,
    );
    // This initial import has one source at position 0 per Place.
    // Future multiple-source behaviour needs separate fixtures and coverage.
    ok(links.every((link) => link.position === 0));
  });
});

Deno.test("DB-C59: source links retain the library record number and the example record identity", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const spots = await loadCoolSpotRows(sql);
    const library = spots.find((spot) =>
      spot.id === "5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab"
    );
    const tate = spots.find((spot) =>
      spot.id === "f536167c-f689-4e46-8e2d-9a144ac03b7e"
    );
    ok(library, "Expected the library fixture");
    ok(tate, "Expected the Tate example fixture");

    const links = await loadPlaceSourceLinks(sql);
    // Only relation identifiers and ordering are returned, never source payloads.
    deepStrictEqual(
      links.filter((link) => link.place_id === library.place_id),
      [{
        place_id: library.place_id,
        source_id: "gla-cool-spaces-2025",
        source_record_id: "18",
        position: 0,
      }],
    );
    deepStrictEqual(
      links.filter((link) => link.place_id === tate.place_id),
      [{
        place_id: tate.place_id,
        source_id: "prototype-community-examples",
        source_record_id: "f536167c-f689-4e46-8e2d-9a144ac03b7e",
        position: 0,
      }],
    );
  });
});

Deno.test("DB-C60: field evidence covers the imported catalogue and belongs to its source links", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const spots = await loadCoolSpotRows(sql);
    const links = await loadPlaceSourceLinks(sql);
    const evidence = await loadFieldInferenceRecordRows(sql);

    strictEqual(evidence.length, 5297);
    deepStrictEqual(
      [...new Set(evidence.map((row) => row.place_id))].sort(),
      spots.map((spot) => spot.place_id).sort(),
    );
    strictEqual(
      new Set(
        evidence.map((row) => JSON.stringify([row.place_id, row.field_key])),
      ).size,
      5297,
    );
    const linkedRecords = new Set(
      links.map((link) =>
        JSON.stringify([link.place_id, link.source_id, link.source_record_id])
      ),
    );
    ok(
      evidence.every((row) =>
        linkedRecords.has(
          JSON.stringify([row.place_id, row.source_id, row.source_record_id]),
        )
      ),
      "Expected every field's source record to be linked to the same Place",
    );
    ok(
      evidence.every((row) =>
        row.field_key !== "places.location_scope" &&
        row.field_key !== "cool_spots.eligibility_details"
      ),
      "Retired fields must not return as current field evidence",
    );
  });
});

Deno.test("DB-C61: library acquisition records distinguish source mapping, context inference and name inference", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const spots = await loadCoolSpotRows(sql);
    const library = spots.find((spot) =>
      spot.id === "5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab"
    );
    ok(library, "Expected the library fixture");
    const evidence = await loadFieldInferenceRecordRows(sql);

    for (
      const expected of [
        {
          field_key: "cool_spots.cooling_features",
          derivation_method: "mapped_from_source",
        },
        {
          field_key: "cool_spots.hours_time_zone",
          derivation_method: "inferred_from_context",
        },
        {
          field_key: "places.place_type",
          derivation_method: "inferred_from_name",
        },
      ]
    ) {
      // Exact rows exclude adopted values and private source snapshots.
      deepStrictEqual(
        evidence.find((row) =>
          row.place_id === library.place_id &&
          row.field_key === expected.field_key
        ),
        {
          place_id: library.place_id,
          field_key: expected.field_key,
          source_id: "gla-cool-spaces-2025",
          source_record_id: "18",
          derivation_method: expected.derivation_method,
          recorded_at: new Date("2026-09-19T00:16:05Z"),
        },
      );
    }
  });
});

Deno.test("DB-C62: example acquisition records are labelled as examples and retain recorded time", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const spots = await loadCoolSpotRows(sql);
    const tate = spots.find((spot) =>
      spot.id === "f536167c-f689-4e46-8e2d-9a144ac03b7e"
    );
    ok(tate, "Expected the Tate example fixture");
    const evidence = await loadFieldInferenceRecordRows(sql);
    deepStrictEqual(
      evidence.find((row) =>
        row.place_id === tate.place_id &&
        row.field_key === "cool_spots.cooling_features"
      ),
      {
        place_id: tate.place_id,
        field_key: "cool_spots.cooling_features",
        source_id: "prototype-community-examples",
        source_record_id: "f536167c-f689-4e46-8e2d-9a144ac03b7e",
        // Example data is not evidence of a live review service.
        derivation_method: "example_data",
        recorded_at: new Date("2026-09-18T22:32:22Z"),
      },
    );
  });
});

Deno.test("DB-C68: map links return all accepted identities in stable order with public fields only", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const spots = await loadCoolSpotRows(sql);
    const links = await loadPlaceMapLinkRows(sql);
    strictEqual(links.length, 145);

    // Retained inputs establish the accepted identity ledger for this initial
    // catalogue. The runtime reader must query the formal relation table.
    const placeIDs = new Map(spots.map((spot) => [spot.id, spot.place_id]));
    const expectedIdentities = [
      ...glaCatalogue.items,
      ...exampleCatalogue.items,
    ]
      .flatMap((item) => {
        const placeID = placeIDs.get(item.id);
        ok(placeID, "Expected each imported Cool Spot to retain a Place");
        return item.mapReferences.map((link) =>
          `${placeID}/${link.provider}/${link.placeID}`
        );
      })
      .sort();
    deepStrictEqual(
      links.map((link) =>
        `${link.place_id}/${link.provider}/${link.external_place_id}`
      ),
      expectedIdentities,
    );
    for (const link of links) {
      deepStrictEqual(Object.keys(link).sort(), [
        "checked_at",
        "external_place_id",
        "place_id",
        "provider",
        "relationship",
        "verification",
      ]);
    }
    strictEqual(
      links.filter((link) => link.verification === "automatic").length,
      136,
    );
    strictEqual(
      links.filter((link) => link.verification === "reviewed").length,
      9,
    );
  });
});

Deno.test("DB-C69: the library map link preserves the accepted same-place identity and original check time", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const spots = await loadCoolSpotRows(sql);
    const library = spots.find((spot) =>
      spot.id === "5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab"
    );
    ok(library, "Expected the library fixture");
    const links = await loadPlaceMapLinkRows(sql);

    deepStrictEqual(
      links.filter((link) => link.place_id === library.place_id),
      [{
        place_id: library.place_id,
        provider: "apple_maps",
        external_place_id: "I7E8561E6022ED614",
        relationship: "same_place",
        // Retained source review is not owner/on-site verification.
        verification: "reviewed",
        checked_at: new Date("2026-09-18T14:33:54Z"),
      }],
    );
  });
});

Deno.test("DB-C70: a containing-venue link preserves the lobby relationship and its own place facts", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const spots = await loadCoolSpotRows(sql);
    const lobby = spots.find((spot) =>
      spot.id === "27eb2d12-9bcc-5d23-bb25-add95d367f01"
    );
    ok(lobby, "Expected the Streatham lobby fixture");
    const links = await loadPlaceMapLinkRows(sql);

    deepStrictEqual(
      links.filter((link) => link.place_id === lobby.place_id),
      [{
        place_id: lobby.place_id,
        provider: "apple_maps",
        external_place_id: "I469799177B7DF2F3",
        relationship: "within_place",
        verification: "reviewed",
        checked_at: new Date("2026-09-19T00:16:05Z"),
      }],
    );
    deepStrictEqual({
      id: lobby.id,
      name: lobby.name,
      latitude: lobby.latitude,
      longitude: lobby.longitude,
    }, {
      id: "27eb2d12-9bcc-5d23-bb25-add95d367f01",
      name: "Streatham Ice Rink lobby",
      latitude: 51.4242620803,
      longitude: -0.1311127576,
    });
  });
});

Deno.test("DB-C71: an unmatched museum remains in the catalogue without an invented map link", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const spots = await loadCoolSpotRows(sql);
    const museum = spots.find((spot) =>
      spot.id === "ba3d7ed3-bfdc-53c6-a5b1-a1b1cde17dac"
    );
    ok(museum, "Expected the unmatched pharmacy museum in the catalogue");
    strictEqual(museum.name, "Museum of the Royal Pharmaceutical Society");
    const links = await loadPlaceMapLinkRows(sql);

    deepStrictEqual(
      links.filter((link) => link.place_id === museum.place_id),
      [],
    );
  });
});

Deno.test("DB-C72: an example map link preserves an unknown check time as null", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const spots = await loadCoolSpotRows(sql);
    const tate = spots.find((spot) =>
      spot.id === "f536167c-f689-4e46-8e2d-9a144ac03b7e"
    );
    ok(tate, "Expected the Tate example fixture");
    const links = await loadPlaceMapLinkRows(sql);

    deepStrictEqual(
      links.filter((link) => link.place_id === tate.place_id),
      [{
        place_id: tate.place_id,
        provider: "apple_maps",
        external_place_id: "I5D0F2F6C33848101",
        relationship: "same_place",
        verification: "reviewed",
        checked_at: null,
      }],
    );
  });
});

Deno.test("DB-C73: photo rows retain all three resource identities and their display order", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const spots = await loadCoolSpotRows(sql);
    const room = spots.find((spot) =>
      spot.id === "bc21d832-6796-46ac-81ac-c96dc242dd18"
    );
    ok(room, "Expected the Example Community Room fixture");
    const photos = await loadPlacePhotoRows(sql);

    deepStrictEqual(
      photos.map((photo) => ({
        id: photo.id,
        place_id: photo.place_id,
        position: photo.position,
      })),
      [
        {
          id: "example-community-photo-1",
          place_id: room.place_id,
          position: 0,
        },
        {
          id: "example-community-photo-2",
          place_id: room.place_id,
          position: 1,
        },
        {
          id: "example-community-photo-3",
          place_id: room.place_id,
          position: 2,
        },
      ],
    );
    for (const photo of photos) {
      deepStrictEqual(Object.keys(photo).sort(), [
        "attribution",
        "caption",
        "captured_at",
        "contribution_id",
        "height",
        "id",
        "image_ref",
        "place_id",
        "position",
        "published_at",
        "source_kind",
        "thumbnail_ref",
        "width",
      ]);
    }
  });
});

Deno.test("DB-C74: photo metadata preserves references, dimensions, caption and attribution", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const spots = await loadCoolSpotRows(sql);
    const room = spots.find((spot) =>
      spot.id === "bc21d832-6796-46ac-81ac-c96dc242dd18"
    );
    ok(room, "Expected the Example Community Room fixture");
    const photos = await loadPlacePhotoRows(sql);

    deepStrictEqual(
      photos.find((photo) => photo.id === "example-community-photo-2"),
      {
        id: "example-community-photo-2",
        place_id: room.place_id,
        thumbnail_ref: "bundle://CommunityPhoto2.jpg",
        image_ref: "bundle://CommunityPhoto2.jpg",
        width: 1448,
        height: 1086,
        caption: "Indoor seating",
        captured_at: null,
        published_at: null,
        attribution: "Illustrative image · Example Community Room",
        source_kind: "illustration",
        contribution_id: null,
        position: 1,
      },
    );
  });
});

Deno.test("DB-C75: all example photos stay illustrative and retain unknown dates and contribution identity", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const photos = await loadPlacePhotoRows(sql);

    deepStrictEqual(
      photos.map((photo) => ({
        id: photo.id,
        source_kind: photo.source_kind,
        captured_at: photo.captured_at,
        published_at: photo.published_at,
        contribution_id: photo.contribution_id,
      })),
      [
        {
          id: "example-community-photo-1",
          source_kind: "illustration",
          captured_at: null,
          published_at: null,
          contribution_id: null,
        },
        {
          id: "example-community-photo-2",
          source_kind: "illustration",
          captured_at: null,
          published_at: null,
          contribution_id: null,
        },
        {
          id: "example-community-photo-3",
          source_kind: "illustration",
          captured_at: null,
          published_at: null,
          contribution_id: null,
        },
      ],
    );
  });
});

Deno.test("DB-C76: a library without published photos remains in the catalogue without an invented photo", async () => {
  await withDatabase(localDatabaseURL(), async (sql) => {
    const spots = await loadCoolSpotRows(sql);
    const library = spots.find((spot) =>
      spot.id === "5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab"
    );
    ok(library, "Expected Canning Town Library in the catalogue");
    strictEqual(library.name, "Canning Town Library");
    const photos = await loadPlacePhotoRows(sql);

    deepStrictEqual(
      photos.filter((photo) => photo.place_id === library.place_id),
      [],
    );
  });
});

// MARK: - Helpers

function coolingValues(row: CoolSpotRow) {
  return {
    setting: row.setting,
    cost: row.cost,
    eligibility: row.eligibility,
    seating: row.seating,
    toilets: row.toilets,
    drinking_water: row.drinking_water,
    wheelchair_access: row.wheelchair_access,
    staffed_when_open: row.staffed_when_open,
    tables: row.tables,
    cooling_features: row.cooling_features,
    cooling_details: row.cooling_details,
    area_description: row.area_description,
    additional_information: row.additional_information,
    hours_text: row.hours_text,
    hours_time_zone: row.hours_time_zone,
    posted_stay_limit_status: row.posted_stay_limit_status,
    posted_stay_limit_minutes: row.posted_stay_limit_minutes,
  };
}

function localDatabaseURL(): string {
  const value = Deno.env.get("COOL_SPOTS_DATABASE_URL");
  if (!value) {
    throw new Error(
      "Load the local backend settings before running this suite.",
    );
  }

  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new Error("Invalid backend URL; its value is withheld.");
  }

  if (
    url.protocol !== "postgresql:" || url.hostname !== "127.0.0.1" ||
    url.port !== "54322" || url.username !== "cool_spots_api" ||
    url.pathname !== "/postgres" || !url.password || url.search || url.hash
  ) {
    throw new Error("This suite requires the dedicated local backend login.");
  }
  return value;
}

async function withDatabase(
  url: string,
  exercise: (sql: ReturnType<typeof createDatabaseClient>) => Promise<void>,
): Promise<void> {
  let sql: ReturnType<typeof createDatabaseClient> | undefined;
  try {
    sql = createDatabaseClient(url);
    await exercise(sql);
  } catch (error) {
    // Assertions contain public fixture values only. Never print driver errors.
    if (error instanceof AssertionError) throw error;
    if (
      error instanceof Error &&
      error.message === "Database connection is not implemented"
    ) {
      throw new Error("Database connection is not implemented");
    }
    throw new Error(
      `Database operation failed (${
        databaseErrorCode(error)
      }); details withheld.`,
    );
  } finally {
    if (sql) {
      try {
        await sql.end({ timeout: 1 });
      } catch {
        throw new Error(
          "Database connection cleanup failed; details withheld.",
        );
      }
    }
  }
}

async function expectDatabaseError(
  action: () => PromiseLike<unknown>,
  expectedCode: string,
): Promise<void> {
  let actualCode = "NO_ERROR";
  try {
    await action();
  } catch (error) {
    actualCode = databaseErrorCode(error);
  }
  strictEqual(actualCode, expectedCode);
}

function databaseErrorCode(error: unknown): string {
  if (typeof error !== "object" || error === null || !("code" in error)) {
    return "UNKNOWN";
  }
  const code = error.code;
  return typeof code === "string" && /^[A-Z0-9_]{5,40}$/.test(code)
    ? code
    : "UNKNOWN";
}
