import { deepStrictEqual, strictEqual, throws } from "node:assert";
import { createCoolSpotsRouter, validateLocalDatabaseURL } from "./server.ts";

Deno.test("API-C09: unknown routes return 404 without reading the catalogue", async () => {
  let calls = 0;
  const router = createCoolSpotsRouter({
    load: async () => {
      calls++;
      return {};
    },
  });
  const response = await router(new Request("http://127.0.0.1:8000/other"));
  strictEqual(response.status, 404);
  deepStrictEqual(await response.json(), { error: { code: "not_found" } });
  strictEqual(calls, 0);
});

Deno.test("API-C10: the local function route forwards a v5 read response", async () => {
  const body = {
    schemaVersion: 5,
    datasetID: "test",
    generatedAt: "2026-10-01T11:34:56.000Z",
    sources: [],
    items: [],
  };
  const router = createCoolSpotsRouter({ load: async () => body });
  const response = await router(
    new Request("http://127.0.0.1:8000/functions/v1/cool-spots"),
  );
  strictEqual(response.status, 200);
  deepStrictEqual(await response.json(), body);
});

Deno.test("API-C11: local configuration accepts only the dedicated loopback login and withholds invalid values", () => {
  const valid =
    "postgresql://cool_spots_api:TEST_ONLY@127.0.0.1:54322/postgres";
  strictEqual(validateLocalDatabaseURL(valid), valid);
  for (
    const invalid of [
      undefined,
      "invalid",
      valid.replace("127.0.0.1", "cloud.example.com"),
      valid.replace("cool_spots_api", "postgres"),
      valid.replace("54322", "5432"),
      `${valid}?sslmode=require`,
      `${valid}#fragment`,
      valid.replace(":TEST_ONLY", ""),
    ]
  ) {
    throws(
      () => validateLocalDatabaseURL(invalid),
      /^Error: Local backend settings are missing$|^Error: Local API requires the dedicated loopback backend login$/,
    );
  }
});
