import {
  AssertionError,
  deepStrictEqual,
  notStrictEqual,
  ok,
  strictEqual,
} from "node:assert";
import { createDatabaseClient } from "./database.ts";
import { createDatabaseCoolSpotsReader } from "./reader.ts";
import { createListCoolSpotsHandler } from "./handler.ts";

Deno.test("DB-C77: the database response reader assembles all current identities, public sources, evidence, maps and photos", async () => {
  await withDatabase(databaseURL(), async (sql) => {
    const response = await createDatabaseCoolSpotsReader(
      sql,
      () => new Date("2026-10-01T11:34:56Z"),
    ).load();
    verifyCatalogue(response);
    strictEqual(response.generatedAt, "2026-10-01T11:34:56.000Z");
  });
});

Deno.test("DB-C78: each database load uses its supplied response time without replacing unknown source dates", async () => {
  await withDatabase(databaseURL(), async (sql) => {
    let calls = 0;
    const reader = createDatabaseCoolSpotsReader(
      sql,
      () => new Date(`2026-10-01T11:34:${++calls === 1 ? "56" : "57"}Z`),
    );
    strictEqual(calls, 0);
    const first = await reader.load();
    const second = await reader.load();
    notStrictEqual(first.generatedAt, second.generatedAt);
    deepStrictEqual(second.sources, first.sources);
    deepStrictEqual(second.items, first.items);
    strictEqual(calls, 2);
    ok(
      second.sources.every((source) =>
        source.retrievedAt === null && source.sourceUpdatedAt === null
      ),
    );
  });
});

Deno.test("API-C06: anonymous HTTP GET returns the complete database-backed v5 catalogue", async () => {
  await withDatabase(databaseURL(), async (sql) => {
    const handler = createListCoolSpotsHandler(
      createDatabaseCoolSpotsReader(sql),
    );
    await withServer(handler, async (url) => {
      const before = Date.now();
      const response = await fetch(url);
      strictEqual(response.status, 200);
      strictEqual(
        response.headers.get("content-type")?.split(";")[0],
        "application/json",
      );
      const body = await response.json();
      verifyCatalogue(body);
      const generated = Date.parse(body.generatedAt);
      ok(generated >= before && generated <= Date.now());
    });
  });
});

Deno.test("API-C07: failed database authentication returns a generic HTTP 500 without diagnostics", async () => {
  const url = new URL(databaseURL());
  url.password = `intentionally-invalid-${crypto.randomUUID()}`;
  await withDatabase(url.toString(), async (sql) => {
    const handler = createListCoolSpotsHandler(
      createDatabaseCoolSpotsReader(sql),
    );
    await withServer(handler, async (endpoint) => {
      const response = await fetch(endpoint);
      strictEqual(response.status, 500);
      deepStrictEqual(await response.json(), {
        error: { code: "cool_spots_load_failed" },
      });
    });
  });
});

Deno.test("API-C08: HTTP write methods return 405 without calling the reader", async () => {
  let calls = 0;
  const handler = createListCoolSpotsHandler({
    load: async () => {
      calls++;
      throw new Error("Reader must not run");
    },
  });
  await withServer(handler, async (url) => {
    for (const method of ["POST", "PUT", "PATCH", "DELETE"]) {
      const response = await fetch(url, { method });
      strictEqual(response.status, 405);
      strictEqual(response.headers.get("allow"), "GET");
      deepStrictEqual(await response.json(), {
        error: { code: "method_not_allowed" },
      });
    }
  });
  strictEqual(calls, 0);
});

type Catalogue = Awaited<
  ReturnType<ReturnType<typeof createDatabaseCoolSpotsReader>["load"]>
>;

function verifyCatalogue(response: Catalogue) {
  strictEqual(response.schemaVersion, 5);
  strictEqual(response.datasetID, "cool-spot-prototype");
  strictEqual(response.items.length, 253);
  strictEqual(new Set(response.items.map((item) => item.id)).size, 253);
  strictEqual(new Set(response.items.map((item) => item.placeID)).size, 253);
  strictEqual(response.sources.length, 2);
  deepStrictEqual(
    response.sources.map((
      source,
    ) => [
      source.id,
      source.label,
      source.isExample,
      source.retrievedAt,
      source.sourceUpdatedAt,
    ]),
    [
      ["gla-cool-spaces-2025", "GLA · 2025", false, null, null],
      [
        "prototype-community-examples",
        "Example cooling info",
        true,
        null,
        null,
      ],
    ],
  );
  strictEqual(
    response.items.filter((item) =>
      item.sourceReferences.some((link) =>
        link.sourceID === "gla-cool-spaces-2025"
      )
    ).length,
    250,
  );
  strictEqual(
    response.items.filter((item) =>
      item.sourceReferences.some((link) =>
        link.sourceID === "prototype-community-examples"
      )
    ).length,
    3,
  );
  strictEqual(
    response.items.flatMap((item) =>
      item.provenance.flatMap((entry) => entry.fields)
    ).length,
    5297,
  );
  strictEqual(response.items.flatMap((item) => item.mapReferences).length, 145);
  strictEqual(response.items.flatMap((item) => item.photos).length, 3);
  const library = response.items.find((item) =>
    item.id === "5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab"
  );
  ok(library);
  notStrictEqual(library.id, library.placeID);
  strictEqual(library.name, "Canning Town Library");
  deepStrictEqual(library.location, {
    latitude: 51.516829995,
    longitude: 0.010439996,
  });
  deepStrictEqual(library.sourceReferences, [{
    sourceID: "gla-cool-spaces-2025",
    recordID: "18",
  }]);
  deepStrictEqual(library.photos, []);
  ok(
    library.provenance.some((entry) =>
      entry.method === "inferred_from_context" &&
      entry.fields.includes("/hours/timeZone")
    ),
  );
  const lobby = response.items.find((item) =>
    item.id === "27eb2d12-9bcc-5d23-bb25-add95d367f01"
  );
  ok(lobby);
  strictEqual(lobby.mapReferences[0].relationship, "within_place");
  const photos = response.items.flatMap((item) => item.photos);
  ok(
    photos.every((photo) =>
      photo.source === "illustration" && photo.capturedAt === null &&
      photo.publishedAt === null && photo.contributionID === null
    ),
  );
  for (const item of response.items) {
    ok(!("scope" in item.location));
    ok(!("eligibilityDetails" in item.access));
    deepStrictEqual(Object.keys(item).sort(), [
      "access",
      "additionalInformation",
      "address",
      "coolingDetails",
      "coolingFeatures",
      "hours",
      "id",
      "location",
      "mapReferences",
      "name",
      "photos",
      "placeID",
      "placeType",
      "provenance",
      "setting",
      "sourceReferences",
    ]);
    for (const entry of item.provenance) {
      ok(
        item.sourceReferences.some((link) =>
          link.sourceID === entry.sourceID && link.recordID === entry.recordID
        ),
      );
      ok(
        entry.fields.every((pointer) =>
          !pointer.includes("scope") && !pointer.includes("eligibilityDetails")
        ),
      );
    }
  }
}

async function withServer(
  handler: (request: Request) => Promise<Response>,
  exercise: (url: string) => Promise<void>,
) {
  const server = Deno.serve({
    hostname: "127.0.0.1",
    port: 0,
    onListen: () => {},
  }, handler);
  try {
    await exercise(
      `http://127.0.0.1:${server.addr.port}/functions/v1/cool-spots`,
    );
  } finally {
    await server.shutdown();
  }
}

function databaseURL() {
  const value = Deno.env.get("COOL_SPOTS_DATABASE_URL");
  if (!value) {
    throw new Error(
      "Load the local backend settings before running this suite",
    );
  }
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new Error("Invalid backend URL; value withheld");
  }
  if (
    url.protocol !== "postgresql:" || url.hostname !== "127.0.0.1" ||
    url.port !== "54322" || url.username !== "cool_spots_api" ||
    url.pathname !== "/postgres" || !url.password || url.search || url.hash
  ) {
    throw new Error("This suite requires the dedicated local backend login");
  }
  return value;
}

async function withDatabase(
  url: string,
  exercise: (sql: ReturnType<typeof createDatabaseClient>) => Promise<void>,
) {
  const sql = createDatabaseClient(url);
  try {
    await exercise(sql);
  } catch (error) {
    if (error instanceof AssertionError) throw error;
    if (
      error instanceof Error &&
      error.message === "Database response reader is not implemented"
    ) throw new Error(error.message);
    throw new Error("Backend integration failed; details withheld");
  } finally {
    try {
      await sql.end({ timeout: 1 });
    } catch {
      throw new Error("Database cleanup failed; details withheld");
    }
  }
}
