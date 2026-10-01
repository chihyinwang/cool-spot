import postgres from "npm:postgres@3.4.9";

export function createDatabaseClient(databaseURL: string): postgres.Sql {
  return postgres(databaseURL, {
    max: 1,
    connect_timeout: 5,
  });
}
