import MapKit
import SwiftUI
import CryptoKit

@MainActor
final class PlaceSearchModel: ObservableObject {
    enum State { case idle, loading, loaded, failed }
    @Published private(set) var state = State.idle
    @Published private(set) var places: [RecognisedPlace] = []
    typealias Search = (String, MKCoordinateRegion, @escaping (Result<[RecognisedPlace], Error>) -> Void) -> () -> Void
    typealias Schedule = (@escaping () -> Void) -> () -> Void
    private let search: Search
    private let schedule: Schedule
    private var cancelRequest: (() -> Void)?
    private var cancelDelay: (() -> Void)?
    private var requestID = UUID()

    init(schedule: @escaping Schedule = PlaceSearchModel.debounce,
         search: @escaping Search = MapKitPlaceSearch.search) {
        self.search = search
        self.schedule = schedule
    }

    func update(query: String, region: MKCoordinateRegion, debounce: Bool = true) {
        cancel()
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        state = .loading
        let id = requestID
        if debounce {
            cancelDelay = schedule { [weak self] in
                guard let self, self.requestID == id else { return }
                self.start(query: query, region: region, id: id)
            }
        } else {
            start(query: query, region: region, id: id)
        }
    }

    private func start(query: String, region: MKCoordinateRegion, id: UUID) {
        cancelRequest = search(query, region) { [weak self] result in
            guard let self, self.requestID == id else { return }
            switch result {
            case .success(let places): self.places = places; self.state = .loaded
            case .failure: self.state = .failed
            }
        }
    }

    func cancel() {
        requestID = UUID()
        cancelDelay?()
        cancelDelay = nil
        cancelRequest?()
        cancelRequest = nil
        places = []
        state = .idle
    }

    deinit {
        cancelDelay?()
        cancelRequest?()
    }

    nonisolated private static func debounce(_ action: @escaping () -> Void) -> () -> Void {
        let task = Task { @MainActor in
            do { try await Task.sleep(for: .milliseconds(350)) } catch { return }
            action()
        }
        return { task.cancel() }
    }
}

enum MapKitPlaceSearch {
    static func request(query: String, region: MKCoordinateRegion) -> MKLocalSearch.Request {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        request.resultTypes = [.address, .pointOfInterest]
        return request
    }

    static func search(query: String, region: MKCoordinateRegion,
                       completion: @escaping (Result<[RecognisedPlace], Error>) -> Void) -> () -> Void {
        let search = MKLocalSearch(request: request(query: query, region: region))
        search.start { response, error in
            Task { @MainActor in
                completion(result(items: response?.mapItems, error: error))
            }
        }
        return { search.cancel() }
    }

    static func result(items: [MKMapItem]?, error: Error?) -> Result<[RecognisedPlace], Error> {
        if let error {
            let error = error as NSError
            if error.domain == MKErrorDomain && error.code == MKError.placemarkNotFound.rawValue {
                return .success([])
            }
            return .failure(error)
        }
        guard let items else { return .failure(MKError(.unknown)) }
        return .success(PlaceSearchResults.unique(items.compactMap(RecognisedPlace.init(mapItem:))))
    }
}

enum PlaceSearchResults {
    static func unique(_ places: [RecognisedPlace]) -> [RecognisedPlace] {
        var ids = Set<String>()
        return places.filter { ids.insert($0.id).inserted }
    }

    static func matching(_ places: [RecognisedPlace], query: String) -> [RecognisedPlace] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return places.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.address.localizedCaseInsensitiveContains(query) ||
            $0.type.rawValue.localizedCaseInsensitiveContains(query)
        }
    }
}

extension RecognisedPlace {
    init?(mapItem: MKMapItem) {
        let placemark = mapItem.placemark
        let coordinate = placemark.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate),
              let name = (mapItem.name ?? placemark.name)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else { return nil }
        let street = [placemark.subThoroughfare, placemark.thoroughfare].compactMap { $0 }.joined(separator: " ")
        let parts = [street, placemark.locality, placemark.postalCode, placemark.country]
            .compactMap { $0 }.filter { !$0.isEmpty }
        let address = parts.isEmpty ? (placemark.title ?? name) : parts.joined(separator: ", ")
        let type: PlaceType?
        let category: String?
        switch mapItem.pointOfInterestCategory {
        case .library: (type, category) = (.library, "Library")
        case .school: (type, category) = (.library, "School")
        case .university: (type, category) = (.library, "University")
        case .museum: (type, category) = (.culture, "Museum")
        case .theater: (type, category) = (.culture, "Theatre")
        case .cafe: (type, category) = (.food, "Café")
        case .bakery: (type, category) = (.food, "Bakery")
        case .restaurant: (type, category) = (.food, "Restaurant")
        case .brewery: (type, category) = (.food, "Brewery")
        case .winery: (type, category) = (.food, "Winery")
        case .store: (type, category) = (.shop, "Shop")
        case .foodMarket: (type, category) = (.shop, "Food market")
        case .park: (type, category) = (.park, "Park")
        case .nationalPark: (type, category) = (.park, "National park")
        case .beach: (type, category) = (.waterside, "Beach")
        case .marina: (type, category) = (.waterside, "Marina")
        case .airport: (type, category) = (.transport, "Airport")
        case .publicTransport: (type, category) = (.transport, "Public transport")
        case .fitnessCenter: (type, category) = (.leisure, "Fitness centre")
        case .stadium: (type, category) = (.leisure, "Stadium")
        default: (type, category) = (nil, nil)
        }
        let id: String
        if let identifier = mapItem.identifier {
            id = "apple-maps:\(identifier.rawValue)"
        } else {
            // Addresses can lack a Place ID. Avoid random IDs and process-randomized hashes.
            let identity = "\(name.lowercased())|\(coordinate.latitude)|\(coordinate.longitude)"
            let digest = SHA256.hash(data: Data(identity.utf8)).map { String(format: "%02x", $0) }.joined()
            id = "apple-maps:coordinate:\(digest)"
        }
        self.init(id: id, name: name, address: address, latitude: coordinate.latitude,
                  longitude: coordinate.longitude, type: type ?? .other, distance: "",
                  hasTrustedType: type != nil, sourceCategory: category,
                  phoneNumber: mapItem.phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines),
                  websiteURL: mapItem.url.flatMap { ["http", "https"].contains($0.scheme?.lowercased() ?? "") ? $0 : nil })
    }

    var searchSubtitle: String {
        id.hasPrefix("apple-maps:") ? address : "Example place · \(address)"
    }

    var categoryLabel: String? {
        sourceCategory ?? (hasTrustedType ? type.shortName : nil)
    }

    var appleMapItemIdentifier: MKMapItem.Identifier? {
        let prefix = "apple-maps:"
        guard id.hasPrefix(prefix), !id.hasPrefix("\(prefix)coordinate:") else { return nil }
        return MKMapItem.Identifier(rawValue: String(id.dropFirst(prefix.count)))
    }

    var phoneURL: URL? {
        guard let phoneNumber else { return nil }
        let number = phoneNumber.filter { $0.isASCII && ($0.isNumber || $0 == "+") }
        guard number.contains(where: \.isNumber) else { return nil }
        return URL(string: "tel:\(number)")
    }
}

struct PlaceSearchStatus: View {
    let state: PlaceSearchModel.State
    let retry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            HStack(spacing: 10) {
                ProgressView()
                Text("Searching places…").font(.subheadline)
            }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        case .failed:
            VStack(alignment: .leading, spacing: 6) {
                Text("Couldn’t search places").font(.headline)
                Text("Check your connection or try again in a moment.")
                    .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                Button("Try again", action: retry).frame(minHeight: 44)
            }
        case .idle, .loaded:
            EmptyView()
        }
    }
}
