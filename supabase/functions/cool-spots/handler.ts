export function createListCoolSpotsHandler(
  reader: { load(): Promise<unknown> },
) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "GET") {
      return Response.json(
        { error: { code: "method_not_allowed" } },
        { status: 405, headers: { Allow: "GET" } },
      );
    }

    try {
      const coolSpotsResponse = await reader.load();
      return Response.json(coolSpotsResponse, { status: 200 });
    } catch {
      return Response.json(
        { error: { code: "cool_spots_load_failed" } },
        { status: 500 },
      );
    }
  };
}
