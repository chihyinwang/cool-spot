import CoreLocation
import SwiftUI
import UIKit

// THROWAWAY PROTOTYPE
// Question: can people distinguish discovering, privately saving, visiting,
// and contributing reviewed public cooling information?

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "appAppearance"
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Match System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AppStyle {
    // A fixed dark fill used only when the foreground is explicitly white.
    static let ink = Color(red: 0.05, green: 0.25, blue: 0.28)
    // Brand-coloured foreground that remains legible on system backgrounds.
    static let brand = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.56, green: 0.88, blue: 0.82, alpha: 1)
            : UIColor(red: 0.05, green: 0.25, blue: 0.28, alpha: 1)
    })
    // Opaque supporting copy for forms and report evidence, including in glare.
    // Avoid hierarchical opacity on tinted buttons and pale field placeholders.
    static let supportingText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.74, green: 0.77, blue: 0.79, alpha: 1)
            : UIColor(red: 0.30, green: 0.33, blue: 0.35, alpha: 1)
    })
    static let mint = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.23, blue: 0.20, alpha: 1)
            : UIColor(red: 0.78, green: 0.93, blue: 0.86, alpha: 1)
    })
    static let blue = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.21, blue: 0.25, alpha: 1)
            : UIColor(red: 0.82, green: 0.93, blue: 0.96, alpha: 1)
    })
    static let sun = Color(red: 0.98, green: 0.76, blue: 0.28)
    static let sunSurface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.26, green: 0.20, blue: 0.06, alpha: 1)
            : UIColor(red: 1.00, green: 0.94, blue: 0.76, alpha: 1)
    })
    static let paper = Color(uiColor: .systemGroupedBackground)
    static let controlSurface = Color(uiColor: .secondarySystemBackground)
    static let subtleBorder = Color(uiColor: .separator)
}

enum SpotSource: String {
    case gla = "Official Cool Space"
    case community = "Community Cool Spot"
    case unknown = "Cool Spot"
}

enum PlaceEnvironment: String, CaseIterable, Identifiable, Codable {
    case indoors = "Indoors"
    case outdoors = "Outdoors"
    case both = "Both"
    case unknown = "Not sure"
    var id: String { rawValue }
}

enum PlaceType: String, CaseIterable, Identifiable, Hashable, Codable {
    case library = "Library or learning space"
    case publicService = "Community or public service"
    case faith = "Faith or worship space"
    case culture = "Museum or cultural venue"
    case leisure = "Sports or leisure centre"
    case shop = "Shop, supermarket or shopping centre"
    case food = "Café, restaurant or food hall"
    case park = "Park, garden or woodland"
    case square = "Square, plaza or courtyard"
    case waterside = "Waterside or water feature"
    case transport = "Transport or waiting area"
    case other = "Other"
    case unknown = "Not sure"

    var id: String { rawValue }
    var shortName: String {
        switch self {
        case .library: "Library"
        case .publicService: "Public space"
        case .faith: "Faith space"
        case .culture: "Culture"
        case .leisure: "Leisure"
        case .shop: "Shop"
        case .food: "Food & drink"
        case .park: "Park"
        case .square: "Square"
        case .waterside: "Waterside"
        case .transport: "Transport"
        case .other: "Other"
        case .unknown: "Place"
        }
    }
    var symbol: String {
        switch self {
        case .library: "books.vertical.fill"
        case .publicService: "building.columns.fill"
        case .faith: "sparkles"
        case .culture: "theatermasks.fill"
        case .leisure: "figure.pool.swim"
        case .shop: "basket.fill"
        case .food: "cup.and.saucer.fill"
        case .park: "tree.fill"
        case .square: "building.2.fill"
        case .waterside: "water.waves"
        case .transport: "tram.fill"
        case .other, .unknown: "mappin"
        }
    }
}

enum CoolingFeature: String, CaseIterable, Identifiable, Hashable, Codable {
    case airConditioning = "Air conditioning"
    case fans = "Fans"
    case coolerIndoors = "Cooler indoor space"
    case treeShade = "Tree shade"
    case structuralShade = "Structural shade"
    case drinkingWater = "Drinking water"
    case waterFeature = "Water nearby"
    case ventilation = "Natural ventilation"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .airConditioning: "snowflake"
        case .fans: "fan"
        case .coolerIndoors: "house.fill"
        case .treeShade: "tree.fill"
        case .structuralShade: "umbrella.fill"
        case .drinkingWater: "waterbottle.fill"
        case .waterFeature: "water.waves"
        case .ventilation: "wind"
        }
    }
}

enum CoolingExperience: String, CaseIterable, Identifiable, Hashable, Codable {
    case notCooler = "Not cooler"
    case aLittleCooler = "A little cooler"
    case muchCooler = "Much cooler"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .notCooler: "sun.max"
        case .aLittleCooler: "wind"
        case .muchCooler: "snowflake"
        }
    }

    var summary: String {
        switch self {
        case .notCooler: "Not cooler than outside"
        case .aLittleCooler: "A little cooler than outside"
        case .muchCooler: "Much cooler than outside"
        }
    }
}

enum AccessType: String, CaseIterable, Identifiable, Codable {
    case free = "Free to use"
    case purchase = "Purchase required"
    case entryFee = "Entry fee"
    case unsure = "Not sure"
    var id: String { rawValue }
    var summary: String { self == .unsure ? "Cost not confirmed" : rawValue }
}

enum PlaceEntryEligibility: String, CaseIterable, Identifiable, Codable {
    case everyone = "Everyone"
    case limited = "Limited access"
    case unknown = "Not sure"
    var id: Self { self }

    static let limitedExamples = "E.g. students, members or residents."

    func summary(requirement: String) -> String? {
        switch self {
        case .everyone: return "Open to everyone"
        case .unknown: return nil
        case .limited:
            let detail = requirement.trimmingCharacters(in: .whitespacesAndNewlines)
            return detail.isEmpty ? "Limited access · Requirements not confirmed" : detail
        }
    }
}

enum SeatingType: String, CaseIterable, Identifiable, Codable {
    case available = "Seating available"
    case limited = "Limited seating"
    case none = "No seating"
    case unsure = "Not sure"
    var id: String { rawValue }
    // Keep stored values compatible; this describes seating, not vacant seats.
    var displayName: String { self == .available ? "Seating provided" : rawValue }
}

enum StayLength: String, CaseIterable, Identifiable, Codable {
    case under15 = "Less than 15 minutes"
    case under30 = "15–30 minutes"
    case under60 = "30–60 minutes"
    case under120 = "1–2 hours"
    case over120 = "More than 2 hours"
    case privateAnswer = "Prefer not to say"
    var id: String { rawValue }
    var compact: String {
        switch self {
        case .under15: "<15m"
        case .under30: "15–30m"
        case .under60: "30–60m"
        case .under120: "1–2h"
        case .over120: "2h+"
        case .privateAnswer: "Private"
        }
    }
}

// Shared place facts. The view uses available fields, regardless of their source.
struct PlaceInformation {
    struct Source {
        let label: String
        var url: URL? = nil
        var isExample = false
    }

    enum Toilets: String, CaseIterable, Identifiable, Codable {
        case onSite = "on_site", nearby, notOnSite = "not_on_site", none, unknown
        var id: Self { self }
        var choiceLabel: String { label ?? "Not added" }
        var label: String? {
            switch self {
            case .onSite: "Toilets on site"
            case .nearby: "Toilets nearby"
            case .notOnSite: "No toilets on site"
            case .none: "No toilets"
            case .unknown: nil
            }
        }
    }

    var source = Source(label: "Example", isExample: true)
    var coolingDetails: String? = nil
    var hours: String? = nil
    var toilets: Toilets = .unknown
    var wheelchairAccessible: Bool? = nil
    var staffedWhenOpen: Bool? = nil
    var tables: Bool? = nil
    var areaDescription: String? = nil
    var postedStayLimit = CoolSpotStayLimit.unknown
    var additionalInformation: String? = nil
    var drinkingWater: Bool? = nil

    var hasFacilities: Bool {
        toilets != .unknown || staffedWhenOpen != nil || tables != nil
    }
}

struct CoolSpot: Identifiable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let source: SpotSource
    let environment: PlaceEnvironment
    let type: PlaceType
    let features: [CoolingFeature]
    let access: AccessType
    let seating: SeatingType
    let distance: String
    var presenceCount: Int
    var experienceReports: [CoolingExperience: Int]
    var latestReportAt: Date
    var stayReports: [StayLength: Int]
    var comments: [String]
    var isNearby: Bool
    var entryEligibility: PlaceEntryEligibility = .unknown
    var entryRequirement = ""
    var entryInformation = ""
    var information = PlaceInformation()
    var placeID: UUID? = nil
    var apiRecord: CoolSpotAPIRecord? = nil
    var applePlaceID: String? = nil
    var photos: [PlacePhotoAsset] = []
    var publishedRecord: CoolSpotsResponse.Item? = nil
    var isExample: Bool { information.source.isExample }
    var sourceLabel: String { information.source.label }
    var detailsApplePlaceID: String? {
        if let apiRecord {
            return apiRecord.detailsApplePlaceID
        }

        return publishedRecord?.mapReferences?.first {
            $0.provider == "apple_maps" &&
            ["same_place", "within_place"].contains($0.relationship) &&
            ["automatic", "reviewed"].contains($0.verification)
        }?.placeID ?? applePlaceID
    }
    var metadataLabel: String { "\(type.shortName) · \(sourceLabel)" }
    var entrySummary: String? { entryEligibility.summary(requirement: entryRequirement) }
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

struct RecognisedPlace: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let type: PlaceType
    let distance: String
    // Missing source evidence is unknown, never an implicit indoor setting.
    var trustedSetting: PlaceEnvironment? = nil
    var hasTrustedType = true
    var coolSpotID: String? = nil
    var sourceCategory: String? = nil
    var phoneNumber: String? = nil
    var websiteURL: URL? = nil
    var alternateApplePlaceIDs: [String]? = nil
    var structuredAddress: CoolSpotsResponse.Item.Address? = nil
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

enum SavedLocationKind: Equatable, Codable {
    case coolSpot(String)
    case recognisedPlace(String)
    case coordinate
}

struct SavedLocation: Identifiable, Codable {
    let id: UUID
    var title: String
    let subtitle: String
    let savedAt: Date
    let latitude: Double
    let longitude: Double
    let kind: SavedLocationKind
    var note: String
}

enum ContributionKind: String, Codable {
    case newPlace = "New Cool Spot"
    case placeUpdate = "Place details"
    case visitReport = "Past visit"
}

enum ContributionStatus: Equatable, Codable {
    case draft
    case inReview
    case actionNeeded(String)
    case published
    case notPublished(String)
    case merged(String)

    var title: String {
        switch self {
        case .draft: "Draft"
        case .inReview: "In review"
        case .actionNeeded: "Action needed"
        case .published: "Published"
        case .notPublished: "Not published"
        case .merged: "Added to an existing Cool Spot"
        }
    }
    var detail: String {
        switch self {
        case .draft: "Only you can see this."
        case .inReview: "A reviewer will check it before it appears on the map."
        case .actionNeeded(let reason): reason
        case .published: "This information is now part of the shared map."
        case .notPublished(let reason): reason
        case .merged(let place): "Your information was added to \(place)."
        }
    }
    var symbol: String {
        switch self {
        case .draft: "doc"
        case .inReview: "clock.fill"
        case .actionNeeded: "exclamationmark.circle.fill"
        case .published: "checkmark.circle.fill"
        case .notPublished: "xmark.circle.fill"
        case .merged: "arrow.triangle.merge"
        }
    }
}

struct Contribution: Identifiable, Codable {
    let id: UUID
    let title: String
    let kind: ContributionKind
    var status: ContributionStatus
    let createdAt: Date
    var placeDraft: PlaceContributionDraft? = nil
    var photoID: String? = nil
}

struct VisitReport: Identifiable, Codable {
    let id: UUID
    let spotID: String
    let experience: CoolingExperience
    let helpedFeatures: Set<CoolingFeature>
    let stayLength: StayLength?
    let comment: String
    let visitedAt: Date
    let confirmationAt: Date
    let submittedAt: Date
}

struct VisitReportDraft: Codable, Equatable {
    var experience: CoolingExperience?
    var helpedFeatures: Set<CoolingFeature> = []
    var stay: StayLength?
    var comment = ""
    var visitedAt: Date
}

enum ReportProvenance { case own, visitor, example }

// A report's author is independent of its completeness. Example dates/answers
// are explicitly authored fixtures, never reconstructed from aggregate counts.
struct VisitorReportItem: Identifiable {
    let id: String
    let comment: String
    let report: VisitReport?
    let provenance: ReportProvenance
    var isOwn: Bool { provenance == .own }
    var isExample: Bool { provenance == .example }
    var sourceLabel: String { isOwn ? "Your report" : isExample ? "Example visitor report" : "Visitor report" }

    static func newestFirst(_ items: [Self]) -> [Self] {
        items.sorted {
            let left = $0.report?.visitedAt ?? .distantPast
            let right = $1.report?.visitedAt ?? .distantPast
            if left != right { return left > right }
            let leftSent = $0.report?.submittedAt ?? .distantPast
            let rightSent = $1.report?.submittedAt ?? .distantPast
            return leftSent == rightSent ? $0.id < $1.id : leftSent > rightSent
        }
    }
}

private struct PopsicleSnapshot: Codable {
    var sent: Set<String> = []
    var receivedExamples: Set<UUID> = []
    var explanationSeen = false
}

private struct ReportJourneySnapshot: Codable {
    var confirmations: [String: Date]
    var drafts: [String: VisitReportDraft]
    var reports: [VisitReport]
    var savedLocations: [SavedLocation]
    var nearbySpotIDs: [String]
    var activePresenceSpotID: String?
    var presenceEndsAt: Date?
    // Optional so existing v1 journeys still decode without losing owner data.
    var savedPlaceDetails: [RecognisedPlace]? = nil
    var placeContributions: [Contribution]? = nil
    var publishedCoolSpotRecords: [CoolSpotsResponse.Item]? = nil
}

extension ReportJourneySnapshot {
    private enum CodingKeys: String, CodingKey {
        case confirmations, drafts, reports, savedLocations, nearbySpotIDs
        case activePresenceSpotID, presenceEndsAt, savedPlaceDetails, placeContributions
        case publishedCoolSpotRecords
        // Read the previous persisted key so an upgrade preserves local publications.
        case legacyPublishedRecords = "publishedCatalogue"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        confirmations = try values.decode([String: Date].self, forKey: .confirmations)
        drafts = try values.decode([String: VisitReportDraft].self, forKey: .drafts)
        reports = try values.decode([VisitReport].self, forKey: .reports)
        savedLocations = try values.decode([SavedLocation].self, forKey: .savedLocations)
        nearbySpotIDs = try values.decode([String].self, forKey: .nearbySpotIDs)
        activePresenceSpotID = try values.decodeIfPresent(String.self, forKey: .activePresenceSpotID)
        presenceEndsAt = try values.decodeIfPresent(Date.self, forKey: .presenceEndsAt)
        savedPlaceDetails = try values.decodeIfPresent([RecognisedPlace].self, forKey: .savedPlaceDetails)
        placeContributions = try values.decodeIfPresent([Contribution].self, forKey: .placeContributions)
        publishedCoolSpotRecords = try values.decodeIfPresent([CoolSpotsResponse.Item].self, forKey: .publishedCoolSpotRecords)
            ?? values.decodeIfPresent([CoolSpotsResponse.Item].self, forKey: .legacyPublishedRecords)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(confirmations, forKey: .confirmations)
        try values.encode(drafts, forKey: .drafts)
        try values.encode(reports, forKey: .reports)
        try values.encode(savedLocations, forKey: .savedLocations)
        try values.encode(nearbySpotIDs, forKey: .nearbySpotIDs)
        try values.encodeIfPresent(activePresenceSpotID, forKey: .activePresenceSpotID)
        try values.encodeIfPresent(presenceEndsAt, forKey: .presenceEndsAt)
        try values.encodeIfPresent(savedPlaceDetails, forKey: .savedPlaceDetails)
        try values.encodeIfPresent(placeContributions, forKey: .placeContributions)
        try values.encodeIfPresent(publishedCoolSpotRecords, forKey: .publishedCoolSpotRecords)
    }
}

struct CoolingEvidence: Equatable {
    let counts: [CoolingExperience: Int]

    var total: Int { counts.values.reduce(0, +) }

    // A plurality is not a majority. Ties and no evidence have no single leader.
    var leadingExperience: CoolingExperience? {
        guard total > 0, let largest = counts.values.max() else { return nil }
        let leaders = CoolingExperience.allCases.filter { counts[$0, default: 0] == largest }
        return leaders.count == 1 ? leaders.first : nil
    }

    var headline: String {
        guard total > 0 else { return "No visitor reports yet" }
        return leadingExperience?.summary ?? "Visitors had different experiences"
    }

    var attribution: String {
        if total == 1 { return "1 visitor reported" }
        guard let leadingExperience else {
            return "\(total) visitor reports"
        }
        return "\(counts[leadingExperience, default: 0]) of \(total) reports said"
    }
}

@MainActor
final class PrototypeStore: ObservableObject {
    enum CatalogueMode { case local, api }
    @Published var spots: [CoolSpot]
    @Published var coolSpotsLoadError: String?
    let usesLoadedCoolSpots: Bool
    let usesAPICatalogue: Bool
    private var nearbySpotIDs: Set<String> = []
    @Published var savedLocations = Fixtures.saved { didSet { persistJourneys() } }
    @Published var contributions = Fixtures.contributions
    @Published var contributionError: String?
    private var publishedCoolSpotRecords: [CoolSpotsResponse.Item] = []
    @Published var visitReports: [VisitReport] = []
    @Published var activePresenceSpotID: String? { didSet { persistJourneys() } }
    @Published private(set) var presenceEndsAt: Date?
    // Private, per-place eligibility; never created by browsing or saving.
    @Published private(set) var visitConfirmedAt: [String: Date] = [:]
    @Published private(set) var reportDrafts: [String: VisitReportDraft] = [:]
    @Published var unlockedTypes: Set<PlaceType> = [.library, .park]
    @Published var isSignedIn = false
    @Published private var popsicles = PopsicleSnapshot()
    var hasSeenPopsicleExplanation: Bool { popsicles.explanationSeen }

    @Published private var selectedPlaces: [RecognisedPlace] = []
    var recognisedPlaces: [RecognisedPlace] { (usesLoadedCoolSpots ? [] : Fixtures.places) + selectedPlaces }
    let currentCoordinate = CLLocationCoordinate2D(latitude: 51.5059, longitude: -0.0906)
    private let reportDefaults: UserDefaults?
    private var isRestoringJourneys = true
    private static let journeyKey = "prototype.reportJourneys.v1"

    // Tests use memory-only stores unless they explicitly exercise relaunch recovery.
    init(reportDefaults: UserDefaults? = nil, loadedCoolSpots: [CoolSpot]? = nil,
         catalogueMode: CatalogueMode = .local) {
        self.reportDefaults = reportDefaults
        usesAPICatalogue = catalogueMode == .api
        usesLoadedCoolSpots = usesAPICatalogue || loadedCoolSpots != nil
        spots = usesAPICatalogue ? [] : (loadedCoolSpots ?? Fixtures.spots)
        nearbySpotIDs = Set(spots.filter(\.isNearby).map(\.id))
        if usesLoadedCoolSpots {
            savedLocations = []
            contributions = []
            unlockedTypes = []
        }
        if let data = reportDefaults?.data(forKey: "prototype.popsicles.v1"),
           let saved = try? JSONDecoder().decode(PopsicleSnapshot.self, from: data) {
            popsicles = saved
        }
        if let data = reportDefaults?.data(forKey: Self.journeyKey),
           let snapshot = try? JSONDecoder().decode(ReportJourneySnapshot.self, from: data) {
            visitConfirmedAt = snapshot.confirmations
            reportDrafts = snapshot.drafts
            visitReports = snapshot.reports
            savedLocations = snapshot.savedLocations
            selectedPlaces = snapshot.savedPlaceDetails ?? []
            publishedCoolSpotRecords = snapshot.publishedCoolSpotRecords ?? []
            if !usesAPICatalogue {
                for item in publishedCoolSpotRecords { applyPublished(item) }
            }
            let restored = (snapshot.placeContributions ?? []).map { record in
                var record = record
                if let photoID = record.photoID { record.placeDraft?.values.photo = PrototypePhotoStorage.original(id: photoID) }
                return record
            }
            contributions.insert(contentsOf: restored, at: 0)
            if let end = snapshot.presenceEndsAt, end > .now {
                activePresenceSpotID = snapshot.activePresenceSpotID
                presenceEndsAt = end
            }
            nearbySpotIDs = Set(snapshot.nearbySpotIDs)
            for index in spots.indices {
                spots[index].isNearby = snapshot.nearbySpotIDs.contains(spots[index].id)
            }
            contributions.insert(contentsOf: snapshot.reports.map {
                Contribution(id: $0.id, title: spot($0.spotID)?.name ?? "Cool Spot",
                             kind: .visitReport, status: .published, createdAt: $0.submittedAt)
            }, at: 0)
        }
        isRestoringJourneys = false
    }

    func replaceAPICatalogue(_ items: [CoolSpot]) {
        guard usesAPICatalogue else { return }
        spots = items.map { item in
            var item = item
            item.isNearby = nearbySpotIDs.contains(item.id)
            return item
        }
    }

    private func persistJourneys() {
        guard !isRestoringJourneys, let reportDefaults else { return }
        let snapshot = ReportJourneySnapshot(confirmations: visitConfirmedAt, drafts: reportDrafts,
                                             reports: visitReports, savedLocations: savedLocations,
                                             nearbySpotIDs: usesAPICatalogue ? nearbySpotIDs.sorted() : spots.filter(\.isNearby).map(\.id),
                                             activePresenceSpotID: activePresenceSpotID, presenceEndsAt: presenceEndsAt,
                                             savedPlaceDetails: selectedPlaces.filter { isSaved(placeID: $0.id) },
                                             placeContributions: contributions.filter { $0.kind != .visitReport },
                                             publishedCoolSpotRecords: publishedCoolSpotRecords)
        if let data = try? JSONEncoder().encode(snapshot) {
            reportDefaults.set(data, forKey: Self.journeyKey)
        }
    }

    func simulateNearbySpot(_ id: String?) {
        nearbySpotIDs = Set(id.map { [$0] } ?? [])
        for index in spots.indices { spots[index].isNearby = spots[index].id == id }
        persistJourneys()
    }

    func simulateEarlierVisits(at now: Date = .now) {
        for id in visitConfirmedAt.keys where publishedReport(for: id) == nil {
            guard !hasUnfinishedReport(for: id) else { continue }
            visitConfirmedAt[id] = now.addingTimeInterval(-7 * 24 * 60 * 60)
        }
        simulateNearbySpot(nil)
    }

    // API mode never treats a private bookmark or old fixture as current public facts.
    func spot(_ id: String) -> CoolSpot? {
        spots.first { $0.id == id } ?? (usesAPICatalogue ? nil : Fixtures.spots.first { $0.id == id })
    }
    func place(_ id: String) -> RecognisedPlace? { recognisedPlaces.first { $0.id == id } ?? Fixtures.places.first { $0.id == id } }
    func remember(_ place: RecognisedPlace) {
        guard !Fixtures.places.contains(where: { $0.id == place.id }) else { return }
        if let index = selectedPlaces.firstIndex(where: { $0.id == place.id }) {
            selectedPlaces[index] = place
        } else {
            selectedPlaces.append(place)
        }
    }
    func isSaved(spotID: String) -> Bool { savedLocations.contains { $0.kind == .coolSpot(spotID) } }
    func isSaved(placeID: String) -> Bool { savedLocations.contains { $0.kind == .recognisedPlace(placeID) } }

    @discardableResult func toggleSaved(_ spot: CoolSpot) -> Bool {
        if let saved = savedLocation(for: spot), let index = savedLocations.firstIndex(where: { $0.id == saved.id }) {
            savedLocations.remove(at: index); return false
        }
        savedLocations.insert(.init(id: UUID(), title: spot.name, subtitle: spot.address, savedAt: .now,
                                    latitude: spot.latitude, longitude: spot.longitude,
                                    kind: .coolSpot(spot.id), note: ""), at: 0)
        return true
    }

    @discardableResult func toggleSaved(_ place: RecognisedPlace) -> Bool {
        if let spot = existingSpot(for: place) { return toggleSaved(spot) }
        if let index = savedLocations.firstIndex(where: { $0.kind == .recognisedPlace(place.id) }) {
            savedLocations.remove(at: index); return false
        }
        remember(place)
        savedLocations.insert(.init(id: UUID(), title: place.name, subtitle: place.address, savedAt: .now,
                                    latitude: place.latitude, longitude: place.longitude,
                                    kind: .recognisedPlace(place.id), note: ""), at: 0)
        return true
    }

    @discardableResult func saveCurrentLocation() -> SavedLocation {
        let saved = SavedLocation(id: UUID(), title: "Dropped pin", subtitle: "Near Southwark Street · SE1",
                                  savedAt: .now, latitude: currentCoordinate.latitude,
                                  longitude: currentCoordinate.longitude, kind: .coordinate, note: "")
        savedLocations.insert(saved, at: 0)
        return saved
    }

    func updateSaved(_ id: UUID, title: String, note: String) {
        guard let index = savedLocations.firstIndex(where: { $0.id == id }) else { return }
        savedLocations[index].title = title
        savedLocations[index].note = note
    }

    func presence(for spot: CoolSpot, at now: Date = .now) -> Int {
        spot.presenceCount + (isSharingPresence(for: spot, at: now) ? 1 : 0)
    }

    func isSharingPresence(for spot: CoolSpot, at now: Date = .now) -> Bool {
        activePresenceSpotID == spot.id && (presenceEndsAt.map { now < $0 } ?? false)
    }

    func endExpiredPresence(at now: Date = .now) {
        if let presenceEndsAt, now >= presenceEndsAt { activePresenceSpotID = nil; self.presenceEndsAt = nil }
    }

    func checkIn(_ spot: CoolSpot, at now: Date = .now) {
        guard spot.isNearby else { return }
        confirmVisitIfNeeded(for: spot, at: now)
        activePresenceSpotID = spot.id
        presenceEndsAt = now.addingTimeInterval(10 * 60)
        unlockedTypes.insert(spot.type)
        persistJourneys()
    }

    func canReportVisit(for spot: CoolSpot, at now: Date = .now) -> Bool {
        if hasUnfinishedReport(for: spot.id) { return true }
        if hasCurrentConfirmation(for: spot, at: now), publishedReport(for: spot.id) != nil { return false }
        if spot.isNearby { return true }
        return hasCurrentConfirmation(for: spot, at: now)
    }

    func hasCurrentConfirmation(for spot: CoolSpot, at now: Date = .now) -> Bool {
        guard let confirmedAt = visitConfirmedAt[spot.id] else { return false }
        return confirmedAt <= now
    }

    // A new visit is explicit, so reading an old report or retrying Publish
    // never silently creates a second report for the same visit.
    @discardableResult
    func beginNewVisitReport(for spot: CoolSpot, at now: Date = .now) -> Bool {
        guard spot.isNearby, publishedReport(for: spot.id) != nil,
              !hasUnfinishedReport(for: spot.id), visitConfirmedAt[spot.id] != now else { return false }
        visitConfirmedAt[spot.id] = now
        reportDrafts[spot.id] = nil
        return beginVisitReport(for: spot, at: now)
    }

    func hasUnfinishedReport(for spotID: String) -> Bool {
        reportDrafts[spotID] != nil && visitConfirmedAt[spotID] != nil && publishedReport(for: spotID) == nil
    }

    var unfinishedReportSpots: [CoolSpot] {
        spots.filter { hasUnfinishedReport(for: $0.id) }
            .sorted { (reportDrafts[$0.id]?.visitedAt ?? .distantPast) > (reportDrafts[$1.id]?.visitedAt ?? .distantPast) }
    }

    func visitsWithoutReports(at now: Date = .now) -> [CoolSpot] {
        visitsToShare.filter { reportDrafts[$0.id] == nil && hasCurrentConfirmation(for: $0, at: now) }
    }

    func publishedReport(for spotID: String) -> VisitReport? {
        guard let confirmation = visitConfirmedAt[spotID] else { return nil }
        return visitReports.first { $0.spotID == spotID && $0.confirmationAt == confirmation }
    }

    var visitsToShare: [CoolSpot] {
        spots.filter { visitConfirmedAt[$0.id] != nil && publishedReport(for: $0.id) == nil }
            .sorted { visitConfirmedAt[$0.id, default: .distantPast] > visitConfirmedAt[$1.id, default: .distantPast] }
    }

    private func confirmVisitIfNeeded(for spot: CoolSpot, at now: Date) {
        // A later arrival must never silently replace an unfinished report's visit.
        guard !hasUnfinishedReport(for: spot.id) else { return }
        if !hasCurrentConfirmation(for: spot, at: now) {
            visitConfirmedAt[spot.id] = now
            reportDrafts[spot.id] = nil
        }
    }

    @discardableResult
    func beginVisitReport(for spot: CoolSpot, at now: Date = .now) -> Bool {
        guard canReportVisit(for: spot, at: now) else { return false }
        if spot.isNearby { confirmVisitIfNeeded(for: spot, at: now) }
        if reportDrafts[spot.id] == nil {
            reportDrafts[spot.id] = VisitReportDraft(visitedAt: visitConfirmedAt[spot.id] ?? now)
        }
        persistJourneys()
        return true
    }

    func saveReportDraft(_ draft: VisitReportDraft, for spotID: String) {
        guard visitConfirmedAt[spotID] != nil, publishedReport(for: spotID) == nil else { return }
        reportDrafts[spotID] = draft
        persistJourneys()
    }

    func discardReportAnswers(_ spotID: String) {
        reportDrafts[spotID] = nil
        // Discarding text does not erase the fact that a visit was confirmed.
        persistJourneys()
    }

    func submitContribution(title: String, kind: ContributionKind) {
        contributions.insert(.init(id: UUID(), title: title, kind: kind, status: .inReview, createdAt: .now), at: 0)
    }

    func existingSpot(for place: RecognisedPlace) -> CoolSpot? {
        if let direct = spot(place.coolSpotID ?? place.id) { return direct }
        let ids = Set(([place.appleMapItemIdentifier?.rawValue].compactMap { $0 }) + (place.alternateApplePlaceIDs ?? []))
        return spots.first { $0.applePlaceID.map(ids.contains) ?? false }
    }

    func searchCoolSpots(query: String, including places: [RecognisedPlace]) -> [CoolSpot] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        let linkedIDs = Set(places.compactMap { existingSpot(for: $0)?.id })
        let appleIDs = Set(places.flatMap {
            ([$0.appleMapItemIdentifier?.rawValue].compactMap { $0 }) + ($0.alternateApplePlaceIDs ?? [])
        })
        // A containing venue can help discover its cooling area without sharing identity.
        return spots.filter { linkedIDs.contains($0.id) ||
            ($0.detailsApplePlaceID.map(appleIDs.contains) ?? false) || $0.name.localizedCaseInsensitiveContains(query) ||
            $0.address.localizedCaseInsensitiveContains(query) || $0.type.rawValue.localizedCaseInsensitiveContains(query) }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(query) == .orderedSame &&
                rhs.name.localizedCaseInsensitiveCompare(query) != .orderedSame
            }
    }

    func savedLocation(for spot: CoolSpot) -> SavedLocation? {
        savedLocations.first { saved in
            if saved.kind == .coolSpot(spot.id) { return true }
            if case .recognisedPlace(let id) = saved.kind, let place = place(id) {
                return existingSpot(for: place)?.id == spot.id
            }
            return false
        }
    }

    // An exact identity match is a duplicate; proximity alone cannot identify a venue.
    func existingSpot(for draft: PlaceContributionDraft) -> CoolSpot? {
        if let id = draft.spotID { return spot(id) }
        if let place = draft.selectedPlace, let existing = existingSpot(for: place) { return existing }
        return spots.first { candidate in
            let samePoint = abs(candidate.latitude - draft.values.latitude) < 0.000001 &&
                abs(candidate.longitude - draft.values.longitude) < 0.000001
            return samePoint && (draft.isExactSpot ||
                candidate.name.caseInsensitiveCompare(draft.values.name.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame)
        }
    }

    @discardableResult
    func submitPlaceContribution(_ draft: PlaceContributionDraft) -> Bool {
        contributionError = nil
        guard draft.canSend else { return false }
        // The UI must explicitly reconcile a newly discovered duplicate first.
        if !draft.isUpdate, existingSpot(for: draft) != nil { return false }
        guard !contributions.contains(where: { $0.id == draft.id }) else { return false }
        do {
            let photoID = try draft.values.photo.map { try PrototypePhotoStorage.stage($0) }
            contributions.insert(.init(id: draft.id, title: draft.displayName,
                                       kind: draft.isUpdate ? .placeUpdate : .newPlace,
                                       status: .inReview, createdAt: .now, placeDraft: draft, photoID: photoID), at: 0)
            persistJourneys()
            return true
        } catch { contributionError = error.localizedDescription; return false }
    }

    @discardableResult
    func submitReport(spot: CoolSpot, experience: CoolingExperience,
                      helpedFeatures: Set<CoolingFeature>, stay: StayLength?, comment: String,
                      visitedAt: Date? = nil,
                      at now: Date = .now) -> Bool {
        guard beginVisitReport(for: spot, at: now) else { return false }
        guard let confirmation = visitConfirmedAt[spot.id] else { return false }
        let visitTime = visitedAt ?? reportDrafts[spot.id]?.visitedAt ?? confirmation
        guard visitTime <= now else { return false }
        visitReports.insert(.init(id: UUID(), spotID: spot.id, experience: experience,
                                  helpedFeatures: helpedFeatures, stayLength: stay,
                                  comment: comment, visitedAt: visitTime,
                                  confirmationAt: confirmation, submittedAt: now), at: 0)
        contributions.insert(.init(id: UUID(), title: spot.name, kind: .visitReport,
                                   status: .published, createdAt: now), at: 0)
        reportDrafts[spot.id] = nil
        persistJourneys()
        return true
    }

    func reportCounts(for spot: CoolSpot) -> (Int, Int) {
        let reports = experienceCounts(for: spot)
        return (reports[.aLittleCooler, default: 0] + reports[.muchCooler, default: 0],
                reports[.notCooler, default: 0])
    }

    func experienceCounts(for spot: CoolSpot) -> [CoolingExperience: Int] {
        var result = spot.experienceReports
        for report in visitReports where report.spotID == spot.id {
            result[report.experience, default: 0] += 1
        }
        return result
    }

    func leadingExperience(for spot: CoolSpot) -> CoolingExperience? {
        coolingEvidence(for: spot).leadingExperience
    }

    func coolingEvidence(for spot: CoolSpot) -> CoolingEvidence {
        CoolingEvidence(counts: experienceCounts(for: spot))
    }

    func latestReportDate(for spot: CoolSpot) -> Date? {
        var dates = visitReports.filter { $0.spotID == spot.id }.map(\.visitedAt)
        if spot.experienceReports.values.reduce(0, +) > 0 {
            dates.append(spot.latestReportAt)
        }
        return dates.max()
    }

    func experienceReportTotal(for spot: CoolSpot) -> Int {
        experienceCounts(for: spot).values.reduce(0, +)
    }

    func comments(for spot: CoolSpot) -> [String] {
        visitReports.filter { $0.spotID == spot.id && !$0.comment.isEmpty }.map(\.comment) + spot.comments
    }

    func visitorReportItems(for spot: CoolSpot) -> [VisitorReportItem] {
        let own = visitReports.filter { $0.spotID == spot.id }
            .map { VisitorReportItem(id: $0.id.uuidString, comment: $0.comment, report: $0, provenance: .own) }
        guard !usesAPICatalogue else { return VisitorReportItem.newestFirst(own) }
        let examples = (Fixtures.visitorReports + PrototypeComparisonPlaces.visitorReports)
            .filter { $0.report?.spotID == spot.id }
        return VisitorReportItem.newestFirst(own + examples)
    }

    func hasSentPopsicle(to id: String) -> Bool { popsicles.sent.contains(id) }

    @discardableResult func sendPopsicle(to id: String) -> Bool {
        // All peer reports are fixture examples until a backend supplies authorship.
        guard spots.contains(where: { spot in
            visitorReportItems(for: spot).contains { $0.id == id && !$0.isOwn }
        }), !popsicles.sent.contains(id) else { return false }
        popsicles.sent.insert(id)
        popsicles.explanationSeen = true
        persistPopsicles()
        return true
    }

    func undoPopsicle(to id: String) {
        popsicles.sent.remove(id)
        persistPopsicles()
    }

    func hasReceivedExamplePopsicle(for id: UUID) -> Bool { popsicles.receivedExamples.contains(id) }

    func simulateReceivedPopsicle(for id: UUID) {
        guard visitReports.contains(where: { $0.id == id }) else { return }
        popsicles.receivedExamples.insert(id)
        persistPopsicles()
    }

    private func persistPopsicles() {
        if let data = try? JSONEncoder().encode(popsicles) {
            reportDefaults?.set(data, forKey: "prototype.popsicles.v1")
        }
    }

    func stays(for spot: CoolSpot) -> [StayLength: Int] {
        var result = spot.stayReports
        for report in visitReports where report.spotID == spot.id {
            if let stay = report.stayLength, stay != .privateAnswer { result[stay, default: 0] += 1 }
        }
        return result
    }

    func simulate(_ status: ContributionStatus) {
        guard let index = contributions.firstIndex(where: {
            switch $0.kind {
            case .visitReport: false
            case .newPlace, .placeUpdate: true
            }
        }) else { return }
        if status == .published { _ = publishContribution(contributions[index].id); return }
        // A completed publication cannot be undone merely by changing a status label.
        guard contributions[index].status != .published else { return }
        if case .merged = status {
            contributionError = "Choose the matching place and submit an update before publishing. A status alone cannot merge places."
            return
        }
        contributions[index].status = status
        persistJourneys()
    }

    @discardableResult
    func publishContribution(_ id: UUID, at date: Date = .now) -> Bool {
        contributionError = nil
        guard !usesAPICatalogue else {
            contributionError = "Public place publishing requires the backend. Your proposal remains saved on this device."
            return false
        }
        guard let index = contributions.firstIndex(where: { $0.id == id }),
              let draft = contributions[index].placeDraft else { return false }
        if contributions[index].status == .published { return true }
        guard contributions[index].status == .inReview else {
            contributionError = "Only a proposal awaiting review can be published. Submit a revised proposal if changes are needed."
            return false
        }
        do {
            if !draft.isUpdate, existingSpot(for: draft) != nil { throw PrototypePublicationError.duplicatePlace }
            let item = try PrototypePublication.publish(draft, onto: draft.spotID.flatMap(spot),
                                                        photoID: contributions[index].photoID, at: date)
            // Exercise the same read contract used for imported places before applying any state.
            let response = CoolSpotsResponse(schemaVersion: CoolSpotsResponse.currentSchemaVersion, datasetID: "local-publication", generatedAt: ISO8601DateFormatter().string(from: date),
                                            source: nil, sources: [PrototypePublication.source] + (try CoolSpotsResponse.bundled().sources ?? [])
                                                + (try CoolSpotsResponse.bundled(named: "CommunityCoolSpots.prototype").sources ?? []), items: [item])
            let decoded = try CoolSpotsResponse.decode(JSONEncoder().encode(response))
            guard let published = decoded.items.first else { throw PrototypePublicationError.invalidContribution }
            publishedCoolSpotRecords.removeAll { $0.id == published.id }
            publishedCoolSpotRecords.append(published)
            applyPublished(published)
            contributions[index].status = .published
            persistJourneys()
            return true
        } catch {
            contributionError = error.localizedDescription
            contributions[index].status = .actionNeeded(error.localizedDescription)
            persistJourneys()
            return false
        }
    }

    private func applyPublished(_ item: CoolSpotsResponse.Item) {
        let previous = spots.first { $0.id == item.id }
        let source: CoolSpotsResponse.SourceMetadata
        if let previous {
            source = .init(id: item.sourceReferences?.first?.sourceID ?? PrototypePublication.source.id,
                           provider: previous.source == .gla ? "gla" : "community", label: previous.sourceLabel,
                           url: previous.information.source.url, isExample: previous.isExample)
        } else { source = PrototypePublication.source }
        let updated = item.makeSpot(sourceMetadata: source, retaining: previous)
        if let index = spots.firstIndex(where: { $0.id == item.id }) { spots[index] = updated }
        else { spots.append(updated) }
    }
}

enum Fixtures {
    // Complete, labelled synthetic reports for testing the same reading layout
    // as personal reports. Fixed dates prevent examples becoming newer at launch.
    static let visitorReports: [VisitorReportItem] = {
        func example(_ id: String, uuid: String, spot: String, at time: String,
                     experience: CoolingExperience, helped: Set<CoolingFeature>, stay: StayLength,
                     comment: String) -> VisitorReportItem {
            let date = ISO8601DateFormatter().date(from: time)!
            let report = VisitReport(id: UUID(uuidString: uuid)!, spotID: spot, experience: experience,
                                     helpedFeatures: helped, stayLength: stay, comment: comment,
                                     visitedAt: date, confirmationAt: date, submittedAt: date.addingTimeInterval(1800))
            return .init(id: id, comment: comment, report: report, provenance: .example)
        }
        return [
            example("example-library-0", uuid: "B7B97191-0051-4000-9000-000000000001", spot: "library",
                    at: "2026-09-05T14:00:00Z", experience: .muchCooler,
                    helped: [.airConditioning, .coolerIndoors], stay: .under60,
                    comment: "Quiet upstairs, with tables away from the windows."),
            example("example-shade-0", uuid: "B7B97191-0051-4000-9000-000000000002", spot: "shade",
                    at: "2026-09-04T15:00:00Z", experience: .aLittleCooler,
                    helped: [.treeShade], stay: .under30,
                    comment: "The bench by the brick wall stays shaded in late afternoon.")
        ]
    }()

    static let spots: [CoolSpot] = [
        .init(id: "library", name: "Riverside Library", address: "Tooley Street, London SE1",
              latitude: 51.5045, longitude: -0.0865, source: .gla, environment: .indoors,
              type: .library,
              features: [.airConditioning, .coolerIndoors, .drinkingWater, .ventilation,
                         .structuralShade, .treeShade, .waterFeature],
              access: .free, seating: .available, distance: "6 min walk", presenceCount: 2,
              experienceReports: [.notCooler: 1, .aLittleCooler: 2, .muchCooler: 5],
              latestReportAt: .now.addingTimeInterval(-7_200),
              stayReports: [.under30: 1, .under60: 4, .under120: 7, .over120: 2],
              comments: ["Quiet upstairs, with tables away from the windows."], isNearby: true,
              photos: PlacePhotoAsset.legacyLibrary),
        .init(id: "shade", name: "Shade beside the playground", address: "Mint Street Park, London SE1",
              latitude: 51.5030, longitude: -0.0982, source: .community, environment: .outdoors,
              type: .park, features: [.treeShade, .drinkingWater], access: .free,
              seating: .limited, distance: "11 min walk", presenceCount: 0,
              experienceReports: [.notCooler: 5, .aLittleCooler: 6, .muchCooler: 3],
              latestReportAt: .now.addingTimeInterval(-18_000),
              stayReports: [.under15: 2, .under30: 5, .under60: 2],
              comments: ["The bench by the brick wall stays shaded in late afternoon."], isNearby: false),
        .init(id: "museum", name: "City Gallery Foyer", address: "Bankside, London SE1",
              latitude: 51.5074, longitude: -0.0991, source: .community, environment: .indoors,
              type: .culture, features: [.airConditioning, .coolerIndoors], access: .free,
              seating: .available, distance: "14 min walk", presenceCount: 1,
              experienceReports: [.notCooler: 1, .aLittleCooler: 3, .muchCooler: 9],
              latestReportAt: .now.addingTimeInterval(-10_800),
              stayReports: [.under30: 2, .under60: 3, .under120: 1], comments: [], isNearby: false)
    ]

    static let places: [RecognisedPlace] = [
        .init(id: "cafe", name: "Riverside Café", address: "Borough High Street, London SE1",
              latitude: 51.5052, longitude: -0.0916, type: .food, distance: "2 min walk"),
        .init(id: "market", name: "Market Street Supermarket", address: "Southwark Street, London SE1",
              latitude: 51.5056, longitude: -0.0924, type: .shop, distance: "3 min walk")
    ]

    static let saved: [SavedLocation] = [
        .init(id: UUID(), title: "Shade near the river", subtitle: "Near Queen’s Walk · SE1",
              savedAt: .now.addingTimeInterval(-7_200), latitude: 51.5062, longitude: -0.0889,
              kind: .coordinate, note: "Try the bench behind the wall.")
    ]

    static let contributions: [Contribution] = [
        .init(id: UUID(), title: "Community Hall", kind: .placeUpdate,
              status: .actionNeeded("Please move the pin closer to the public entrance."),
              createdAt: .now.addingTimeInterval(-86_400)),
        .init(id: UUID(), title: "Courtyard drinking fountain", kind: .newPlace,
              status: .merged("Riverside Courtyard"), createdAt: .now.addingTimeInterval(-172_800))
    ]
}
