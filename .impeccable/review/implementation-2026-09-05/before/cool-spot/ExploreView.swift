import MapKit
import SwiftUI

enum ExploreSelection: Identifiable {
    case coolSpot(String)
    case recognisedPlace(String)
    var id: String {
        switch self {
        case .coolSpot(let id): "cool-\(id)"
        case .recognisedPlace(let id): "place-\(id)"
        }
    }
}

enum ExploreFilter: String, Identifiable {
    case nearby, indoor, shade, airConditioning, free, water
    var id: String { rawValue }
    static let visible: [ExploreFilter] = [.indoor, .shade, .airConditioning, .free, .water]
    var title: String {
        switch self {
        case .nearby: "Nearby"
        case .indoor: "Indoor"
        case .shade: "Outdoor shade"
        case .airConditioning: "AC"
        case .free: "Free"
        case .water: "Water"
        }
    }
    var symbol: String {
        switch self {
        case .nearby: "location.fill"
        case .indoor: "house.fill"
        case .shade: "tree.fill"
        case .airConditioning: "snowflake"
        case .free: "sterlingsign.circle.fill"
        case .water: "drop.fill"
        }
    }
}

enum LocationRequestPurpose: Equatable {
    case nearby
    case saveCurrentLocation
}

struct ExploreView: View {
    @ObservedObject var store: PrototypeStore
    @State private var camera: MapCameraPosition = .region(.init(
        center: .init(latitude: 51.5052, longitude: -0.0920),
        span: .init(latitudeDelta: 0.035, longitudeDelta: 0.035)))
    @State private var search = ""
    @State private var filter: ExploreFilter?
    @State private var selection: ExploreSelection?
    @State private var showSearchArea = false
    @State private var showLocationExplanation = false
    @State private var showContribution = false
    @State private var showSavedToast = false
    @State private var showSaveConfirmation = false
    @State private var hasLocationAccess = false
    @State private var locationRequestPurpose: LocationRequestPurpose = .nearby
    @State private var lastSavedLocation: SavedLocation?
    @State private var savedDetail: SavedLocation?
    @State private var acceptMapMovementAfter = Date.distantFuture

    var filteredSpots: [CoolSpot] {
        store.spots.filter { spot in
            switch filter {
            case .indoor: spot.environment != .outdoors
            case .shade: spot.features.contains(.treeShade) || spot.features.contains(.structuralShade)
            case .airConditioning: spot.features.contains(.airConditioning)
            case .free: spot.access == .free
            case .water: spot.features.contains(.drinkingWater) || spot.features.contains(.waterFeature)
            case nil, .nearby: true
            }
        }
    }

    var searchedSpots: [CoolSpot] {
        guard !search.isEmpty else { return [] }
        return store.spots.filter { $0.name.localizedCaseInsensitiveContains(search) ||
            $0.type.rawValue.localizedCaseInsensitiveContains(search) }
    }

    var searchedPlaces: [RecognisedPlace] {
        guard !search.isEmpty else { return [] }
        let matches = store.recognisedPlaces.filter { $0.name.localizedCaseInsensitiveContains(search) ||
            $0.type.rawValue.localizedCaseInsensitiveContains(search) }
        return matches.isEmpty ? store.recognisedPlaces : matches
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $camera) {
                    if hasLocationAccess {
                        Annotation("Your location", coordinate: store.currentCoordinate) {
                            CurrentLocationMarker()
                        }
                    }
                    ForEach(filteredSpots) { spot in
                        Annotation(spot.name, coordinate: spot.coordinate, anchor: .bottom) {
                            Button { selection = .coolSpot(spot.id) } label: {
                                CoolSpotPin(type: spot.type, isGLA: spot.source == .gla,
                                            count: store.presence(for: spot))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat, emphasis: .muted,
                                    pointsOfInterest: .excludingAll))
                .onMapCameraChange(frequency: .onEnd) { _ in
                    if Date.now >= acceptMapMovementAfter { showSearchArea = true }
                }
                .task {
                    try? await Task.sleep(for: .seconds(1.25))
                    acceptMapMovementAfter = .now
                }
                .ignoresSafeArea(edges: .top)

                VStack(spacing: 10) {
                    SearchBar(text: $search)
                    filterBar

                    if !search.isEmpty {
                        SearchResultsPanel(coolSpots: searchedSpots, places: searchedPlaces,
                                           chooseSpot: { selection = .coolSpot($0.id) },
                                           choosePlace: { selection = .recognisedPlace($0.id) })
                            .padding(.horizontal, 16)
                    } else if showSearchArea {
                        Button { showSearchArea = false } label: {
                            Label("Search this area", systemImage: "arrow.clockwise")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(.regularMaterial, in: Capsule())
                                .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                    if showSaveConfirmation {
                        CurrentLocationSavePrompt {
                            withAnimation { showSaveConfirmation = false }
                        } save: {
                            let saved = store.saveCurrentLocation()
                            lastSavedLocation = saved
                            withAnimation {
                                showSaveConfirmation = false
                                showSavedToast = true
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    HStack {
                        Spacer()
                        Menu {
                            Button {
                                requestLocation(for: .saveCurrentLocation)
                            } label: { Label("Save a pin here", systemImage: "mappin.and.ellipse") }
                            Button { showContribution = true } label: {
                                Label("Add cooling information", systemImage: "plus.bubble.fill")
                            }
                        } label: {
                            Image(systemName: "plus").font(.title2.bold()).foregroundStyle(.white)
                                .frame(width: 54, height: 54).background(AppStyle.ink, in: Circle())
                                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                        }
                        .accessibilityLabel("Save or contribute")
                    }
                    .padding(.horizontal, 16)
                    NearbyPanel(spots: filteredSpots) { selection = .coolSpot($0.id) }
                }
                .padding(.top, 8)

                if showSavedToast {
                    SavedToast {
                        if let lastSavedLocation { savedDetail = lastSavedLocation }
                        withAnimation { showSavedToast = false }
                    }
                        .padding(.horizontal, 16).padding(.top, 132)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .task {
                            try? await Task.sleep(for: .seconds(3))
                            withAnimation { showSavedToast = false }
                        }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .alert("Use your current location?", isPresented: $showLocationExplanation) {
            Button("Not now", role: .cancel) {}
            Button("Continue") {
                hasLocationAccess = true
                filter = .nearby
                showSearchArea = false
                acceptMapMovementAfter = .now.addingTimeInterval(1)
                camera = .region(.init(center: store.currentCoordinate,
                                       span: .init(latitudeDelta: 0.018, longitudeDelta: 0.018)))
                if locationRequestPurpose == .saveCurrentLocation {
                    filter = nil
                    withAnimation { showSaveConfirmation = true }
                }
            }
        } message: {
            Text(locationRequestPurpose == .saveCurrentLocation
                 ? "Cool Spot uses your location to show the point before you save it. The estimated accuracy is also shown."
                 : "Cool Spot uses your location only when you ask for nearby places or check in. You can still search without it.")
        }
        .sheet(item: $selection) { item in
            switch item {
            case .coolSpot(let id):
                if let spot = store.spot(id) { CoolSpotDetailView(store: store, spot: spot) }
            case .recognisedPlace(let id):
                if let place = store.place(id) { RecognisedPlaceDetailView(store: store, place: place) }
            }
        }
        .sheet(isPresented: $showContribution) {
            ContributionFlow(store: store, source: .currentLocation)
        }
        .sheet(item: $savedDetail) { saved in
            SavedDetail(store: store, savedID: saved.id)
        }
    }

    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "Nearby", symbol: "location.fill", selected: filter == .nearby) {
                    requestLocation(for: .nearby)
                }
                ForEach(ExploreFilter.visible) { item in
                    FilterChip(title: item.title, symbol: item.symbol, selected: filter == item) {
                        filter = filter == item ? nil : item
                    }
                }
                FilterChip(title: "More", symbol: "slider.horizontal.3", selected: false) {}
            }
            .padding(.horizontal, 16)
        }
    }

    func requestLocation(for purpose: LocationRequestPurpose) {
        locationRequestPurpose = purpose
        if hasLocationAccess {
            showSearchArea = false
            acceptMapMovementAfter = .now.addingTimeInterval(1)
            camera = .region(.init(center: store.currentCoordinate,
                                   span: .init(latitudeDelta: 0.018, longitudeDelta: 0.018)))
            if purpose == .nearby {
                filter = .nearby
            } else {
                withAnimation { showSaveConfirmation = true }
            }
        } else {
            showLocationExplanation = true
        }
    }
}

struct CurrentLocationMarker: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.blue.opacity(0.18)).frame(width: 48, height: 48)
            Circle().fill(.blue).frame(width: 18, height: 18)
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.22), radius: 3, y: 1)
        }
        .accessibilityLabel("Your current location")
    }
}

struct CurrentLocationSavePrompt: View {
    let cancel: () -> Void
    let save: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "location.fill").foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Save a pin here?").font(.headline)
                    Text("Find this point again in Saved → Pins. Only you can see it; no report is started.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Prototype location · Near Southwark Street · Estimated accuracy 25 m")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            HStack {
                Button("Cancel", action: cancel).buttonStyle(.bordered)
                Spacer()
                Button("Save pin", action: save)
                    .buttonStyle(.borderedProminent).tint(AppStyle.ink)
            }
        }
        .padding(14)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct SearchBar: View {
    @Binding var text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("", text: $text,
                      prompt: Text("Search a place, landmark or postcode")
                        .foregroundStyle(Color.primary.opacity(0.74)))
                .textInputAutocapitalization(.words).submitLabel(.search)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16).frame(height: 50)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.16), radius: 10, y: 4).padding(.horizontal, 16)
    }
}

struct FilterChip: View {
    let title: String
    let symbol: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol).font(.caption.weight(.semibold))
                .foregroundStyle(selected ? .white : AppStyle.brand)
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(selected ? AppStyle.ink : AppStyle.controlSurface, in: Capsule())
                .overlay(Capsule().stroke(AppStyle.subtleBorder))
        }
        .buttonStyle(.plain)
    }
}

struct CoolSpotPin: View {
    let type: PlaceType
    let isGLA: Bool
    let count: Int
    var body: some View {
        VStack(spacing: 3) {
            if count > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<min(count, 3), id: \.self) { _ in
                        Circle().fill(AppStyle.sun).frame(width: 7, height: 7)
                    }
                }
                .padding(.horizontal, 6).padding(.vertical, 4).background(AppStyle.controlSurface, in: Capsule())
                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
            }
            ZStack(alignment: .topTrailing) {
                Image(systemName: type.symbol).font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 42, height: 42).background(AppStyle.ink, in: Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.24), radius: 4, y: 2)
                if isGLA {
                    Circle().fill(AppStyle.sun).frame(width: 13, height: 13)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }
        }
    }
}

struct SearchResultsPanel: View {
    let coolSpots: [CoolSpot]
    let places: [RecognisedPlace]
    let chooseSpot: (CoolSpot) -> Void
    let choosePlace: (RecognisedPlace) -> Void
    var body: some View {
        VStack(spacing: 0) {
            ForEach(coolSpots.prefix(2)) { spot in
                Button { chooseSpot(spot) } label: {
                    SearchResultRow(symbol: spot.type.symbol, title: spot.name,
                                    subtitle: "\(spot.source.rawValue) · \(spot.distance)", isCoolSpot: true)
                }.buttonStyle(.plain)
            }
            ForEach(places.prefix(2)) { place in
                Button { choosePlace(place) } label: {
                    SearchResultRow(symbol: place.type.symbol, title: place.name,
                                    subtitle: "Place result · \(place.distance)", isCoolSpot: false)
                }.buttonStyle(.plain)
            }
        }
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.16), radius: 12, y: 4)
    }
}

struct SearchResultRow: View {
    let symbol: String, title: String, subtitle: String
    let isCoolSpot: Bool
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(isCoolSpot ? .white : AppStyle.brand)
                .frame(width: 38, height: 38).background(isCoolSpot ? AppStyle.ink : AppStyle.blue, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
                if !isCoolSpot {
                    Text("No cooling information yet").font(.caption.weight(.medium)).foregroundStyle(.orange)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(12)
    }
}

struct NearbyPanel: View {
    let spots: [CoolSpot]
    let choose: (CoolSpot) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Capsule().fill(.tertiary).frame(width: 38, height: 5).frame(maxWidth: .infinity)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cool Spots nearby").font(.headline)
                    Text("Reviewed places only").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(spots.count) places").font(.caption.weight(.semibold)).foregroundStyle(AppStyle.brand)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(spots) { spot in
                        Button { choose(spot) } label: {
                            HStack(spacing: 10) {
                                Image(systemName: spot.type.symbol).foregroundStyle(.white)
                                    .frame(width: 34, height: 34).background(AppStyle.ink, in: Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(spot.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                                    Text("\(spot.distance) · \(spot.features.first?.rawValue ?? spot.type.shortName)")
                                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                            .padding(10).frame(width: 245, alignment: .leading)
                            .background(AppStyle.paper, in: RoundedRectangle(cornerRadius: 14))
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 9).padding(.bottom, 12)
        .background(.ultraThickMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 14, y: -2)
    }
}

struct SavedToast: View {
    let view: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bookmark.fill").foregroundStyle(AppStyle.brand)
            VStack(alignment: .leading, spacing: 2) {
                Text("Private pin saved").font(.subheadline.weight(.semibold))
                Text("Find it in Saved → Pins. Only you can see it.").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("View pin", action: view).font(.caption.weight(.bold)).frame(minHeight: 44)
        }
        .padding(14).background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.16), radius: 10, y: 4)
    }
}
