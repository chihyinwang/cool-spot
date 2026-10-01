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

        let address: Address
        let placeType: CoolSpotPlaceType
        let setting: CoolSpotSetting
        let coolingFeatures: [CoolSpotFeature]
        let coolingDetails: String?
        let additionalInformation: String?
        let access: Access
        let hours: Hours?

        let sourceReferences: [SourceReference]
        let provenance: [Provenance]
        let mapReferences: [MapReference]
        let photos: [PlacePhotoAsset]

        struct SourceReference: Decodable, Hashable {
            let sourceID: String
            let recordID: String
        }

        struct Provenance: Decodable, Equatable {
            let sourceID: String
            let recordID: String
            let method: String
            let recordedAt: String?
            let fields: [String]
        }

        struct MapReference: Decodable, Equatable {
            let provider: String
            let placeID: String
            let relationship: String
            let verification: String
            let checkedAt: String?
        }

        struct Address: Decodable, Equatable {
            let formatted: String?
            let line1: String?
            let line2: String?
            let locality: String?
            let borough: String?
            let postalCode: String?
            let countryCode: String?
        }

        struct Access: Decodable, Equatable {
            let cost: CoolSpotCost
            let eligibility: Eligibility
            let seating: CoolSpotSeating
            let toilets: CoolSpotToilets
            let drinkingWater: CoolSpotAvailability
            let wheelchairAccess: CoolSpotAvailability
            let staffedWhenOpen: CoolSpotAvailability
            let tables: CoolSpotAvailability
            let areaDescription: String?
            let postedStayLimit: CoolSpotStayLimit
        }

        enum Eligibility: String, Decodable {
            case everyone, limited, unknown

            init(from decoder: Decoder) throws {
                let code = try decoder.singleValueContainer().decode(String.self)
                self = Self(rawValue: code) ?? .unknown
            }
        }

        struct Hours: Decodable, Equatable {
            let text: String
            let timeZone: String
        }

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

        let sourceIDs = Set(response.sources.map(\.id))

        guard sourceIDs.count == response.sources.count,
              response.sources.allSatisfy({
                  !$0.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              }),
              Set(response.items.map(\.id)).count == response.items.count,
              Set(response.items.map(\.placeID)).count == response.items.count,
              response.items.allSatisfy({ item in
                  let linkedRecords = Set(item.sourceReferences)

                  return !item.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  !item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  CLLocationCoordinate2DIsValid(item.location.coordinate) &&
                  item.access.postedStayLimit.isValid &&
                  item.sourceReferences.allSatisfy({ reference in
                      sourceIDs.contains(reference.sourceID) &&
                      !reference.recordID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                  }) &&
                  item.provenance.allSatisfy({ evidence in
                      linkedRecords.contains(.init(
                          sourceID: evidence.sourceID,
                          recordID: evidence.recordID
                      ))
                  })
              }) else {
            throw LoadError.invalidItems
        }

        return response
    }
}
