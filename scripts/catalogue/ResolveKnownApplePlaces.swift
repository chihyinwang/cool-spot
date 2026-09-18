import Foundation
import MapKit

// Re-resolve previously reviewed identities; a stored ID alone is not approval.
@main struct ResolveKnownApplePlaces {
    @MainActor static func main() async throws {
        let args = CommandLine.arguments
        guard args.count == 3 else { fatalError("Usage: ResolveKnownApplePlaces previous-identities.json results.json") }
        let rows = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: args[1]))) as! [[String: Any]]
        var output: [[String: Any]] = []
        for row in rows {
            let rawID = row["placeID"] as! String
            let coordinate = CLLocation(latitude: row["latitude"] as! Double, longitude: row["longitude"] as! Double)
            let request = MKMapItemRequest(mapItemIdentifier: MKMapItem.Identifier(rawValue: rawID)!)
            var result: [String: Any] = ["siteID": row["siteID"]!, "query": "Place ID: \(rawID)",
                "queriedAt": ISO8601DateFormatter().string(from: .now)]
            let timeout = Task { try? await Task.sleep(for: .seconds(25)); if !Task.isCancelled { request.cancel() } }
            do {
                let item = try await request.mapItem
                let p = item.placemark
                result["candidates"] = [["placeID": item.identifier?.rawValue ?? rawID, "name": item.name ?? "",
                    "address": [p.subThoroughfare, p.thoroughfare].compactMap { $0 }.joined(separator: " "),
                    "postalCode": p.postalCode ?? "", "locality": p.locality ?? "", "category": item.pointOfInterestCategory?.rawValue ?? "",
                    "latitude": p.coordinate.latitude, "longitude": p.coordinate.longitude,
                    "distanceMetres": Int(coordinate.distance(from: CLLocation(latitude: p.coordinate.latitude, longitude: p.coordinate.longitude)).rounded())]]
            } catch {
                let error = error as NSError
                result["error"] = ["domain": error.domain, "code": error.code, "message": error.localizedDescription]
            }
            timeout.cancel()
            output.append(result)
            try JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: args[2]), options: .atomic)
            try await Task.sleep(for: .milliseconds(1100))
        }
    }
}
