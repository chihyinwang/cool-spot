import CoreLocation
import SwiftUI
import UIKit

// THROWAWAY PROTOTYPE
// Question: can people distinguish discovering, privately saving, visiting,
// and contributing reviewed public cooling information?

enum AppStyle {
    // A fixed dark fill used only when the foreground is explicitly white.
    static let ink = Color(red: 0.05, green: 0.25, blue: 0.28)
    // Brand-coloured foreground that remains legible on system backgrounds.
    static let brand = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.56, green: 0.88, blue: 0.82, alpha: 1)
            : UIColor(red: 0.05, green: 0.25, blue: 0.28, alpha: 1)
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
}

enum PlaceEnvironment: String, CaseIterable, Identifiable {
    case indoors = "Indoors"
    case outdoors = "Outdoors"
    case both = "Both"
    var id: String { rawValue }
}

enum PlaceType: String, CaseIterable, Identifiable, Hashable {
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
        case .other: "mappin"
        }
    }
}

enum CoolingFeature: String, CaseIterable, Identifiable, Hashable {
    case airConditioning = "Air conditioning"
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
        case .coolerIndoors: "house.fill"
        case .treeShade: "tree.fill"
        case .structuralShade: "umbrella.fill"
        case .drinkingWater: "waterbottle.fill"
        case .waterFeature: "water.waves"
        case .ventilation: "wind"
        }
    }
}

enum AccessType: String, CaseIterable, Identifiable {
    case free = "Free to enter"
    case purchase = "Purchase expected"
    case ticket = "Ticket required"
    case unsure = "Not sure"
    var id: String { rawValue }
}

enum SeatingType: String, CaseIterable, Identifiable {
    case available = "Seating available"
    case limited = "Limited seating"
    case none = "No seating"
    case unsure = "Not sure"
    var id: String { rawValue }
}

enum StayLength: String, CaseIterable, Identifiable {
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
    let presenceCount: Int
    let coolReports: Int
    let notCoolReports: Int
    let stayReports: [StayLength: Int]
    let comments: [String]
    let isNearby: Bool
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

struct RecognisedPlace: Identifiable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let type: PlaceType
    let distance: String
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

enum SavedLocationKind: Equatable {
    case coolSpot(String)
    case recognisedPlace(String)
    case coordinate
}

struct SavedLocation: Identifiable {
    let id: UUID
    var title: String
    let subtitle: String
    let savedAt: Date
    let latitude: Double
    let longitude: Double
    let kind: SavedLocationKind
    var note: String
}

enum ContributionKind: String {
    case newPlace = "New Cool Spot"
    case placeUpdate = "Place details"
    case visitReport = "Past visit"
}

enum ContributionStatus: Equatable {
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

struct Contribution: Identifiable {
    let id: UUID
    let title: String
    let kind: ContributionKind
    var status: ContributionStatus
    let createdAt: Date
}

struct VisitReport: Identifiable {
    let id: UUID
    let spotID: String
    let foundCool: Bool
    let stayLength: StayLength?
    let comment: String
}

@MainActor
final class PrototypeStore: ObservableObject {
    @Published var spots = Fixtures.spots
    @Published var savedLocations = Fixtures.saved
    @Published var contributions = Fixtures.contributions
    @Published var visitReports: [VisitReport] = []
    @Published var activePresenceSpotID: String?
    @Published var unlockedTypes: Set<PlaceType> = [.library, .park]
    @Published var isSignedIn = false

    let recognisedPlaces = Fixtures.places
    let currentCoordinate = CLLocationCoordinate2D(latitude: 51.5059, longitude: -0.0906)

    func spot(_ id: String) -> CoolSpot? { spots.first { $0.id == id } }
    func place(_ id: String) -> RecognisedPlace? { recognisedPlaces.first { $0.id == id } }
    func isSaved(spotID: String) -> Bool { savedLocations.contains { $0.kind == .coolSpot(spotID) } }
    func isSaved(placeID: String) -> Bool { savedLocations.contains { $0.kind == .recognisedPlace(placeID) } }

    @discardableResult func toggleSaved(_ spot: CoolSpot) -> Bool {
        if let index = savedLocations.firstIndex(where: { $0.kind == .coolSpot(spot.id) }) {
            savedLocations.remove(at: index); return false
        }
        savedLocations.insert(.init(id: UUID(), title: spot.name, subtitle: spot.address, savedAt: .now,
                                    latitude: spot.latitude, longitude: spot.longitude,
                                    kind: .coolSpot(spot.id), note: ""), at: 0)
        return true
    }

    @discardableResult func toggleSaved(_ place: RecognisedPlace) -> Bool {
        if let index = savedLocations.firstIndex(where: { $0.kind == .recognisedPlace(place.id) }) {
            savedLocations.remove(at: index); return false
        }
        savedLocations.insert(.init(id: UUID(), title: place.name, subtitle: place.address, savedAt: .now,
                                    latitude: place.latitude, longitude: place.longitude,
                                    kind: .recognisedPlace(place.id), note: ""), at: 0)
        return true
    }

    @discardableResult func saveCurrentLocation() -> SavedLocation {
        let saved = SavedLocation(id: UUID(), title: "Saved location", subtitle: "Near Southwark Street · SE1",
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

    func presence(for spot: CoolSpot) -> Int {
        spot.presenceCount + (activePresenceSpotID == spot.id ? 1 : 0)
    }

    func checkIn(_ spot: CoolSpot) {
        guard spot.isNearby else { return }
        activePresenceSpotID = spot.id
        unlockedTypes.insert(spot.type)
    }

    func submitContribution(title: String, kind: ContributionKind) {
        contributions.insert(.init(id: UUID(), title: title, kind: kind, status: .inReview, createdAt: .now), at: 0)
    }

    func submitReport(spot: CoolSpot, foundCool: Bool, stay: StayLength?, comment: String) {
        visitReports.insert(.init(id: UUID(), spotID: spot.id, foundCool: foundCool,
                                  stayLength: stay, comment: comment), at: 0)
        contributions.insert(.init(id: UUID(), title: spot.name, kind: .visitReport,
                                   status: .published, createdAt: .now), at: 0)
    }

    func reportCounts(for spot: CoolSpot) -> (Int, Int) {
        let reports = visitReports.filter { $0.spotID == spot.id }
        return (spot.coolReports + reports.filter(\.foundCool).count,
                spot.notCoolReports + reports.filter { !$0.foundCool }.count)
    }

    func comments(for spot: CoolSpot) -> [String] {
        visitReports.filter { $0.spotID == spot.id && !$0.comment.isEmpty }.map(\.comment) + spot.comments
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
        contributions[index].status = status
    }
}

enum Fixtures {
    static let spots: [CoolSpot] = [
        .init(id: "library", name: "Riverside Library", address: "Tooley Street, London SE1",
              latitude: 51.5045, longitude: -0.0865, source: .gla, environment: .indoors,
              type: .library, features: [.coolerIndoors, .ventilation, .drinkingWater],
              access: .free, seating: .available, distance: "6 min walk", presenceCount: 2,
              coolReports: 18, notCoolReports: 3,
              stayReports: [.under30: 1, .under60: 4, .under120: 7, .over120: 2],
              comments: ["Quiet upstairs, with tables away from the windows."], isNearby: true),
        .init(id: "shade", name: "Shade beside the playground", address: "Mint Street Park, London SE1",
              latitude: 51.5030, longitude: -0.0982, source: .community, environment: .outdoors,
              type: .park, features: [.treeShade, .drinkingWater], access: .free,
              seating: .limited, distance: "11 min walk", presenceCount: 0,
              coolReports: 9, notCoolReports: 5,
              stayReports: [.under15: 2, .under30: 5, .under60: 2],
              comments: ["The bench by the brick wall stays shaded in late afternoon."], isNearby: false),
        .init(id: "museum", name: "City Gallery Foyer", address: "Bankside, London SE1",
              latitude: 51.5074, longitude: -0.0991, source: .community, environment: .indoors,
              type: .culture, features: [.airConditioning, .coolerIndoors], access: .free,
              seating: .available, distance: "14 min walk", presenceCount: 1,
              coolReports: 12, notCoolReports: 1,
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
