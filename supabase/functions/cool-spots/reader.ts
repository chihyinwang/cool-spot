import type postgres from "npm:postgres@3.4.9";
import { assembleCoolSpotsResponse } from "./response.ts";
import {
  loadCoolSpotRows,
  loadDataSourceRows,
  loadFieldInferenceRecordRows,
  loadPlaceMapLinkRows,
  loadPlacePhotoRows,
  loadPlaceSourceLinks,
} from "./database_reader.ts";

export function createDatabaseCoolSpotsReader(
  sql: postgres.Sql,
  now: () => Date = () => new Date(),
): { load(): Promise<ReturnType<typeof assembleCoolSpotsResponse>> } {
  return {
    load: async () => {
      const snapshot = await sql.begin(
        "isolation level repeatable read read only",
        async (transaction) => {
          const rows = await loadCoolSpotRows(transaction);
          const sources = await loadDataSourceRows(transaction);
          const sourceLinks = await loadPlaceSourceLinks(transaction);
          const inferenceRecords = await loadFieldInferenceRecordRows(
            transaction,
          );
          const mapLinks = await loadPlaceMapLinkRows(transaction);
          const photos = await loadPlacePhotoRows(transaction);
          return {
            rows,
            relations: {
              sources,
              sourceLinks,
              inferenceRecords,
              mapLinks,
              photos,
            },
          };
        },
      );
      return assembleCoolSpotsResponse(
        snapshot.rows,
        now(),
        snapshot.relations,
      );
    },
  };
}
