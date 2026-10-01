import Foundation
import CoreLocation

struct CoolSpotsAPIResponse: Decodable {
    let schemaVersion: Int
    let datasetID: String
    let generatedAt: String
    let sources: [Source]
    let items: [Item]

    struct Source: Decodable, Equatable {
        let id: String
        let provider: String
        let label: String
        let dataset: String?
        let url: URL?
        let downloadURL: URL?
        let retrievedAt: String?
        let sourceUpdatedAt: String?
        let sha256: String?
        let isExample: Bool
    }

    struct Item: Decodable, Equatable {
        let id: String
        let placeID: UUID
        let name: String
        let location: Location

        struct Location: Decodable, Equatable {
            let latitude: Double
            let longitude: Double
            var coordinate: CLLocationCoordinate2D {
                .init(latitude: latitude, longitude: longitude)
            }
        }
    }

    enum LoadError: Error, Equatable {
        case unsupportedVersion
        case invalidItems
    }

    static func decode(_ data: Data) throws -> Self {
        let response = try JSONDecoder().decode(Self.self, from: data)

        guard response.schemaVersion == 5 else {
            throw LoadError.unsupportedVersion
        }

        guard Set(response.items.map(\.id)).count == response.items.count,
              Set(response.items.map(\.placeID)).count == response.items.count,
              response.items.allSatisfy({ item in
                  !item.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  !item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  CLLocationCoordinate2DIsValid(item.location.coordinate)
              }) else {
            throw LoadError.invalidItems
        }

        return response
    }
}
