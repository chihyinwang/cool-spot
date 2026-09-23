import Foundation
import MapKit

// Read-only, serial MapKit probe for a bounded set of discovery cases.
// Uses the app's request types and initial Explore region; never approves identity.
@main struct AuditDiscovery {
    @MainActor static func main() async throws {
        let args = CommandLine.arguments
        guard args.count == 3 else { fatalError("Usage: AuditDiscovery cases.json output.json") }
        let document = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: args[1]))) as! [String: Any]
        let cases = document["cases"] as! [[String: Any]]
        let url = URL(fileURLWithPath: args[2])
        var rows = (try? JSONSerialization.jsonObject(with: Data(contentsOf: url))) as? [[String: Any]] ?? []
        for entry in cases {
            let sid = entry["sourceRecordID"] as! String
            let query = entry["query"] as! String
            if rows.contains(where: { $0["siteID"] as? String == sid && $0["query"] as? String == query }) { continue }
            let source = CLLocation(latitude: entry["latitude"] as! Double, longitude: entry["longitude"] as! Double)
            var row: [String: Any] = ["siteID": sid, "query": query,
                "queriedAt": ISO8601DateFormatter().string(from: .now)]
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.resultTypes = [.address, .pointOfInterest]
            request.region = MKCoordinateRegion(center: .init(latitude: 51.5052, longitude: -0.0920),
                span: .init(latitudeDelta: 0.035, longitudeDelta: 0.035))
            let search = MKLocalSearch(request: request)
            let timeout = Task { try? await Task.sleep(for: .seconds(25)); if !Task.isCancelled { search.cancel() } }
            do {
                let response = try await search.start()
                row["candidates"] = response.mapItems.map { snapshot($0, from: source) }
            } catch {
                let error = error as NSError
                row["error"] = ["domain": error.domain, "code": error.code, "message": error.localizedDescription]
            }
            timeout.cancel()
            var resolved: [[String: Any]] = []
            for id in entry["placeIDs"] as? [String] ?? [] {
                guard let identifier = MKMapItem.Identifier(rawValue: id) else { continue }
                let request = MKMapItemRequest(mapItemIdentifier: identifier)
                let timeout = Task { try? await Task.sleep(for: .seconds(25)); if !Task.isCancelled { request.cancel() } }
                do {
                    var result = snapshot(try await request.mapItem, from: source)
                    result["requestedPlaceID"] = id
                    resolved.append(result)
                } catch {
                    let error = error as NSError
                    resolved.append(["requestedPlaceID": id, "error": ["domain": error.domain, "code": error.code]])
                }
                timeout.cancel()
                try await Task.sleep(for: .milliseconds(1100))
            }
            row["resolvedIdentities"] = resolved
            rows.append(row)
            try JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys]).write(to: url, options: .atomic)
            print("Checked \(sid): \(query)"); fflush(stdout)
            try await Task.sleep(for: .milliseconds(1100))
        }
    }

    static func snapshot(_ item: MKMapItem, from source: CLLocation) -> [String: Any] {
        let p = item.placemark
        return ["placeID": item.identifier?.rawValue ?? "", "alternatePlaceIDs": item.alternateIdentifiers.map(\.rawValue),
            "name": item.name ?? "", "address": [p.subThoroughfare, p.thoroughfare].compactMap { $0 }.joined(separator: " "),
            "postalCode": p.postalCode ?? "", "locality": p.locality ?? "", "category": item.pointOfInterestCategory?.rawValue ?? "",
            "latitude": p.coordinate.latitude, "longitude": p.coordinate.longitude,
            "distanceMetres": Int(source.distance(from: CLLocation(latitude: p.coordinate.latitude, longitude: p.coordinate.longitude)).rounded())]
    }
}
