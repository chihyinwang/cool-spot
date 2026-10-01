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
    @Binding var nearbyPlaceRequest: RecognisedPlace?
    let catalogueState: CoolSpotsCatalogueViewModel.State?
    let retryCatalogue: () -> Void
    @State private var nearbyOrigin: RecognisedPlace?
    @State private var nearbyRadius: CLLocationDistance = 1_000
    @State private var camera: MapCameraPosition = .region(.init(
        center: .init(latitude: 51.5052, longitude: -0.0920),
        span: .init(latitudeDelta: 0.035, longitudeDelta: 0.035)))
    @State private var search = ""
    @State private var searchFocused = false
    @StateObject private var placeSearch = PlaceSearchModel()
    @State private var searchRegion = MKCoordinateRegion(
        center: .init(latitude: 51.5052, longitude: -0.0920),
        span: .init(latitudeDelta: 0.035, longitudeDelta: 0.035))
    @State private var filter: ExploreFilter?
    @State private var selection: ExploreSelection?
    @State private var focusedPlace: RecognisedPlace?
    @State private var detailDetent: PresentationDetent = .medium
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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

    init(store: PrototypeStore, nearbyPlaceRequest: Binding<RecognisedPlace?> = .constant(nil),
         catalogueState: CoolSpotsCatalogueViewModel.State? = nil,
         retryCatalogue: @escaping () -> Void = {}) {
        self.store = store
        _nearbyPlaceRequest = nearbyPlaceRequest
        self.catalogueState = catalogueState
        self.retryCatalogue = retryCatalogue
    }

    private var nearbyResults: [NearbyCoolSpotResult] {
        guard let origin = nearbyOrigin else { return [] }
        return NearbyCoolSpotResult.find(in: store.spots, around: origin.coordinate, radius: nearbyRadius)
    }

    var filteredSpots: [CoolSpot] {
        store.spots.filter { spot in
            switch filter {
            case .indoor: spot.environment == .indoors || spot.environment == .both
            case .shade: spot.features.contains(.treeShade) || spot.features.contains(.structuralShade)
            case .airConditioning: spot.features.contains(.airConditioning)
            case .free: spot.access == .free
            case .water: spot.features.contains(.drinkingWater) || spot.features.contains(.waterFeature)
            case nil, .nearby: true
            }
        }
    }

    var searchedSpots: [CoolSpot] {
        guard !query.isEmpty else { return [] }
        return store.searchCoolSpots(query: query, including: placeSearch.places)
    }

    private var mapSpots: [CoolSpot] {
        if nearbyOrigin != nil { return nearbyResults.map(\.spot) }
        guard case .coolSpot(let id) = selection,
              !filteredSpots.contains(where: { $0.id == id }), let spot = store.spot(id) else { return filteredSpots }
        return filteredSpots + [spot]
    }

    var searchedPlaces: [RecognisedPlace] {
        PlaceSearchResults.unique(placeSearch.places + PlaceSearchResults.matching(store.recognisedPlaces, query: query))
            .filter { store.existingSpot(for: $0) == nil }
    }

    var query: String { search.trimmingCharacters(in: .whitespacesAndNewlines) }

    func searchPlaces(debounce: Bool = true) {
        placeSearch.update(query: query, region: searchRegion, debounce: debounce)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
            ZStack(alignment: .top) {
                Map(position: $camera) {
                    if hasLocationAccess {
                        Annotation("Your location", coordinate: store.currentCoordinate) {
                            CurrentLocationMarker()
                        }
                    }
                    ForEach(mapSpots) { spot in
                        Annotation(spot.name, coordinate: spot.coordinate, anchor: .bottom) {
                            Button { select(spot) } label: {
                                CoolSpotPin(type: spot.type,
                                            count: store.presence(for: spot))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if let place = focusedPlace {
                        Annotation(place.name, coordinate: place.coordinate, anchor: .bottom) {
                            Button {
                                if nearbyOrigin != nil { returnToOrigin() }
                                else { select(place) }
                            } label: {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white, nearbyOrigin == nil ? AppStyle.brand : .gray)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open \(place.name)")
                        }
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if selection != nil || nearbyOrigin != nil {
                        Color.clear.frame(height: geometry.size.height * 0.5)
                    }
                }
                .mapStyle(.standard(elevation: .flat, emphasis: .muted,
                                    pointsOfInterest: .excludingAll))
                .onMapCameraChange(frequency: .onEnd) { context in
                    searchRegion = context.region
                    if nearbyOrigin == nil, Date.now >= acceptMapMovementAfter { showSearchArea = true }
                }
                .task {
                    try? await Task.sleep(for: .seconds(1.25))
                    acceptMapMovementAfter = .now
                }
                .ignoresSafeArea(edges: .top)

                if selection == nil {
                if let origin = nearbyOrigin {
                    VStack {
                        Button(action: returnToOrigin) {
                            Label("Back to \(origin.name)", systemImage: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .padding(.horizontal, 14)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        Spacer()
                        NearbyCoolSpotsPanel(origin: origin, results: nearbyResults, radius: nearbyRadius,
                                             expand: expandNearbyArea, choose: { select($0) })
                            .frame(maxHeight: geometry.size.height * 0.48)
                    }
                    .padding(.top, 8)
                } else {
                VStack(spacing: 10) {
                    SearchBar(text: $search, submit: { searchPlaces(debounce: false) },
                              focusChanged: { searchFocused = $0 })
                    filterBar
                    catalogueStatus
                    if let message = store.coolSpotsLoadError {
                        Text(message).font(.subheadline).padding(12).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    if !query.isEmpty {
                        SearchResultsPanel(query: query, coolSpots: searchedSpots, places: searchedPlaces,
                                           state: placeSearch.state,
                                           retry: { searchPlaces(debounce: false) },
                                           chooseSpot: { select($0) },
                                           choosePlace: { select($0) },
                                           addLocation: { showContribution = true })
                            .padding(.horizontal, 16)
                    } else if showSearchArea {
                        Button { showSearchArea = false } label: {
                            Label("Search this area", systemImage: "arrow.clockwise")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16).padding(.vertical, LayoutSpacing.related)
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
                    if !searchFocused || query.isEmpty {
                        if showsCataloguePanel {
                            NearbyPanel(spots: filteredSpots) { select($0) }
                        }
                    }
                }
                .padding(.top, 8)
                }
                }

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
        }
        .onAppear {
            searchPlaces()
            receiveNearbyRequest()
        }
        .onChange(of: nearbyPlaceRequest?.id) { _, _ in receiveNearbyRequest() }
        .onChange(of: search) { _, _ in
            if nearbyOrigin == nil { searchPlaces() }
        }
        .onDisappear { placeSearch.cancel() }
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
        .sheet(item: $selection, onDismiss: {
            if nearbyOrigin != nil { focusNearbyArea() }
        }) { item in
            Group {
            switch item {
            case .coolSpot(let id):
                if let spot = store.spot(id) {
                    CoolSpotDetailView(store: store, spot: spot, distanceContext: nearbyDistanceContext(for: id))
                }
            case .recognisedPlace(let id):
                if let place = store.place(id) {
                    RecognisedPlaceDetailView(store: store, place: place, findNearby: { startNearby(place) })
                }
            }
            }
            .presentationDetents([.medium, .large], selection: $detailDetent)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .presentationContentInteraction(.resizes)
        }
        .sheet(isPresented: $showContribution) {
            ContributionFlow(store: store, source: .currentLocation)
        }
        .sheet(item: $savedDetail) { saved in
            SavedDetail(store: store, savedID: saved.id)
        }
    }

    private var showsCataloguePanel: Bool {
        guard let catalogueState else { return true }
        if case let .loaded(spots) = catalogueState { return !spots.isEmpty }
        return false
    }

    @ViewBuilder private var catalogueStatus: some View {
        switch catalogueState {
        case .idle?, .loading?:
            HStack(spacing: 10) {
                ProgressView()
                Text("Loading Cool Spots…")
            }
            .font(.subheadline)
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        case .failed?:
            VStack(spacing: 8) {
                Text("Couldn’t load Cool Spots")
                Button("Try again", action: retryCatalogue)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        case let .loaded(spots)? where spots.isEmpty:
            Text("No Cool Spots available")
                .font(.subheadline)
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        default:
            EmptyView()
        }
    }

    private func select(_ spot: CoolSpot) {
        focusedPlace = nearbyOrigin
        focusMap(on: spot.coordinate)
        selection = .coolSpot(spot.id)
    }

    private func select(_ place: RecognisedPlace) {
        if let spot = store.existingSpot(for: place) { select(spot); return }
        store.remember(place)
        focusedPlace = place
        focusMap(on: place.coordinate)
        selection = .recognisedPlace(place.id)
    }

    private func receiveNearbyRequest() {
        guard let place = nearbyPlaceRequest else { return }
        nearbyPlaceRequest = nil
        search = place.name
        startNearby(place)
    }

    private func startNearby(_ place: RecognisedPlace) {
        store.remember(place)
        nearbyOrigin = place
        nearbyRadius = 1_000
        focusedPlace = place
        selection = nil
        searchFocused = false
        placeSearch.cancel()
        focusNearbyArea()
    }

    private func returnToOrigin() {
        guard let place = nearbyOrigin else { return }
        nearbyOrigin = nil
        select(place)
        searchPlaces(debounce: false)
    }

    private func expandNearbyArea() {
        nearbyRadius = nearbyRadius < 3_000 ? 3_000 : min(nearbyRadius * 2, 25_000)
        focusNearbyArea()
    }

    private func focusNearbyArea() {
        guard let origin = nearbyOrigin else { return }
        showSearchArea = false
        acceptMapMovementAfter = .now.addingTimeInterval(1)
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
            camera = .region(MKCoordinateRegion(center: origin.coordinate,
                                                latitudinalMeters: nearbyRadius * 2.4,
                                                longitudinalMeters: nearbyRadius * 2.4))
        }
    }

    private func focusMap(on coordinate: CLLocationCoordinate2D) {
        detailDetent = .medium
        searchFocused = false
        showSearchArea = false
        acceptMapMovementAfter = .now.addingTimeInterval(1)
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
            camera = .region(.init(center: coordinate,
                                   span: .init(latitudeDelta: 0.008, longitudeDelta: 0.008)))
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

    private func nearbyDistanceContext(for id: String) -> String? {
        guard let origin = nearbyOrigin,
              let result = nearbyResults.first(where: { $0.id == id }) else { return nil }
        return "\(result.distanceLabel) from \(origin.name) (straight-line)"
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

struct NearbyCoolSpotResult: Identifiable {
    let spot: CoolSpot
    let distance: CLLocationDistance
    var id: String { spot.id }
    var distanceLabel: String {
        if distance < 1_000 { return "\(Int((distance / 10).rounded()) * 10) m" }
        return String(format: "%.1f km", distance / 1_000)
    }

    static func find(in spots: [CoolSpot], around coordinate: CLLocationCoordinate2D,
                     radius: CLLocationDistance) -> [Self] {
        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return spots.map { spot in
            Self(spot: spot, distance: origin.distance(from: CLLocation(latitude: spot.latitude,
                                                                        longitude: spot.longitude)))
        }
        .filter { $0.distance <= radius }
        .sorted { $0.distance == $1.distance ? $0.id < $1.id : $0.distance < $1.distance }
    }
}

private struct NearbyCoolSpotsPanel: View {
    let origin: RecognisedPlace
    let results: [NearbyCoolSpotResult]
    let radius: CLLocationDistance
    let expand: () -> Void
    let choose: (CoolSpot) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                    Text("Nearby Cool Spots").font(.title3.bold())
                    Text("Near \(origin.name)").font(.subheadline)
                    Text("Within \(Int(radius / 1_000)) km · Straight-line distance")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if results.isEmpty {
                    Text("No Cool Spots found nearby").font(.headline).padding(.top, 8)
                    Text("Try a wider area.")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    ForEach(results) { result in
                        Button { choose(result.spot) } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                                    Text(result.spot.name).font(.headline)
                                    Text("\(result.distanceLabel) from \(origin.name)")
                                        .font(.caption).foregroundStyle(.secondary)
                                    Text([result.spot.features.first?.rawValue, result.spot.access.summary]
                                        .compactMap { $0 }.joined(separator: " · "))
                                        .font(.subheadline)
                                    Text(result.spot.sourceLabel).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .padding(.vertical, LayoutSpacing.related)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
                if radius < 25_000 {
                    Button("Search a wider area", action: expand)
                        .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .padding(.bottom, 60)
        }
        .background(.regularMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
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
            HStack(spacing: LayoutSpacing.related) {
                Image(systemName: "location.fill").foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                    Text("Save a pin here?").font(.headline)
                    Text("Save to your private pins")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Example location · Southwark Street")
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
    var submit: () -> Void = {}
    var focusChanged: (Bool) -> Void = { _ in }
    @FocusState private var isFocused: Bool
    var body: some View {
        HStack(spacing: LayoutSpacing.related) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("", text: $text,
                      prompt: Text("Search a place, landmark or postcode")
                        .foregroundStyle(Color.primary.opacity(0.74)))
                .textInputAutocapitalization(.words).submitLabel(.search)
                .autocorrectionDisabled()
                .accessibilityLabel("Search places")
                .focused($isFocused)
                .onChange(of: isFocused) { _, focused in focusChanged(focused) }
                .onSubmit { isFocused = false; submit() }
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Clear search")
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
                .frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct CoolSpotPin: View {
    let type: PlaceType
    let count: Int
    var arrivalPhase: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var diameter = 42.0
    @ScaledMetric(relativeTo: .caption) private var badgeSpace = 32.0
    var body: some View {
        VStack(spacing: 4) {
            if count > 0 {
                Label("\(count)", systemImage: "person.fill")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 7).padding(.vertical, 4)
                    .background(AppStyle.controlSurface, in: Capsule())
                    .overlay(Capsule().stroke(AppStyle.subtleBorder))
                    .fixedSize()
                    .contentTransition(.numericText())
                    .scaleEffect(reduceMotion ? 1 : arrivalPhase == 1 ? 1.18 : arrivalPhase == 2 ? 1.06 : 1)
                    .rotationEffect(.degrees(reduceMotion ? 0 : arrivalPhase == 1 ? -5 : arrivalPhase == 2 ? 4 : 0))
                    .offset(y: reduceMotion ? 0 : arrivalPhase == 1 ? -3 : arrivalPhase == 2 ? -1 : 0)
                    .animation(reduceMotion ? nil : .spring(duration: 0.24, bounce: 0.3), value: arrivalPhase)
            }
            Image(systemName: type.symbol)
                .font(.body.weight(.bold)).foregroundStyle(.white)
                .frame(width: diameter, height: diameter).background(AppStyle.ink, in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
        }
        // Stable bottom anchor in the map, including when the badge disappears.
        .frame(minHeight: diameter + badgeSpace, alignment: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(type.rawValue). \(count > 0 ? "\(count) people shared they’re cooling off here in the last 10 minutes" : "No active shared presence")")
    }
}

struct SearchResultsPanel: View {
    let query: String
    let coolSpots: [CoolSpot]
    let places: [RecognisedPlace]
    let state: PlaceSearchModel.State
    let retry: () -> Void
    let chooseSpot: (CoolSpot) -> Void
    let choosePlace: (RecognisedPlace) -> Void
    let addLocation: () -> Void
    var body: some View {
        ScrollView {
          VStack(spacing: 0) {
            if state == .loading || state == .failed {
                PlaceSearchStatus(state: state, retry: retry).padding(16)
            }
            if state == .loaded && coolSpots.isEmpty && places.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("No places found").font(.headline)
                    Text("No matches for “\(query)”. Try another name or address.")
                        .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Add cooling information at a location", action: addLocation)
                        .frame(minHeight: 44)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
            }
            ForEach(coolSpots) { spot in
                Button { chooseSpot(spot) } label: {
                    SearchResultRow(symbol: spot.type.symbol, title: spot.name,
                                    subtitle: "\(spot.sourceLabel) · \(spot.address)", isCoolSpot: true)
                }.buttonStyle(.plain)
            }
            ForEach(places) { place in
                Button { choosePlace(place) } label: {
                    SearchResultRow(symbol: place.type.symbol, title: place.name,
                                    subtitle: place.searchSubtitle, isCoolSpot: false)
                }.buttonStyle(.plain)
            }
          }
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxHeight: 320)
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
            VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(AppStyle.supportingText)
                if !isCoolSpot {
                    Text("No cooling information yet").font(.caption.weight(.medium)).foregroundStyle(.orange)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(AppStyle.supportingText)
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
                VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                    Text("Cool Spots").font(.headline)
                }
                Spacer()
                Text("\(spots.count) places").font(.caption.weight(.semibold)).foregroundStyle(AppStyle.brand)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LayoutSpacing.related) {
                    ForEach(spots) { spot in
                        Button { choose(spot) } label: {
                            HStack(spacing: LayoutSpacing.related) {
                                Image(systemName: spot.type.symbol).foregroundStyle(.white)
                                    .frame(width: 34, height: 34).background(AppStyle.ink, in: Circle())
                                VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                                    Text(spot.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                                    Text([spot.isExample ? spot.sourceLabel : spot.distance, spot.features.first?.rawValue ?? spot.type.shortName].filter { !$0.isEmpty }.joined(separator: " · "))
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
        .padding(.horizontal, 16).padding(.top, LayoutSpacing.related).padding(.bottom, 12)
        .background(.ultraThickMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 14, y: -2)
    }
}

struct SavedToast: View {
    let view: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bookmark.fill").foregroundStyle(AppStyle.brand)
            VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                Text("Private pin saved").font(.subheadline.weight(.semibold))
                Text("Added to Saved → Pins").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("View pin", action: view).font(.caption.weight(.bold)).frame(minHeight: 44)
        }
        .padding(14).background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.16), radius: 10, y: 4)
    }
}
