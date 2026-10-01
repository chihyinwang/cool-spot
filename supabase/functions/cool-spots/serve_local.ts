import { createDatabaseClient } from "./database.ts";
import { createDatabaseCoolSpotsReader } from "./reader.ts";
import { createCoolSpotsRouter, validateLocalDatabaseURL } from "./server.ts";

async function serveLocal() {
  const url = validateLocalDatabaseURL(Deno.env.get("COOL_SPOTS_DATABASE_URL"));
  const sql = createDatabaseClient(url);
  const controller = new AbortController();
  const stop = () => controller.abort();
  const server = Deno.serve({
    hostname: "127.0.0.1",
    port: 8000,
    signal: controller.signal,
    onListen: () =>
      console.log(
        "Local Cool Spots API: http://127.0.0.1:8000/functions/v1/cool-spots",
      ),
  }, createCoolSpotsRouter(createDatabaseCoolSpotsReader(sql)));
  Deno.addSignalListener("SIGINT", stop);
  Deno.addSignalListener("SIGTERM", stop);
  try {
    await server.finished;
  } finally {
    Deno.removeSignalListener("SIGINT", stop);
    Deno.removeSignalListener("SIGTERM", stop);
    await sql.end({ timeout: 1 });
  }
}

if (import.meta.main) {
  try {
    await serveLocal();
  } catch {
    console.error(
      "Local API could not start or stop; diagnostic details withheld.",
    );
    Deno.exitCode = 1;
  }
}
