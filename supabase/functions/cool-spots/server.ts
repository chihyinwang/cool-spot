import { createListCoolSpotsHandler } from "./handler.ts";

export function createCoolSpotsRouter(reader: { load(): Promise<unknown> }) {
  const list = createListCoolSpotsHandler(reader);
  return async (request: Request): Promise<Response> => {
    if (new URL(request.url).pathname !== "/functions/v1/cool-spots") {
      return Response.json({ error: { code: "not_found" } }, { status: 404 });
    }
    return await list(request);
  };
}

export function validateLocalDatabaseURL(value: string | undefined): string {
  if (!value) throw new Error("Local backend settings are missing");
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new Error("Local API requires the dedicated loopback backend login");
  }
  if (
    url.protocol !== "postgresql:" || url.hostname !== "127.0.0.1" ||
    url.port !== "54322" || url.username !== "cool_spots_api" ||
    url.pathname !== "/postgres" || !url.password || url.search || url.hash
  ) {
    throw new Error("Local API requires the dedicated loopback backend login");
  }
  return value;
}
