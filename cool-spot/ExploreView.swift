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

struct ExploreMapSpot: Identifiable {
    let spot: CoolSpot
    let count: Int
    var id: String { spot.id }

    static func make(browsing: [CoolSpot], selected: CoolSpot?,
                     presence: (CoolSpot) -> Int) -> [Self] {
        var spots = browsing
        if let selected, !spots.contains(where: { $0.id == selected.id }) {
            spots.append(selected)
        }
        return spots.map { .init(spot: $0, count: presence($0)) }
    }
}

struct ExploreView: View {
    @ObservedObject var store: PrototypeStore
    @Binding var nearbyPlaceRequest: RecognisedPlace?
    let catalogueState: CoolSpotsCatalogueViewModel.State?
    let retryCatalogue: () -> Void

    @StateObject private var placeSearch = PlaceSearchModel()
    @FocusState private var searchFieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var query = ""
    @State private var isSearching = false
    @State private var listExpanded = false
    @GestureState private var panelIsDragging = false
    @State private var panelDragHeight: CGFloat?
    @State private var panelDragStartHeight: CGFloat?
    @State private var renderedBrowseHeight: CGFloat = 0
    @State private var compactRowHeight: CGFloat = 96
    @State private var filter: ExploreFilter?
    @State private var selection: ExploreSelection?
    @State private var selectedPlace: RecognisedPlace?
    @State private var detailDetent: PresentationDetent = .medium
    @State private var camera: MapCameraPosition = .region(initialRegion)
    @State private var visibleRegion = initialRegion
    @State private var browseRegion = initialRegion
    @State private var regionBeforeDetail = initialRegion
    @State private var regionBeforeSearch = initialRegion
    @State private var browseRegionBeforeSearch = initialRegion
    @State private var filterBeforeSearch: ExploreFilter?
    @State private var listExpandedBeforeSearch = false
    @State private var mapCanvasHeight: CGFloat = 0
    @State private var visibleCamera: MapCamera?
    @State private var positionBeforeSearch: MapCameraPosition = .region(initialRegion)
    @State private var positionBeforeDetail: MapCameraPosition = .region(initialRegion)
    @State private var areaChangePending = false
    @State private var cameraHasSettled = false
    @State private var initialized = false

    @State private var nearbyOrigin: RecognisedPlace?
    @State private var nearbyRadius: CLLocationDistance = 1_000
    @State private var hasLocationAccess = false
    @State private var showLocationExplanation = false
    @State private var locationRequestPurpose: LocationRequestPurpose = .nearby
    @State private var showSaveConfirmation = false
    @State private var showSavedToast = false
    @State private var lastSavedLocation: SavedLocation?
    @State private var savedDetail: SavedLocation?
    @State private var showContribution = false

    init(store: PrototypeStore, nearbyPlaceRequest: Binding<RecognisedPlace?> = .constant(nil),
         catalogueState: CoolSpotsCatalogueViewModel.State? = nil,
         retryCatalogue: @escaping () -> Void = {}) {
        self.store = store
        _nearbyPlaceRequest = nearbyPlaceRequest
        self.catalogueState = catalogueState
        self.retryCatalogue = retryCatalogue
    }

    private static let initialRegion = MKCoordinateRegion(
        center: .init(latitude: 51.5052, longitude: -0.0920),
        span: .init(latitudeDelta: 0.035, longitudeDelta: 0.035)
    )

    private var searchingOnScreen: Bool { isSearching && selection == nil }
    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var catalogueIsLoaded: Bool {
        guard let catalogueState else { return true }
        if case .loaded = catalogueState { return true }
        return false
    }

    private var nearbyResults: [NearbyCoolSpotResult] {
        guard let origin = nearbyOrigin else { return [] }
        return NearbyCoolSpotResult.find(in: store.spots, around: origin.coordinate, radius: nearbyRadius)
    }

    private var browseSpots: [CoolSpot] {
        if nearbyOrigin != nil { return nearbyResults.map(\.spot) }
        return store.spots.filter { contains($0.coordinate, in: browseRegion) && matchesFilter($0) }
            .sorted { first, second in
                let firstDistance = distance(first.coordinate, from: browseRegion.center)
                let secondDistance = distance(second.coordinate, from: browseRegion.center)
                if firstDistance != secondDistance { return firstDistance < secondDistance }
                let names = first.name.localizedStandardCompare(second.name)
                return names == .orderedSame ? first.id < second.id : names == .orderedAscending
            }
    }

    private var matchingSpots: [CoolSpot] {
        guard !trimmedQuery.isEmpty else { return [] }
        return store.searchCoolSpots(query: trimmedQuery, including: placeSearch.places)
    }

    private var mapSpots: [ExploreMapSpot] {
        let selected: CoolSpot?
        if case .coolSpot(let id) = selection { selected = store.spot(id) }
        else { selected = nil }
        return ExploreMapSpot.make(browsing: browseSpots, selected: selected,
                                   presence: { store.presence(for: $0) })
    }

    private var matchingPlaces: [RecognisedPlace] {
        PlaceSearchResults.unique(placeSearch.places
            + PlaceSearchResults.matching(store.recognisedPlaces, query: trimmedQuery))
            .filter { store.existingSpot(for: $0) == nil }
    }

    private var areaHasMoved: Bool {
        guard cameraHasSettled, selection == nil, nearbyOrigin == nil, areaChangePending else { return false }
        return distance(visibleRegion.center, from: browseRegion.center) > 100
            || abs(visibleRegion.span.latitudeDelta - browseRegion.span.latitudeDelta)
                > browseRegion.span.latitudeDelta * 0.15
            || abs(visibleRegion.span.longitudeDelta - browseRegion.span.longitudeDelta)
                > browseRegion.span.longitudeDelta * 0.15
    }

    var body: some View {
        explore
        .toolbar(searchingOnScreen ? .hidden : .visible, for: .tabBar)
        .sheet(item: $selection, onDismiss: {
            if nearbyOrigin != nil {
                focusNearbyArea()
            } else {
                camera = positionBeforeDetail
                visibleRegion = regionBeforeDetail
            }
        }) { destination in
            Group {
                switch destination {
                case .coolSpot(let id):
                    if let spot = store.spot(id) {
                        CoolSpotDetailView(store: store, spot: spot,
                                           distanceContext: nearbyDistanceContext(for: id))
                    }
                case .recognisedPlace:
                    if let place = selectedPlace {
                        RecognisedPlaceDetailView(store: store, place: place, findNearby: {
                            startNearby(place)
                        })
                    }
                }
            }
            .presentationDetents([.medium, .large], selection: $detailDetent)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .presentationContentInteraction(.resizes)
        }
        .onAppear {
            receiveNearbyRequest()
            guard !initialized else { return }
            initialized = true
            #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("--explore-layout-preview"), arguments.contains("--preview-search") {
                beginSearch()
                query = "Canning"
            }
            #endif
        }
        .onChange(of: nearbyPlaceRequest?.id) { _, _ in receiveNearbyRequest() }
        .onChange(of: query) { _, value in
            guard isSearching else { return }
            placeSearch.update(query: value, region: browseRegion)
        }
        .onChange(of: panelIsDragging) { _, dragging in
            // Gesture cancellation also needs a stable resting height.
            if !dragging, panelDragHeight != nil { setListExpanded(listExpanded) }
        }
        .onChange(of: isSearching) { _, searching in
            if searching { clearPanelDrag() }
        }
        .onDisappear {
            placeSearch.cancel()
            clearPanelDrag()
        }
        .alert("Use your current location?", isPresented: $showLocationExplanation) {
            Button("Not now", role: .cancel) {}
            Button("Continue") {
                hasLocationAccess = true
                focusCurrentLocation()
            }
        } message: {
            Text(locationRequestPurpose == .saveCurrentLocation
                 ? "Cool Spot uses your location to show the point before you save it. The estimated accuracy is also shown."
                 : "Cool Spot uses your location only when you ask for nearby places or check in. You can still search without it.")
        }
        .sheet(isPresented: $showContribution) {
            ContributionFlow(store: store, source: .currentLocation)
        }
        .sheet(item: $savedDetail) { saved in
            SavedDetail(store: store, savedID: saved.id)
        }
    }

    private var explore: some View {
        GeometryReader { geometry in
            ZStack {
                if !searchingOnScreen {
                Map(position: $camera) {
                    if hasLocationAccess {
                        Annotation("Your location", coordinate: store.currentCoordinate) {
                            CurrentLocationMarker()
                        }
                    }
                    ForEach(mapSpots) { marker in
                        Annotation(marker.spot.name, coordinate: marker.spot.coordinate, anchor: .bottom) {
                            Button { open(marker.spot) } label: {
                                CoolSpotPin(type: marker.spot.type, count: marker.count)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(marker.count > 0
                                ? "\(marker.spot.name). \(marker.count) \(marker.count == 1 ? "person" : "people") shared they’re cooling off here in the last 10 minutes"
                                : marker.spot.name)
                        }
                    }
                    if let selectedPlace, selection != nil || nearbyOrigin != nil {
                        Marker(selectedPlace.name, coordinate: selectedPlace.coordinate)
                            .tint(AppStyle.brand)
                    }
                }
                // Keyboard and tab-bar changes must not resize the hidden map
                // or masquerade as a new area chosen by the person.
                .frame(width: geometry.size.width,
                       height: mapCanvasHeight == 0 ? geometry.size.height : mapCanvasHeight)
                .frame(maxHeight: .infinity, alignment: .top)
                .mapStyle(.standard(elevation: .flat, emphasis: .muted,
                                    pointsOfInterest: .excludingAll))
                .ignoresSafeArea()
                .onMapCameraChange(frequency: .onEnd) { context in
                    visibleRegion = context.region
                    visibleCamera = context.camera
                    if !cameraHasSettled {
                        browseRegion = context.region
                        cameraHasSettled = true
                    }
                    if camera.positionedByUser && !isSearching && selection == nil && nearbyOrigin == nil {
                        areaChangePending = true
                    }
                }
                .overlay(alignment: .top) {
                    if !searchingOnScreen && selection == nil {
                        VStack(spacing: LayoutSpacing.text) {
                            if let origin = nearbyOrigin {
                                Button(action: returnToOrigin) {
                                    Label("Back to \(origin.name)", systemImage: "chevron.left")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                        .padding(.horizontal, LayoutSpacing.group)
                                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                                }.buttonStyle(.plain)
                            } else {
                            Button(action: beginSearch) {
                                Label("Search a place or postcode", systemImage: "magnifyingglass")
                                    .font(.body)
                                    .foregroundStyle(AppStyle.supportingText)
                                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                    .padding(.horizontal, LayoutSpacing.group)
                                    .background(.regularMaterial,
                                                in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("inspectionSearch")
                            HStack {
                                Spacer()
                                Button { requestLocation(for: .nearby) } label: {
                                    Label("Nearby", systemImage: "location.fill")
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, LayoutSpacing.related)
                                        .frame(minHeight: 44)
                                        .background(.regularMaterial, in: Capsule())
                                }.buttonStyle(.plain)
                                contributionMenu
                            }
                            }
                            if areaHasMoved {
                                Button {
                                    browseRegion = visibleRegion
                                    areaChangePending = false
                                } label: {
                                    Label("Search this area", systemImage: "arrow.clockwise")
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, LayoutSpacing.group)
                                        .frame(minHeight: 44)
                                        .background(.regularMaterial, in: Capsule())
                                }.buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, LayoutSpacing.page)
                        .padding(.top, LayoutSpacing.text)
                    }
                }
                .overlay(alignment: .bottom) {
                    if !searchingOnScreen && selection == nil {
                        VStack(spacing: LayoutSpacing.related) {
                            if showSaveConfirmation {
                                CurrentLocationSavePrompt {
                                    showSaveConfirmation = false
                                } save: {
                                    lastSavedLocation = store.saveCurrentLocation()
                                    showSaveConfirmation = false
                                    showSavedToast = true
                                }.padding(.horizontal, LayoutSpacing.page)
                            }
                            if let origin = nearbyOrigin {
                                if catalogueIsLoaded {
                                    NearbyCoolSpotsPanel(origin: origin, results: nearbyResults,
                                                        radius: nearbyRadius, expand: expandNearbyArea,
                                                        choose: open)
                                        .frame(maxHeight: geometry.size.height * 0.48)
                                } else {
                                    catalogueStatus.background(Color(.systemBackground))
                                }
                            } else {
                                browsePanel(availableHeight: geometry.size.height)
                            }
                        }
                    }
                }
                }

                if searchingOnScreen { searchLayout }
                if showSavedToast {
                    VStack {
                        SavedToast {
                            savedDetail = lastSavedLocation
                            showSavedToast = false
                        }
                        Spacer()
                    }
                    .padding(.horizontal, LayoutSpacing.page)
                    .padding(.top, 132)
                    .task {
                        try? await Task.sleep(for: .seconds(3))
                        showSavedToast = false
                    }
                }
            }
            .onAppear { mapCanvasHeight = geometry.size.height }
        }
    }

    private func browsePanel(availableHeight: CGFloat) -> some View {
        let canResize = catalogueIsLoaded && !browseSpots.isEmpty
        let contentHeight = browseContentHeight(availableHeight: availableHeight)
        return VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                if canResize {
                    Button { setListExpanded(!listExpanded) } label: {
                        Capsule().fill(Color(.tertiaryLabel))
                            .frame(width: 38, height: 5)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Cool Spots panel")
                    .accessibilityValue(listExpanded ? "Expanded" : "Collapsed")
                    .accessibilityHint("Double-tap to expand or collapse the list.")
                    .accessibilityIdentifier("inspectionPanelGrabber")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: setListExpanded(true)
                        case .decrement: setListExpanded(false)
                        @unknown default: break
                        }
                    }
                }
                HStack(alignment: .top, spacing: LayoutSpacing.related) {
                    VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                        Text("Cool Spots").font(.title3.weight(.semibold))
                        if catalogueIsLoaded {
                            Text("\(browseSpots.count) in this area\(filter.map { " · \($0.title)" } ?? "")")
                                .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                        }
                        if canResize {
                            Text("Closest to map centre")
                                .font(.footnote).foregroundStyle(AppStyle.supportingText)
                        }
                    }
                    Spacer(minLength: 0)
                    if canResize {
                        Button { setListExpanded(!listExpanded) } label: {
                            Label(listExpanded ? "Show map" : "Show list",
                                  systemImage: listExpanded ? "chevron.down" : "chevron.up")
                                .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                        }
                        .accessibilityIdentifier("inspectionExpandList")
                    }
                }
                .padding(.horizontal, LayoutSpacing.page)
                .padding(.top, canResize ? 0 : LayoutSpacing.group)
                .padding(.bottom, LayoutSpacing.related)
            }
            .contentShape(Rectangle())
            .gesture(browseResizeGesture(availableHeight: availableHeight))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LayoutSpacing.text) {
                    filterButton(title: "All", symbol: nil, value: nil)
                    ForEach(ExploreFilter.visible) { option in
                        filterButton(title: option.title, symbol: option.symbol, value: option)
                    }
                }.padding(.horizontal, LayoutSpacing.page)
            }
            .padding(.bottom, LayoutSpacing.text)

            if catalogueIsLoaded && store.spots.isEmpty {
                catalogueStatus
            } else if catalogueIsLoaded {
                if browseSpots.isEmpty {
                    VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                        Text("No Cool Spots match in this area").font(.headline)
                        Text("Try another filter or move the map to explore a different area.")
                            .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                        if filter != nil {
                            Button("Clear filter") { filter = nil }.frame(minHeight: 44)
                        }
                    }
                    .padding(.horizontal, LayoutSpacing.page)
                    .padding(.vertical, LayoutSpacing.group)
                } else {
                    // Keep the same list while dragging and settling; replacing it mid-gesture jumps.
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(browseSpots) { spot in
                                    measuredBrowseRow(spot).id(spot.id)
                                    Divider().padding(.leading, 74)
                                }
                            }
                        }
                        .scrollDisabled(!listExpanded || panelIsDragging)
                        .scrollBounceBehavior(.basedOnSize)
                        .onChange(of: listExpanded) { _, expanded in
                            if !expanded, let first = browseSpots.first {
                                var transaction = Transaction()
                                transaction.disablesAnimations = true
                                withTransaction(transaction) { proxy.scrollTo(first.id, anchor: .top) }
                            }
                        }
                    }
                    .frame(height: contentHeight, alignment: .top)
                    .clipped()
                    .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height in
                        renderedBrowseHeight = height
                    }
                }
            } else {
                catalogueStatus
            }
        }
        .padding(.bottom, LayoutSpacing.related)
        .background(Color(.systemBackground),
                    in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
    }

    private func measuredBrowseRow(_ spot: CoolSpot) -> some View {
        spotRow(spot, inBrowse: true)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height in
                if spot.id == browseSpots.first?.id, height > 0 {
                    compactRowHeight = max(44, height)
                }
            }
    }

    private func expandedBrowseHeight(availableHeight: CGFloat) -> CGFloat {
        max(compactRowHeight, min(360, availableHeight * 0.40))
    }

    private func browseContentHeight(availableHeight: CGFloat) -> CGFloat {
        panelDragHeight ?? (listExpanded ? expandedBrowseHeight(availableHeight: availableHeight)
                                       : compactRowHeight)
    }

    private func resistedBrowseHeight(_ height: CGFloat, upperBound: CGFloat) -> CGFloat {
        let bounded = min(upperBound, max(compactRowHeight, height))
        guard !reduceMotion else { return bounded }
        let excess = height - bounded
        // Resistance increases near each boundary; overdrag stays below 24 pt.
        return bounded + 24 * excess / (abs(excess) + 120)
    }

    private func browseResizeGesture(availableHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .global)
            .updating($panelIsDragging) { value, dragging, transaction in
                guard catalogueIsLoaded, !browseSpots.isEmpty,
                      abs(value.translation.height) > abs(value.translation.width) else { return }
                dragging = true
                transaction.animation = nil
            }
            .onChanged { value in
                guard catalogueIsLoaded, !browseSpots.isEmpty,
                      abs(value.translation.height) > abs(value.translation.width) else { return }
                let upperBound = expandedBrowseHeight(availableHeight: availableHeight)
                if panelDragStartHeight == nil {
                    let currentHeight = renderedBrowseHeight > 0
                        ? renderedBrowseHeight : browseContentHeight(availableHeight: availableHeight)
                    panelDragStartHeight = min(upperBound, max(compactRowHeight, currentHeight))
                }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    panelDragHeight = resistedBrowseHeight(
                        (panelDragStartHeight ?? compactRowHeight) - value.translation.height,
                        upperBound: upperBound
                    )
                }
            }
            .onEnded { value in
                guard let startHeight = panelDragStartHeight else { return }
                let upperBound = expandedBrowseHeight(availableHeight: availableHeight)
                let destinationHeight = startHeight - value.predictedEndTranslation.height
                setListExpanded(destinationHeight > (compactRowHeight + upperBound) / 2)
            }
    }

    private func setListExpanded(_ expanded: Bool) {
        let settling: Animation = reduceMotion ? .easeOut(duration: 0.15)
            : .spring(response: 0.34, dampingFraction: 0.84, blendDuration: 0.10)
        withAnimation(settling) {
            listExpanded = expanded
            clearPanelDrag()
        }
    }

    private func clearPanelDrag() {
        panelDragHeight = nil
        panelDragStartHeight = nil
    }

    private func filterButton(title: String, symbol: String?, value: ExploreFilter?) -> some View {
        Button { filter = value } label: {
            HStack(spacing: 6) {
                if let symbol { Image(systemName: symbol) }
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(filter == value ? .white : AppStyle.brand)
            .padding(.horizontal, LayoutSpacing.related)
            .frame(minHeight: 44)
            .background(filter == value ? AppStyle.ink : AppStyle.controlSurface, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(filter == value ? .isSelected : [])
    }

    private var searchLayout: some View {
        VStack(spacing: 0) {
            HStack(spacing: LayoutSpacing.text) {
                HStack(spacing: 0) {
                    Image(systemName: "magnifyingglass").foregroundStyle(AppStyle.supportingText)
                        .padding(.leading, LayoutSpacing.related)
                        .padding(.trailing, LayoutSpacing.text)
                    TextField("Search a place or postcode", text: $query,
                              prompt: Text("Search a place or postcode")
                                .foregroundStyle(AppStyle.supportingText))
                        .font(.body).focused($searchFieldFocused)
                        .submitLabel(.search).autocorrectionDisabled()
                        .onSubmit {
                            searchFieldFocused = false
                            placeSearch.update(query: query, region: browseRegion, debounce: false)
                        }
                    if !query.isEmpty {
                        Button {
                            query = ""
                            placeSearch.cancel()
                            searchFieldFocused = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppStyle.supportingText)
                                .frame(width: 44, height: 44)
                        }.accessibilityLabel("Clear search")
                    }
                }
                .frame(minHeight: 48)
                .background(AppStyle.controlSurface, in: RoundedRectangle(cornerRadius: 12))

                Button("Cancel", action: cancelSearch)
                    .font(.body).frame(minHeight: 44)
            }
            .padding(.horizontal, LayoutSpacing.page)
            .padding(.vertical, LayoutSpacing.related)

            if trimmedQuery.isEmpty {
                VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                    Text("Find a place").font(.title2.weight(.semibold))
                    Text("Search by name, address or postcode.")
                        .font(.body).foregroundStyle(AppStyle.supportingText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(LayoutSpacing.page)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if !catalogueIsLoaded { catalogueStatus }
                        ForEach(matchingSpots) { spot in
                            spotRow(spot, inBrowse: false)
                            Divider().padding(.leading, 74)
                        }
                        ForEach(matchingPlaces) { place in
                            Button { open(place) } label: {
                                resultRow(symbol: place.type.symbol, name: place.name,
                                          address: place.address,
                                          metadata: "Apple Maps · No cooling information yet",
                                          isCoolSpot: false)
                            }.buttonStyle(.plain)
                            Divider().padding(.leading, 74)
                        }
                        PlaceSearchStatus(state: placeSearch.state, retry: {
                            placeSearch.update(query: query, region: browseRegion, debounce: false)
                        })
                        .padding(.horizontal, LayoutSpacing.page)
                        .padding(.vertical, LayoutSpacing.related)
                        if placeSearch.state == .loaded && matchingSpots.isEmpty && matchingPlaces.isEmpty {
                            VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                                Text("No places found").font(.headline)
                                Text("Try a different name, address or postcode.")
                                    .font(.body).foregroundStyle(AppStyle.supportingText)
                                Button("Add cooling information") { showContribution = true }
                                    .frame(minHeight: 44)
                            }.padding(LayoutSpacing.page)
                        }
                    }
                }.scrollDismissesKeyboard(.interactively)
            }
        }
        .background(Color(.systemBackground))
    }

    @ViewBuilder private var catalogueStatus: some View {
        switch catalogueState {
        case .idle?, .loading?:
            ProgressView("Loading Cool Spots…").padding(LayoutSpacing.page)
        case .failed?:
            VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                Text("Couldn’t load Cool Spots").font(.headline)
                Text("Try again to load the cooling catalogue.")
                    .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                Button("Try again", action: retryCatalogue).frame(minHeight: 44)
            }.padding(LayoutSpacing.page)
        case .loaded?, nil:
            if store.spots.isEmpty {
                Text("No Cool Spots available")
                    .font(.headline).padding(LayoutSpacing.page)
            }
        }
    }

    private func spotRow(_ spot: CoolSpot, inBrowse: Bool) -> some View {
        Button { open(spot) } label: {
            resultRow(symbol: spot.type.symbol, name: spot.name, address: spot.address,
                      metadata: inBrowse
                        ? "\(spot.features.first?.rawValue ?? "Cooling information") · \(spot.sourceLabel)"
                        : "Cool Spot · \(spot.sourceLabel)",
                      isCoolSpot: true,
                      distanceLabel: inBrowse ? formattedDistance(spot.coordinate) : nil)
        }.buttonStyle(.plain)
    }

    private func resultRow(symbol: String, name: String, address: String,
                           metadata: String, isCoolSpot: Bool, distanceLabel: String? = nil) -> some View {
        HStack(alignment: .top, spacing: LayoutSpacing.related) {
            Image(systemName: symbol).font(.body.weight(.medium))
                .foregroundStyle(isCoolSpot ? .white : AppStyle.brand)
                .frame(width: 42, height: 42)
                .background(isCoolSpot ? AppStyle.ink : AppStyle.controlSurface, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                Text(name).font(.body.weight(.semibold))
                    .foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
                Text(address).font(.subheadline).foregroundStyle(AppStyle.supportingText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(metadata).font(.footnote)
                    .foregroundStyle(isCoolSpot ? AppStyle.brand : AppStyle.supportingText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: LayoutSpacing.text) {
                if let distanceLabel {
                    Text(distanceLabel).font(.subheadline).foregroundStyle(AppStyle.supportingText)
                        .fixedSize()
                }
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                    .foregroundStyle(AppStyle.supportingText).accessibilityHidden(true)
            }.padding(.top, LayoutSpacing.metadata)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, LayoutSpacing.page)
        .padding(.vertical, LayoutSpacing.group)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func beginSearch() {
        captureBrowseContext()
        isSearching = true
        Task { @MainActor in
            await Task.yield()
            searchFieldFocused = true
        }
    }

    private func captureBrowseContext() {
        regionBeforeSearch = visibleRegion
        positionBeforeSearch = camera.positionedByUser
            ? visibleCamera.map(MapCameraPosition.camera) ?? camera : camera
        browseRegionBeforeSearch = browseRegion
        filterBeforeSearch = filter
        listExpandedBeforeSearch = listExpanded
    }

    private func cancelSearch() {
        searchFieldFocused = false
        placeSearch.cancel()
        query = ""
        isSearching = false
        clearPanelDrag()
        browseRegion = browseRegionBeforeSearch
        filter = filterBeforeSearch
        listExpanded = listExpandedBeforeSearch
        camera = positionBeforeSearch
        visibleRegion = regionBeforeSearch
    }

    private func open(_ spot: CoolSpot) {
        searchFieldFocused = false
        regionBeforeDetail = isSearching ? regionBeforeSearch : visibleRegion
        positionBeforeDetail = isSearching ? positionBeforeSearch : camera.positionedByUser
            ? visibleCamera.map(MapCameraPosition.camera) ?? camera : camera
        selectedPlace = nil
        detailDetent = .medium
        camera = .region(.init(center: spot.coordinate, span: .init(latitudeDelta: 0.008, longitudeDelta: 0.008)))
        selection = .coolSpot(spot.id)
    }

    private func open(_ place: RecognisedPlace) {
        searchFieldFocused = false
        regionBeforeDetail = isSearching ? regionBeforeSearch : visibleRegion
        positionBeforeDetail = isSearching ? positionBeforeSearch : camera.positionedByUser
            ? visibleCamera.map(MapCameraPosition.camera) ?? camera : camera
        store.remember(place)
        selectedPlace = place
        detailDetent = .medium
        camera = .region(.init(center: place.coordinate, span: .init(latitudeDelta: 0.008, longitudeDelta: 0.008)))
        selection = .recognisedPlace(place.id)
    }

    private var contributionMenu: some View {
        Menu {
            Button { requestLocation(for: .saveCurrentLocation) } label: {
                Label("Save a pin here", systemImage: "mappin.and.ellipse")
            }
            Button { showContribution = true } label: {
                Label("Add cooling information", systemImage: "plus.bubble.fill")
            }
        } label: {
            Image(systemName: "plus").font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
        }.accessibilityLabel("Save or contribute")
    }

    private func receiveNearbyRequest() {
        guard let place = nearbyPlaceRequest else { return }
        nearbyPlaceRequest = nil
        if !isSearching { captureBrowseContext() }
        query = place.name
        startNearby(place)
    }

    private func startNearby(_ place: RecognisedPlace) {
        store.remember(place)
        nearbyOrigin = place
        nearbyRadius = 1_000
        selectedPlace = place
        selection = nil
        searchFieldFocused = false
        isSearching = false
        placeSearch.cancel()
        filter = nil
        clearPanelDrag()
        focusNearbyArea()
    }

    private func returnToOrigin() {
        guard let origin = nearbyOrigin else { return }
        nearbyOrigin = nil
        isSearching = !trimmedQuery.isEmpty
        placeSearch.update(query: query, region: browseRegion, debounce: false)
        open(origin)
    }

    private func expandNearbyArea() {
        nearbyRadius = nearbyRadius < 3_000 ? 3_000 : min(nearbyRadius * 2, 25_000)
        focusNearbyArea()
    }

    private func focusNearbyArea() {
        guard let origin = nearbyOrigin else { return }
        let region = MKCoordinateRegion(center: origin.coordinate,
                                        latitudinalMeters: nearbyRadius * 2.4,
                                        longitudinalMeters: nearbyRadius * 2.4)
        browseRegion = region
        visibleRegion = region
        areaChangePending = false
        camera = .region(region)
    }

    private func nearbyDistanceContext(for id: String) -> String? {
        guard let origin = nearbyOrigin,
              let result = nearbyResults.first(where: { $0.id == id }) else { return nil }
        return "\(result.distanceLabel) from \(origin.name) (straight-line)"
    }

    private func requestLocation(for purpose: LocationRequestPurpose) {
        locationRequestPurpose = purpose
        if hasLocationAccess { focusCurrentLocation() }
        else { showLocationExplanation = true }
    }

    private func focusCurrentLocation() {
        let region = MKCoordinateRegion(center: store.currentCoordinate,
                                       span: .init(latitudeDelta: 0.018, longitudeDelta: 0.018))
        browseRegion = region
        visibleRegion = region
        camera = .region(region)
        filter = nil
        areaChangePending = false
        if locationRequestPurpose == .saveCurrentLocation { showSaveConfirmation = true }
    }

    private func matchesFilter(_ spot: CoolSpot) -> Bool {
        switch filter {
        case .indoor: spot.environment == .indoors || spot.environment == .both
        case .shade: spot.features.contains(.treeShade) || spot.features.contains(.structuralShade)
        case .airConditioning: spot.features.contains(.airConditioning)
        case .free: spot.access == .free
        case .water: spot.features.contains(.drinkingWater) || spot.features.contains(.waterFeature)
        case nil, .nearby: true
        }
    }

    private func contains(_ coordinate: CLLocationCoordinate2D, in region: MKCoordinateRegion) -> Bool {
        abs(coordinate.latitude - region.center.latitude) <= region.span.latitudeDelta / 2
            && abs(coordinate.longitude - region.center.longitude) <= region.span.longitudeDelta / 2
    }

    private func distance(_ coordinate: CLLocationCoordinate2D, from centre: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            .distance(from: CLLocation(latitude: centre.latitude, longitude: centre.longitude))
    }

    private func formattedDistance(_ coordinate: CLLocationCoordinate2D) -> String {
        let metres = distance(coordinate, from: browseRegion.center)
        if metres < 1_000 { return "\(Int((metres / 10).rounded()) * 10) m" }
        return String(format: "%.1f km", metres / 1_000)
    }
}

// Developer inspection only: real production views, memory-only data and local
// accessibility overrides. Does not read/write the user's stored journeys.

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
