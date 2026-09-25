import Foundation
import CoreLocation

// PROTOTYPE: a bundled response exercises the Cool Spots response contract without a server.
// Wire codes are independent of English labels and existing journey storage values.
private protocol CoolSpotCode: RawRepresentable, Codable where RawValue == String {
    static var unknown: Self { get }
}

extension CoolSpotCode {
    init(from decoder: Decoder) throws {
        let code = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: code) ?? .unknown
    }
}

enum CoolSpotAvailability: String, CoolSpotCode {
    case yes, no, unknown
}

enum CoolSpotFeature: String, CoolSpotCode {
    case airConditioning = "air_conditioning"
    case fans
    case ventilation = "natural_ventilation"
    case treeShade = "tree_shade"
    case structuralShade = "structural_shade"
    case coolerIndoors = "cooler_indoors"
    case waterNearby = "water_nearby"
    case unknown

    var feature: CoolingFeature? {
        switch self {
        case .airConditioning: .airConditioning
        case .fans: .fans
        case .ventilation: .ventilation
        case .treeShade: .treeShade
        case .structuralShade: .structuralShade
        case .coolerIndoors: .coolerIndoors
        case .waterNearby: .waterFeature
        case .unknown: nil
        }
    }
}

enum CoolSpotPlaceType: String, CoolSpotCode {
    case library, community, faith, culture, leisure, shop, food, park, square, waterside, transport, other, unknown
    var type: PlaceType {
        switch self {
        case .library: .library
        case .community: .publicService
        case .faith: .faith
        case .culture: .culture
        case .leisure: .leisure
        case .shop: .shop
        case .food: .food
        case .park: .park
        case .square: .square
        case .waterside: .waterside
        case .transport: .transport
        case .other: .other
        case .unknown: .unknown
        }
    }
}

enum CoolSpotSetting: String, CoolSpotCode {
    case indoors, outdoors, both, unknown
    var environment: PlaceEnvironment {
        switch self {
        case .indoors: .indoors
        case .outdoors: .outdoors
        case .both: .both
        case .unknown: .unknown
        }
    }
}

enum CoolSpotCost: String, CoolSpotCode {
    case free, purchaseRequired = "purchase_required", entryFee = "entry_fee", unknown
    var access: AccessType {
        switch self {
        case .free: .free
        case .purchaseRequired: .purchase
        case .entryFee: .entryFee
        case .unknown: .unsure
        }
    }
}

enum CoolSpotToilets: String, CoolSpotCode {
    case onSite = "on_site", nearby, notOnSite = "not_on_site", none, unknown
}

enum CoolSpotSeating: String, CoolSpotCode { case yes, limited, no, unknown }
enum CoolSpotScope: String, CoolSpotCode { case venue, specificArea = "specific_area", unknown }

struct CoolSpotsResponse: Codable {
    static let currentSchemaVersion = 4

    let schemaVersion: Int
    let datasetID: String
    var generatedAt: String? = nil
    var source: Source?
    var sources: [SourceMetadata]?
    var items: [Item]

    struct SourceMetadata: Codable, Equatable {
        var id: String
        var provider: String
        var label: String
        var url: URL?
        var isExample: Bool? = nil
    }

    struct Source: Codable, Equatable {
        var provider: String
        var dataset: String
        var url: URL
        var retrievedOn: String
    }

    struct Item: Codable, Identifiable, Equatable {
        var id: String
        var name: String
        var location: Location
        var address: Address
        var placeType: CoolSpotPlaceType
        var setting: CoolSpotSetting
        var coolingFeatures: [CoolSpotFeature]
        var additionalInformation: String? = nil
        var coolingDetails: String?
        var access: Access
        var hours: Hours?
        var sourceRecord: SourceRecord?
        var appleMatch: AppleMatch?
        var sourceReferences: [SourceReference]?
        var mapReferences: [MapReference]?
        var photos: [PlacePhotoAsset]?
        var provenance: [Provenance]? = nil

        struct SourceReference: Codable, Equatable { var sourceID: String; var recordID: String }
        struct Provenance: Codable, Equatable {
            var sourceID: String
            var method: String
            var fields: [String]
            var recordID: String? = nil
            var recordedAt: String? = nil
        }
        struct MapReference: Codable, Equatable {
            var provider: String
            var placeID: String
            var relationship: String
            var verification: String
            var checkedAt: String? = nil
        }

        struct Location: Codable, Equatable {
            var latitude: Double
            var longitude: Double
            var scope: CoolSpotScope? = nil
            var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
        }
        struct Address: Codable, Equatable {
            var line1: String?
            var formatted: String? = nil
            var line2: String?
            var borough: String?
            var locality: String?
            var countryCode: String?
            var postalCode: String?
            var display: String {
                if let formatted, !formatted.isEmpty { return formatted }
                return [line1, line2, locality, postalCode].compactMap { $0 }
                    .filter { !$0.isEmpty }.joined(separator: ", ")
            }
        }
        struct Access: Codable, Equatable {
            var cost: CoolSpotCost
            var eligibility: String
            var seating: CoolSpotSeating
            var drinkingWater: CoolSpotAvailability
            var toilets: CoolSpotToilets
            var wheelchairAccess: CoolSpotAvailability
            var staffedWhenOpen: CoolSpotAvailability?
            var tables: CoolSpotAvailability?
            var eligibilityDetails: String?
            var instructions: String?
            var postedStayLimitMinutes: Int?
            var areaDescription: String? = nil
            var postedStayLimit: CoolSpotStayLimit? = nil
            var resolvedStayLimit: CoolSpotStayLimit {
                postedStayLimit ?? postedStayLimitMinutes.map { .init(status: .limited, minutes: $0) } ?? .unknown
            }
        }
        struct Hours: Codable, Equatable {
            var text: String
            var timeZone: String
        }
        struct SourceRecord: Codable, Equatable {
            var siteID: String
            var objectID: Int
            var tier: String
            // Preserve the source value; its meaning is not a verified-at timestamp.
            var runtime: String
        }
        struct AppleMatch: Codable, Equatable {
            var placeID: String
            var status: String
            var relationship: String
            var reviewedOn: String
            var evidence: URL?
            var reviewNote: String
        }
        var matchedAppleID: String? {
            if let match = mapReferences?.first(where: {
                $0.provider == "apple_maps" && $0.relationship == "same_place" &&
                ["automatic", "reviewed"].contains($0.verification) && !$0.placeID.isEmpty
            }) { return match.placeID }
            guard let appleMatch, appleMatch.status == "matched",
                  appleMatch.relationship == "same_place", !appleMatch.placeID.isEmpty else { return nil }
            return appleMatch.placeID
        }

        func makeSpot(sourceMetadata: SourceMetadata? = nil, retaining previous: CoolSpot? = nil) -> CoolSpot {
            let sourceKind: SpotSource = switch sourceMetadata?.provider {
            case "gla": .gla
            case "community": .community
            default: sourceRecord == nil ? .unknown : .gla
            }
            var features = coolingFeatures.compactMap(\.feature)
            if access.drinkingWater == .yes { features.append(.drinkingWater) }
            let seating: SeatingType = switch access.seating {
            case .yes: .available
            case .limited: .limited
            case .no: .none
            case .unknown: .unsure
            }
            var spot = CoolSpot(id: id, name: name, address: address.display,
                                latitude: location.latitude, longitude: location.longitude,
                                source: sourceKind, environment: setting.environment, type: placeType.type,
                                features: features, access: access.cost.access, seating: seating,
                                distance: previous?.distance ?? "", presenceCount: previous?.presenceCount ?? 0,
                                experienceReports: previous?.experienceReports ?? [:],
                                latestReportAt: previous?.latestReportAt ?? .distantPast,
                                stayReports: previous?.stayReports ?? [:], comments: previous?.comments ?? [],
                                isNearby: previous?.isNearby ?? false)
            spot.entryEligibility = access.eligibility == "everyone" ? .everyone
                : access.eligibility == "limited" ? .limited : .unknown
            spot.applePlaceID = matchedAppleID
            spot.photos = (photos ?? []).filter(\.isDisplayable)
            spot.entryRequirement = access.eligibilityDetails ?? ""
            var sourceLabel = sourceMetadata?.label ?? (sourceKind == .gla ? "GLA · 2025" : sourceKind.rawValue)
            if sourceKind == .gla, provenance?.contains(where: { $0.sourceID == PrototypePublication.source.id }) == true,
               !sourceLabel.hasSuffix(" · Local edits") {
                sourceLabel += " · Local edits"
            }
            spot.information = PlaceInformation(
                source: .init(label: sourceLabel,
                              url: sourceMetadata?.url, isExample: sourceMetadata?.isExample ?? false),
                coolingDetails: coolingDetails, hours: hours?.text,
                toilets: .init(rawValue: access.toilets.rawValue) ?? .unknown,
                wheelchairAccessible: access.wheelchairAccess == .unknown ? nil : access.wheelchairAccess == .yes,
                staffedWhenOpen: access.staffedWhenOpen == .yes ? true : access.staffedWhenOpen == .no ? false : nil,
                tables: access.tables == .yes ? true : access.tables == .no ? false : nil,
                areaDescription: access.areaDescription ?? access.instructions,
                postedStayLimit: access.resolvedStayLimit, additionalInformation: additionalInformation,
                drinkingWater: access.drinkingWater == .unknown ? nil : access.drinkingWater == .yes)
            spot.publishedRecord = self
            return spot
        }
    }

    enum LoadError: Error { case unsupportedVersion, invalidItems }

    static func decode(_ data: Data) throws -> Self {
        let response = try JSONDecoder().decode(Self.self, from: data)
        guard [1, 2, 3, currentSchemaVersion].contains(response.schemaVersion) else { throw LoadError.unsupportedVersion }
        guard Set(response.items.map(\.id)).count == response.items.count,
              response.items.allSatisfy({ !$0.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  CLLocationCoordinate2DIsValid($0.location.coordinate) &&
                  $0.access.resolvedStayLimit.isValid
              }) else { throw LoadError.invalidItems }
        return response
    }

    static func bundled(named name: String = "CoolSpots.prototype") throws -> Self {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try decode(Data(contentsOf: url))
    }
}

extension CoolSpotsResponse {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion, datasetID, generatedAt, source, sources, items
        // The old wire key is retained only for reading/writing legacy versions.
        case legacyDatasetID = "catalogID"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        if schemaVersion < Self.currentSchemaVersion {
            datasetID = try values.decodeIfPresent(String.self, forKey: .datasetID)
                ?? values.decode(String.self, forKey: .legacyDatasetID)
        } else {
            datasetID = try values.decode(String.self, forKey: .datasetID)
        }
        generatedAt = try values.decodeIfPresent(String.self, forKey: .generatedAt)
        source = try values.decodeIfPresent(Source.self, forKey: .source)
        sources = try values.decodeIfPresent([SourceMetadata].self, forKey: .sources)
        items = try values.decode([Item].self, forKey: .items)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schemaVersion, forKey: .schemaVersion)
        try values.encode(datasetID, forKey: schemaVersion < Self.currentSchemaVersion ? .legacyDatasetID : .datasetID)
        try values.encodeIfPresent(generatedAt, forKey: .generatedAt)
        try values.encodeIfPresent(source, forKey: .source)
        try values.encodeIfPresent(sources, forKey: .sources)
        try values.encode(items, forKey: .items)
    }
}

@MainActor
extension PrototypeStore {
    static func loadedCoolSpotsStore(reportDefaults: UserDefaults?) -> PrototypeStore {
        do {
            let response = try CoolSpotsResponse.bundled()
            let imported = response.items.map { item in
                let source = response.sources?.first { $0.id == item.sourceReferences?.first?.sourceID }
                return item.makeSpot(sourceMetadata: source)
            }
            let store = PrototypeStore(reportDefaults: reportDefaults,
                                       loadedCoolSpots: imported + (try PrototypeComparisonPlaces.loadSpots()))
            // Keep the ordinary-place case searchable without waiting for a network result.
            // Existing saved metadata takes precedence over this comparison seed.
            if store.place(PrototypeComparisonPlaces.ordinaryPlace.id) == nil {
                store.remember(PrototypeComparisonPlaces.ordinaryPlace)
            }
            return store
        } catch {
            let store = PrototypeStore(reportDefaults: reportDefaults, loadedCoolSpots: [])
            store.coolSpotsLoadError = "Cool Spots couldn’t load."
            return store
        }
    }
}

// PROTOTYPE: explicitly illustrative community facts and visit reports.
// Only Tate Modern has a real map identity; the other two places are fictional.
// These fixtures never overwrite the ten GLA source records or personal reports.
enum PrototypeComparisonPlaces {
    private static let tateID = "f536167c-f689-4e46-8e2d-9a144ac03b7e"
    private static let roomID = "bc21d832-6796-46ac-81ac-c96dc242dd18"
    private static let gardenID = "23e2f374-3e18-445c-8f2a-db3fb7a8c130"

    static var communitySpots: [CoolSpot] { (try? loadSpots()) ?? [] }
    static var communitySpot: CoolSpot { communitySpots.first { $0.id == tateID }! }

    static func loadSpots() throws -> [CoolSpot] {
        let response = try CoolSpotsResponse.bundled(named: "CommunityCoolSpots.prototype")
        return response.items.map { item in
            let source = response.sources?.first { $0.id == item.sourceReferences?.first?.sourceID }
            var spot = item.makeSpot(sourceMetadata: source)
            let reports = visitorReports.compactMap(\.report).filter { $0.spotID == item.id }
            spot.experienceReports = reports.reduce(into: [:]) { $0[$1.experience, default: 0] += 1 }
            spot.stayReports = reports.reduce(into: [:]) { counts, report in
                if let stay = report.stayLength { counts[stay, default: 0] += 1 }
            }
            spot.latestReportAt = reports.map(\.visitedAt).max() ?? .distantPast
            spot.comments = reports.map(\.comment).filter { !$0.isEmpty }
            spot.presenceCount = item.id == roomID ? 2 : item.id == gardenID ? 1 : 0
            return spot
        }
    }

    // Stable dates and IDs: reopening the app never creates a new visit or count.
    static let visitorReports: [VisitorReportItem] = [
        report(1, spot: tateID, at: "2026-09-17T14:00:00Z", experience: .muchCooler,
               helped: [.coolerIndoors], stay: .under60, comment: "A comfortable break indoors. I found somewhere to sit."),
        report(2, spot: tateID, at: "2026-09-16T12:30:00Z", experience: .aLittleCooler,
               helped: [.coolerIndoors], stay: .under30, comment: "Cooler than the street, but still quite busy."),
        report(3, spot: tateID, at: "2026-09-15T13:00:00Z", experience: .muchCooler,
               helped: [.coolerIndoors], stay: .under60, comment: "Stayed for a short rest before walking home."),
        report(4, spot: roomID, at: "2026-09-17T15:00:00Z", experience: .aLittleCooler,
               helped: [.fans, .drinkingWater], stay: .under30, comment: "The fan helped. There were tables, but no toilet."),
        report(5, spot: roomID, at: "2026-09-16T14:00:00Z", experience: .notCooler,
               helped: [], stay: .under15, comment: "It still felt warm when I visited in the afternoon."),
        report(6, spot: gardenID, at: "2026-09-17T11:00:00Z", experience: .aLittleCooler,
               helped: [.treeShade], stay: .under30, comment: "The shaded bench was a useful place to pause."),
        report(7, spot: gardenID, at: "2026-09-16T16:00:00Z", experience: .muchCooler,
               helped: [.treeShade], stay: .under60, comment: "A breeze through the trees made this feel cooler.")
    ]

    private static func report(_ number: Int, spot: String, at time: String, experience: CoolingExperience,
                               helped: Set<CoolingFeature>, stay: StayLength?, comment: String) -> VisitorReportItem {
        let date = ISO8601DateFormatter().date(from: time)!
        let id = UUID(uuidString: String(format: "A87F3AE8-EC50-4BED-8A35-%012d", number))!
        let report = VisitReport(id: id, spotID: spot, experience: experience, helpedFeatures: helped,
                                 stayLength: stay, comment: comment, visitedAt: date,
                                 confirmationAt: date, submittedAt: date.addingTimeInterval(1800))
        return .init(id: "example-community-\(number)", comment: comment, report: report, provenance: .example)
    }

    // MapKit identity checked on 2026-09-18; no cooling claims are attached.
    static let ordinaryPlace = RecognisedPlace(
        id: "apple-maps:IC97C731EC7408E3D", name: "The British Museum",
        address: "Great Russell Street, London WC1B 3DE",
        latitude: 51.5194502, longitude: -0.1269867,
        type: .culture, distance: "", sourceCategory: "Museum",
        alternateApplePlaceIDs: ["I4E20718257688514"])
}
