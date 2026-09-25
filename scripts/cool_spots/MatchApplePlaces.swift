import Foundation
import MapKit

// Offline Cool Spot reconciliation tool. Run serially and checkpoint every lookup.
// Candidate retrieval is not identity approval; build_cool_spots.py makes that decision.
@main struct MatchApplePlaces {
    @MainActor static func main() async throws {
        let args = CommandLine.arguments
        guard args.count >= 3 else { fatalError("Usage: MatchApplePlaces source.geojson results.json [retry] [address audit.json]") }
        let source = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: args[1]))) as! [String: Any]
        let features = source["features"] as! [[String: Any]]
        let outputURL = URL(fileURLWithPath: args[2])
        var rows = (try? JSONSerialization.jsonObject(with: Data(contentsOf: outputURL))) as? [[String: Any]] ?? []
        let retry = args.dropFirst(3).contains("retry")
        let addressMode = args.dropFirst(3).contains("address")
        var requestedIDs: Set<String>?
        if addressMode, let position = args.firstIndex(of: "address"), args.count > position + 1 {
            let audit = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: args[position + 1]))) as! [String: Any]
            let results = (audit["mapping"] as! [String: Any])["results"] as! [[String: Any]]
            requestedIDs = Set(results.filter { $0["status"] as? String != "auto_matched" }.compactMap { $0["sourceRecordID"] as? String })
        }
        let done = Set(rows.filter { !retry || $0["error"] == nil }.compactMap { $0["siteID"] as? String })
        for (index, feature) in features.enumerated() {
            let p = feature["properties"] as! [String: Any]
            let id = String(describing: p["cs_indoor_site_id"]!)
            if done.contains(id) { continue }
            if let requestedIDs, !requestedIDs.contains(id) { continue }
            let coordinates = (feature["geometry"] as! [String: Any])["coordinates"] as! [Double]
            let location = CLLocation(latitude: coordinates[1], longitude: coordinates[0])
            let name = p["cs_name"] as? String ?? ""
            let address = p["cs_address_one"] as? String ?? ""
            let borough = p["cs_borough"] as? String ?? ""
            let query = addressMode ? "\(name) \(address) London" : "\(name) \(borough) London"
            var row: [String: Any] = ["siteID": id, "sourceName": name, "sourceAddress": address,
                "query": query, "queriedAt": ISO8601DateFormatter().string(from: .now)]
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000)
            request.resultTypes = .pointOfInterest
            let search = MKLocalSearch(request: request)
            let timeout = Task { try? await Task.sleep(for: .seconds(25)); if !Task.isCancelled { search.cancel() } }
            do {
                let response = try await search.start()
                timeout.cancel()
                row["candidates"] = response.mapItems.prefix(8).map { item -> [String: Any] in
                    let place = item.placemark
                    return ["placeID": item.identifier?.rawValue ?? "", "name": item.name ?? "",
                        "address": [place.subThoroughfare, place.thoroughfare].compactMap { $0 }.joined(separator: " "),
                        "postalCode": place.postalCode ?? "", "locality": place.locality ?? "",
                        "category": item.pointOfInterestCategory?.rawValue ?? "",
                        "latitude": place.coordinate.latitude, "longitude": place.coordinate.longitude,
                        "distanceMetres": Int(location.distance(from: CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)).rounded())]
                }
            } catch {
                timeout.cancel()
                let error = error as NSError
                row["error"] = ["domain": error.domain, "code": error.code, "message": error.localizedDescription]
                print("Lookup error \(id): \(error.domain) \(error.code)")
                // Back off without retrying the same request in a tight loop.
                if error.domain != MKErrorDomain || error.code != MKError.Code.placemarkNotFound.rawValue {
                    try? await Task.sleep(for: .seconds(10))
                }
            }
            rows.removeAll { $0["siteID"] as? String == id }
            rows.append(row)
            try JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys]).write(to: outputURL, options: .atomic)
            if (index + 1) % 10 == 0 || index == features.count - 1 {
                print("Checked \(rows.count)/\(features.count): \(name)")
                fflush(stdout)
            }
            try await Task.sleep(for: .milliseconds(1100))
        }
    }
}
