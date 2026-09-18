import Foundation
import CoreLocation

// PROTOTYPE: a bundled response exercises the catalogue contract without a server.
// Wire codes are independent of English labels and existing journey storage values.
private protocol CatalogCode: RawRepresentable, Decodable where RawValue == String {
    static var unknown: Self { get }
}

extension CatalogCode {
    init(from decoder: Decoder) throws {
        let code = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: code) ?? .unknown
    }
}

enum CatalogAvailability: String, CatalogCode {
    case yes, no, unknown
}

enum CatalogFeature: String, CatalogCode {
    case airConditioning = "air_conditioning"
    case fans
    case ventilation = "natural_ventilation"
    case treeShade = "tree_shade"
    case structuralShade = "structural_shade"
    case coolerIndoors = "cooler_indoors"
    case unknown

    var feature: CoolingFeature? {
        switch self {
        case .airConditioning: .airConditioning
        case .fans: .fans
        case .ventilation: .ventilation
        case .treeShade: .treeShade
        case .structuralShade: .structuralShade
        case .coolerIndoors: .coolerIndoors
        case .unknown: nil
        }
    }
}

enum CatalogPlaceType: String, CatalogCode {
    case library, community, faith, culture, leisure, shop, food, park, square, waterside, transport, unknown
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
        case .unknown: .other
        }
    }
}

enum CatalogSetting: String, CatalogCode {
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

enum CatalogCost: String, CatalogCode {
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

enum CatalogToilets: String, CatalogCode {
    case onSite = "on_site", nearby, none, unknown
}

struct PrototypeCatalog: Decodable {
    let schemaVersion: Int
    let catalogID: String
    let source: Source?
    let sources: [CatalogueSource]?
    let items: [Item]

    struct CatalogueSource: Decodable {
        let id: String
        let provider: String
        let label: String
        let url: URL?
    }

    struct Source: Decodable {
        let provider: String
        let dataset: String
        let url: URL
        let retrievedOn: String
    }

    struct Item: Decodable, Identifiable {
        let id: String
        let name: String
        let location: Location
        let address: Address
        let placeType: CatalogPlaceType
        let setting: CatalogSetting
        let coolingFeatures: [CatalogFeature]
        let coolingDetails: String?
        let access: Access
        let hours: Hours?
        let sourceRecord: SourceRecord?
        let appleMatch: AppleMatch?
        let sourceReferences: [SourceReference]?
        let mapReferences: [MapReference]?
        let photos: [PlacePhotoAsset]?

        struct SourceReference: Decodable { let sourceID: String; let recordID: String }
        struct MapReference: Decodable {
            let provider: String
            let placeID: String
            let relationship: String
            let verification: String
        }

        struct Location: Decodable {
            let latitude: Double
            let longitude: Double
            var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
        }
        struct Address: Decodable {
            let line1: String
            let line2: String?
            let borough: String?
            let locality: String?
            let countryCode: String?
            let postalCode: String?
            var display: String {
                [line1, line2, locality ?? "London", postalCode].compactMap { $0 }
                    .filter { !$0.isEmpty }.joined(separator: ", ")
            }
        }
        struct Access: Decodable {
            let cost: CatalogCost
            let eligibility: String
            let seating: CatalogAvailability
            let drinkingWater: CatalogAvailability
            let toilets: CatalogToilets
            let wheelchairAccess: CatalogAvailability
            let staffedWhenOpen: CatalogAvailability?
            let tables: CatalogAvailability?
            let eligibilityDetails: String?
            let instructions: String?
            let postedStayLimitMinutes: Int?
        }
        struct Hours: Decodable {
            let text: String
            let timeZone: String
        }
        struct SourceRecord: Decodable {
            let siteID: String
            let objectID: Int
            let tier: String
            // Preserve the source value; its meaning is not a verified-at timestamp.
            let runtime: String
        }
        struct AppleMatch: Decodable {
            let placeID: String
            let status: String
            let relationship: String
            let reviewedOn: String
            let evidence: URL?
            let reviewNote: String
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

        func makeSpot(catalogueSource: CatalogueSource? = nil) -> CoolSpot {
            let sourceKind: SpotSource = switch catalogueSource?.provider {
            case "gla": .gla
            case "community": .community
            default: sourceRecord == nil ? .unknown : .gla
            }
            var features = coolingFeatures.compactMap(\.feature)
            if access.drinkingWater == .yes { features.append(.drinkingWater) }
            let seating: SeatingType = switch access.seating {
            case .yes: .available
            case .no: .none
            case .unknown: .unsure
            }
            var spot = CoolSpot(id: id, name: name, address: address.display,
                                latitude: location.latitude, longitude: location.longitude,
                                source: sourceKind, environment: setting.environment, type: placeType.type,
                                features: features, access: access.cost.access, seating: seating,
                                distance: "", presenceCount: 0, experienceReports: [:],
                                latestReportAt: .distantPast, stayReports: [:], comments: [], isNearby: false)
            spot.entryEligibility = access.eligibility == "everyone" ? .everyone
                : access.eligibility == "limited" ? .limited : .unknown
            spot.applePlaceID = matchedAppleID
            spot.photos = (photos ?? []).filter(\.isDisplayable)
            spot.entryRequirement = access.eligibilityDetails ?? ""
            spot.information = PlaceInformation(
                source: .init(label: catalogueSource?.label ?? (sourceKind == .gla ? "GLA · 2025" : sourceKind.rawValue),
                              url: catalogueSource?.url),
                coolingDetails: coolingDetails, hours: hours?.text,
                toilets: .init(rawValue: access.toilets.rawValue) ?? .unknown,
                wheelchairAccessible: access.wheelchairAccess == .unknown ? nil : access.wheelchairAccess == .yes,
                staffedWhenOpen: access.staffedWhenOpen == .yes ? true : access.staffedWhenOpen == .no ? false : nil,
                tables: access.tables == .yes ? true : access.tables == .no ? false : nil,
                instructions: access.instructions, postedStayLimitMinutes: access.postedStayLimitMinutes)
            return spot
        }
    }

    enum LoadError: Error { case unsupportedVersion, invalidItems }

    static func decode(_ data: Data) throws -> Self {
        let response = try JSONDecoder().decode(Self.self, from: data)
        guard [1, 2].contains(response.schemaVersion) else { throw LoadError.unsupportedVersion }
        guard Set(response.items.map(\.id)).count == response.items.count,
              response.items.allSatisfy({ UUID(uuidString: $0.id) != nil &&
                  !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  CLLocationCoordinate2DIsValid($0.location.coordinate) &&
                  ($0.access.postedStayLimitMinutes.map { $0 > 0 } ?? true)
              }) else { throw LoadError.invalidItems }
        return response
    }

    static func bundled() throws -> Self {
        guard let url = Bundle.main.url(forResource: "CoolSpotCatalog.prototype", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try decode(Data(contentsOf: url))
    }
}

@MainActor
extension PrototypeStore {
    static func catalogStore(reportDefaults: UserDefaults?) -> PrototypeStore {
        do {
            let response = try PrototypeCatalog.bundled()
            let imported = response.items.map { item in
                let source = response.sources?.first { $0.id == item.sourceReferences?.first?.sourceID }
                return item.makeSpot(catalogueSource: source)
            }
            let store = PrototypeStore(reportDefaults: reportDefaults,
                                       catalogSpots: imported + PrototypeComparisonPlaces.communitySpots)
            // Keep the ordinary-place case searchable without waiting for a network result.
            // Existing saved metadata takes precedence over this comparison seed.
            if store.place(PrototypeComparisonPlaces.ordinaryPlace.id) == nil {
                store.remember(PrototypeComparisonPlaces.ordinaryPlace)
            }
            return store
        } catch {
            let store = PrototypeStore(reportDefaults: reportDefaults, catalogSpots: [])
            store.catalogError = "Cool Spots couldn’t load."
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

    static var communitySpots: [CoolSpot] { [communitySpot, communityRoom, shadedGarden] }

    static var communitySpot: CoolSpot {
        var spot = makeSpot(id: tateID, name: "Tate Modern", address: "Bankside, London SE1 9TG",
                            latitude: 51.5074983, longitude: -0.0994222, environment: .indoors,
                            type: .culture, features: [.coolerIndoors], presence: 0,
                            toilets: .onSite, wheelchair: true, staffed: true, tables: true)
        spot.applePlaceID = "I5D0F2F6C33848101"
        return spot
    }

    private static var communityRoom: CoolSpot {
        var spot = makeSpot(id: roomID, name: "Example Community Room", address: "Southwark, London",
                 latitude: 51.5056, longitude: -0.0950, environment: .indoors,
                 type: .publicService, features: [.fans, .drinkingWater], presence: 2,
                 toilets: .none, wheelchair: false, staffed: true, tables: true)
        spot.photos = PlacePhotoAsset.examples
        return spot
    }

    private static var shadedGarden: CoolSpot {
        makeSpot(id: gardenID, name: "Example Shaded Garden", address: "Southwark, London",
                 latitude: 51.5030, longitude: -0.0982, environment: .outdoors,
                 type: .park, features: [.treeShade], presence: 1,
                 toilets: .unknown, wheelchair: true, staffed: false, tables: nil)
    }

    private static func makeSpot(id: String, name: String, address: String,
                                 latitude: Double, longitude: Double, environment: PlaceEnvironment,
                                 type: PlaceType, features: [CoolingFeature], presence: Int,
                                 toilets: PlaceInformation.Toilets, wheelchair: Bool?,
                                 staffed: Bool?, tables: Bool?) -> CoolSpot {
        let reports = visitorReports.compactMap(\.report).filter { $0.spotID == id }
        let experiences = reports.reduce(into: [CoolingExperience: Int]()) { $0[$1.experience, default: 0] += 1 }
        let stays = reports.reduce(into: [StayLength: Int]()) { counts, report in
            if let stay = report.stayLength { counts[stay, default: 0] += 1 }
        }
        var spot = CoolSpot(id: id, name: name, address: address, latitude: latitude, longitude: longitude,
                            source: .community, environment: environment, type: type,
                            features: features, access: .free, seating: .available,
                            distance: "", presenceCount: presence, experienceReports: experiences,
                            latestReportAt: reports.map(\.visitedAt).max() ?? .distantPast,
                            stayReports: stays, comments: reports.map(\.comment).filter { !$0.isEmpty }, isNearby: false)
        spot.entryEligibility = .everyone
        spot.information = PlaceInformation(
            source: .init(label: "Example cooling info", isExample: true),
            toilets: toilets, wheelchairAccessible: wheelchair, staffedWhenOpen: staffed, tables: tables)
        return spot
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
