import { deepStrictEqual, ok, strictEqual } from "node:assert";
import { createListCoolSpotsHandler } from "./handler.ts";
import communityCoolSpotsResponse from "../../../cool-spot/Resources/CommunityCoolSpots.prototype.json" with {
  type: "json",
};

Deno.test("GET returns an empty v4 Cool Spots response when no Cool Spots exist", async () => {
  const coolSpotsResponse = {
    schemaVersion: 4,
    datasetID: "test-cool-spots",
    generatedAt: "2026-09-23T00:00:00Z",
    sources: [],
    items: [],
  };
  const reader = { load: async () => coolSpotsResponse };
  const handler = createListCoolSpotsHandler(reader);

  const response = await handler(
    new Request("https://example.com/functions/v1/cool-spots"),
  );

  strictEqual(response.status, 200);
  strictEqual(
    response.headers.get("content-type")?.split(";")[0],
    "application/json",
  );
  deepStrictEqual(await response.json(), coolSpotsResponse);
});

Deno.test("GET preserves the complete v4 Cool Spots response when Cool Spots exist", async () => {
  const coolSpotsResponse = communityCoolSpotsResponse;
  ok(
    coolSpotsResponse.items.length > 0,
    "This test requires a nonempty Cool Spots response",
  );
  const reader = { load: async () => structuredClone(coolSpotsResponse) };
  const handler = createListCoolSpotsHandler(reader);

  const response = await handler(
    new Request("https://example.com/functions/v1/cool-spots"),
  );

  strictEqual(response.status, 200);
  strictEqual(
    response.headers.get("content-type")?.split(";")[0],
    "application/json",
  );
  deepStrictEqual(await response.json(), coolSpotsResponse);
});

Deno.test("GET returns a generic JSON error when loading Cool Spots fails", async () => {
  const reader = {
    load: async () => {
      throw new Error("Database connection failed: internal diagnostic");
    },
  };
  const handler = createListCoolSpotsHandler(reader);

  const response = await handler(
    new Request("https://example.com/functions/v1/cool-spots"),
  );

  strictEqual(response.status, 500);
  strictEqual(
    response.headers.get("content-type")?.split(";")[0],
    "application/json",
  );
  deepStrictEqual(await response.json(), {
    error: { code: "cool_spots_load_failed" },
  });
});

for (const method of ["POST", "PUT", "PATCH", "DELETE"]) {
  Deno.test(`${method} is rejected without loading the Cool Spots response`, async () => {
    let loadCallCount = 0;
    const reader = {
      load: async () => {
        loadCallCount += 1;
        return structuredClone(communityCoolSpotsResponse);
      },
    };
    const handler = createListCoolSpotsHandler(reader);

    const response = await handler(
      new Request("https://example.com/functions/v1/cool-spots", { method }),
    );

    strictEqual(response.status, 405);
    strictEqual(response.headers.get("allow"), "GET");
    strictEqual(
      response.headers.get("content-type")?.split(";")[0],
      "application/json",
    );
    deepStrictEqual(await response.json(), {
      error: { code: "method_not_allowed" },
    });
    strictEqual(loadCallCount, 0);
  });
}
