import MapKit
import SwiftUI
import PhotosUI

// THESIS: choose the place once, answer related questions together, send for review.
// OWN-WORLD: native teal/mint controls, system type and meaningful form sections.
// STORY: known places open the form; saved pins retain their original position.
// FIRST VIEWPORT: selected place or immediate search; one clear next action.
// FORM: user-authorized human-centred extension, 2026-09-06; code-led native UI.
// FINISH: native evidence, independent review and continuity notes are required.
enum ContributionSource {
    case currentLocation
    case savedCoordinate(SavedLocation)
    case exactSavedCoordinate(SavedLocation)
    case recognisedPlace(RecognisedPlace)
    case existingCoolSpot(CoolSpot)

    func anchor(current: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        switch self {
        case .savedCoordinate(let saved), .exactSavedCoordinate(let saved):
            .init(latitude: saved.latitude, longitude: saved.longitude)
        case .recognisedPlace(let place): place.coordinate
        case .existingCoolSpot(let spot): spot.coordinate
        case .currentLocation: current
        }
    }
    var isSavedPin: Bool {
        switch self { case .savedCoordinate, .exactSavedCoordinate: true; default: false }
    }
}

enum PlaceContributionKind: Equatable, Codable { case recognised, missing, exact, unlisted, update }
enum OptionalFact: String, CaseIterable, Identifiable, Codable {
    case unknown = "Not added", yes = "Yes", no = "No"
    var id: Self { self }
}

struct PlaceContributionValues: Equatable, Codable {
    var name = ""
    var latitude: Double
    var longitude: Double
    var locationConfirmed = false
    var setting: PlaceEnvironment?
    var type: PlaceType?
    var features: Set<CoolingFeature> = []
    var access: AccessType = .unsure
    var accessibility = ""
    var seating: SeatingType = .unsure
    var tables: OptionalFact = .unknown
    var wheelchairAccess: OptionalFact = .unknown
    var staffedWhenOpen: OptionalFact = .unknown
    var stayLimit = ""
    var toilets: PlaceInformation.Toilets = .unknown
    var wifi: OptionalFact = .unknown
    var power: OptionalFact = .unknown
    var laptop: OptionalFact = .unknown
    var photo: Data?
    var entryEligibility: PlaceEntryEligibility = .unknown {
        didSet {
            if entryEligibility != .limited { entryRequirement = "" }
        }
    }
    var entryRequirement = ""
    var locationDetails = ""
    var note = ""
    var sourceCorrection = ""
    var removalReason = ""
    // Photo bytes live in device-local files, never in the Cool Spots response or preferences JSON.
    enum CodingKeys: String, CodingKey {
        case name, latitude, longitude, locationConfirmed, setting, type, features, access, accessibility, seating
        case tables, wheelchairAccess, staffedWhenOpen, stayLimit, toilets, wifi, power, laptop
        case entryEligibility, entryRequirement, locationDetails, note, sourceCorrection, removalReason
    }
    var normalized: Self {
        var copy = self
        copy.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.locationDetails = locationDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.entryRequirement = entryRequirement.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.accessibility = accessibility.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.stayLimit = stayLimit.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.sourceCorrection = sourceCorrection.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.removalReason = removalReason.trimmingCharacters(in: .whitespacesAndNewlines)
        return copy
    }
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

enum ContributionField: Hashable {
    case location, setting, name, type, features, removalReason, photo, changes
}

struct ContributionValidationIssue: Equatable {
    let field: ContributionField
    let message: String
}

struct PlaceContributionDraft: Identifiable, Equatable, Codable {
    let id: UUID
    let selectedPlace: RecognisedPlace?
    let identity: String
    let kind: PlaceContributionKind
    let spotID: String?
    let sourceName: Bool
    let sourceType: Bool
    let sourceSetting: Bool
    var values: PlaceContributionValues
    let original: PlaceContributionValues

    init(kind: PlaceContributionKind, anchor: CLLocationCoordinate2D,
         place: RecognisedPlace? = nil, spot: CoolSpot? = nil) {
        id = UUID()
        selectedPlace = place
        self.kind = kind
        spotID = spot?.id
        identity = spot.map { "spot:\($0.id)" } ?? place.map { "place:\($0.id)" } ?? UUID().uuidString
        sourceName = place != nil || spot != nil
        sourceType = (spot != nil && spot?.type != .unknown) || place?.hasTrustedType == true
        sourceSetting = place?.trustedSetting != nil
        var initial = PlaceContributionValues(latitude: anchor.latitude, longitude: anchor.longitude)
        if let spot {
            initial.name = spot.name; initial.latitude = spot.latitude; initial.longitude = spot.longitude
            initial.type = spot.type == .unknown ? nil : spot.type; initial.setting = spot.environment
            initial.features = Set(spot.features); initial.access = spot.access; initial.seating = spot.seating
            initial.entryEligibility = spot.entryEligibility
            initial.entryRequirement = spot.entryEligibility == .limited ? spot.entryRequirement : ""
            initial.accessibility = spot.entryInformation
            initial.toilets = spot.information.toilets
            initial.wheelchairAccess = spot.information.wheelchairAccessible.map { $0 ? .yes : .no } ?? .unknown
            initial.staffedWhenOpen = spot.information.staffedWhenOpen.map { $0 ? .yes : .no } ?? .unknown
            initial.tables = spot.information.tables.map { $0 ? .yes : .no } ?? .unknown
            initial.locationDetails = spot.information.areaDescription ?? ""
            initial.note = spot.information.additionalInformation ?? ""
            initial.stayLimit = spot.information.postedStayLimit.formValue
            initial.locationConfirmed = true
        } else if let place {
            initial.name = place.name; initial.latitude = place.latitude; initial.longitude = place.longitude
            initial.type = place.hasTrustedType ? place.type : nil
            initial.setting = place.trustedSetting; initial.locationConfirmed = true
        } else if kind == .exact { initial.setting = .outdoors }
        values = initial; original = initial
    }
    var isUpdate: Bool { kind == .update }
    var isUnlisted: Bool { kind == .unlisted || kind == .missing || kind == .exact }
    var isExactSpot: Bool { isUnlisted && values.normalized.name.isEmpty }
    var isDirty: Bool { values != original }
    var displayName: String {
        if !values.normalized.name.isEmpty { return values.normalized.name }
        if !values.normalized.locationDetails.isEmpty { return values.normalized.locationDetails }
        return "Selected spot"
    }
    var needsRemovalReason: Bool { isUpdate && !original.features.isEmpty && values.features.isEmpty }
    // Ordered as the questions appear, shared by the form and store submission gate.
    var validationIssues: [ContributionValidationIssue] {
        var issues: [ContributionValidationIssue] = []
        func require(_ valid: Bool, _ field: ContributionField, _ message: String) {
            if !valid { issues.append(.init(field: field, message: message)) }
        }
        require(CLLocationCoordinate2DIsValid(values.coordinate) && values.locationConfirmed,
                .location, "Confirm the location on the map.")
        if !isUpdate || values.setting != original.setting {
            require(values.setting != nil, .setting, "Choose indoors, outdoors or both.")
        }
        if !isUpdate || values.normalized.name != original.normalized.name {
            require(!values.normalized.name.isEmpty, .name, "Give this spot a name people can recognise.")
        }
        if isUpdate && values.type != original.type {
            require(values.type != nil, .type, "Choose a place type.")
        }
        if !isUpdate {
            require(!values.features.isEmpty, .features, "Choose at least one cooling feature.")
        }
        if needsRemovalReason {
            require(!values.normalized.removalReason.isEmpty, .removalReason,
                    "Explain why the cooling features should be removed.")
        }
        if let photo = values.photo {
            if !isUpdate || photo != original.photo {
                require(UIImage(data: photo) != nil, .photo, "This photo couldn’t be read. Choose another image.")
            }
        } else if isUnlisted {
            require(false, .photo, "Add a photo so people can find this spot.")
        }
        if isUpdate {
            require(!changes.isEmpty, .changes, "Change at least one detail before sending an update.")
        }
        return issues
    }
    var canSend: Bool { validationIssues.isEmpty }
    var changes: [String] {
        let values = values.normalized
        let original = original.normalized
        var result: [String] = []
        if values.name != original.name { result.append("Name: \(original.name) → \(values.name)") }
        if values.setting != original.setting { result.append("Setting: \(original.setting?.rawValue ?? "Unknown") → \(values.setting?.rawValue ?? "Unknown")") }
        if values.type != original.type { result.append("Type: \(original.type?.rawValue ?? "Unknown") → \(values.type?.rawValue ?? "Unknown")") }
        if values.features != original.features { result.append("Cooling features: \(Self.featureText(original.features)) → \(Self.featureText(values.features))") }
        if values.access != original.access { result.append("Cost to use: \(original.access.rawValue) → \(values.access.rawValue)") }
        if values.entryEligibility != original.entryEligibility { result.append("Who can use it: \(values.entryEligibility.rawValue)") }
        if values.entryRequirement != original.entryRequirement { result.append("Who it is limited to: \(values.entryRequirement.isEmpty ? "Not added" : values.entryRequirement)") }
        if values.seating != original.seating { result.append("Seating: \(original.seating.displayName) → \(values.seating.displayName)") }
        if values.tables != original.tables { result.append("Tables: \(values.tables.rawValue)") }
        if values.wheelchairAccess != original.wheelchairAccess { result.append("Wheelchair accessible: \(values.wheelchairAccess.rawValue)") }
        if values.staffedWhenOpen != original.staffedWhenOpen { result.append("Staff on site when open: \(values.staffedWhenOpen.rawValue)") }
        if values.stayLimit != original.stayLimit { result.append("Time limit: \(values.stayLimit.isEmpty ? "Not added" : values.stayLimit)") }
        if values.accessibility != original.accessibility { result.append("Tickets and booking: \(values.accessibility.isEmpty ? "Not added" : values.accessibility)") }
        if values.toilets != original.toilets { result.append("Toilets: \(values.toilets.rawValue)") }
        if values.wifi != original.wifi { result.append("Wi-Fi: \(values.wifi.rawValue)") }
        if values.power != original.power { result.append("Power outlets: \(values.power.rawValue)") }
        if values.laptop != original.laptop { result.append("Laptop use welcome / allowed: \(values.laptop.rawValue)") }
        if values.photo != original.photo { result.append("Photo added") }
        if values.locationDetails != original.locationDetails { result.append("Cooling area: \(values.locationDetails)") }
        if values.note != original.note { result.append("Note: \(values.note)") }
        if values.sourceCorrection != original.sourceCorrection { result.append("Source correction: \(values.sourceCorrection)") }
        return result
    }
    func reconciled(with spot: CoolSpot) -> PlaceContributionDraft {
        var update = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        // Rebase only explicit edits onto existing facts. Source identity and
        // untouched optional answers come from the existing Cool Spot.
        let proposed = values.normalized
        let baseline = original.normalized
        func apply<Value: Equatable>(_ key: WritableKeyPath<PlaceContributionValues, Value>) {
            if proposed[keyPath: key] != baseline[keyPath: key] {
                update.values[keyPath: key] = proposed[keyPath: key]
            }
        }
        apply(\.name)
        apply(\.setting)
        apply(\.type)
        apply(\.features)
        apply(\.access)
        apply(\.entryEligibility)
        apply(\.entryRequirement)
        apply(\.accessibility)
        apply(\.seating)
        apply(\.tables)
        apply(\.wheelchairAccess)
        apply(\.staffedWhenOpen)
        apply(\.stayLimit)
        apply(\.toilets)
        apply(\.wifi)
        apply(\.power)
        apply(\.laptop)
        apply(\.photo)
        apply(\.locationDetails)
        apply(\.note)
        apply(\.sourceCorrection)
        apply(\.removalReason)
        return update
    }
    static func featureText(_ features: Set<CoolingFeature>) -> String {
        features.isEmpty ? "None selected" : features.map(\.rawValue).sorted().joined(separator: ", ")
    }
}

enum PlaceContributionPage: Hashable { case choose, location, details, complete }

struct ContributionFlow: View {
    @ObservedObject var store: PrototypeStore
    let source: ContributionSource
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.usesRefinedContributionLayout) private var usesRefinedLayout
    @State private var draft: PlaceContributionDraft
    @State private var rootPage: PlaceContributionPage
    @State private var path: [PlaceContributionPage] = []
    @State private var mapValues: PlaceContributionValues
    @State private var editingLocation = false
    @State private var photoLoading = false
    @State private var pending: PlaceContributionDraft?
    @State private var duplicate: PlaceContributionDraft?
    @State private var showChange = false
    @State private var showClose = false
    @State private var showFailure = false
    @State private var showDuplicate = false
    @State private var search = ""
    @StateObject private var placeSearch = PlaceSearchModel()
    @State private var sent = false
    @State private var visitingExpanded = false
    @State private var facilitiesExpanded = false
    @State private var areaExpanded = false
    @State private var correctionExpanded = false
    @State private var validationAttempt = 0
    @AccessibilityFocusState private var focusedError: ContributionField?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedField: InputField?

    private enum InputField: Hashable {
        case search, name, locationDetails, correction, removalReason, note
    }

    init(store: PrototypeStore, source: ContributionSource) {
        self.store = store; self.source = source
        let anchor = source.anchor(current: store.currentCoordinate)
        let initial: PlaceContributionDraft
        let first: PlaceContributionPage
        switch source {
        case .recognisedPlace(let place):
            if let spot = store.existingSpot(for: place) {
                initial = .init(kind: .update, anchor: spot.coordinate, spot: spot)
            } else { initial = .init(kind: .recognised, anchor: place.coordinate, place: place) }
            first = .details
        case .existingCoolSpot(let spot):
            initial = .init(kind: .update, anchor: spot.coordinate, spot: spot); first = .details
        case .savedCoordinate, .exactSavedCoordinate:
            initial = .init(kind: .unlisted, anchor: anchor); first = .location
        case .currentLocation:
            initial = .init(kind: .unlisted, anchor: anchor); first = .choose
        }
        _areaExpanded = State(initialValue: initial.isUnlisted || !initial.values.locationDetails.isEmpty)
        _draft = State(initialValue: initial)
        _mapValues = State(initialValue: initial.values)
        _rootPage = State(initialValue: first)
    }
    var anchor: CLLocationCoordinate2D { source.anchor(current: store.currentCoordinate) }

    var body: some View {
        NavigationStack(path: $path) {
            screen(rootPage)
                .navigationDestination(for: PlaceContributionPage.self) { screen($0) }
        }
        .tint(AppStyle.actionForeground)
        .onChange(of: path) { _, _ in focusedField = nil }
        .interactiveDismissDisabled(draft.isDirty && !sent)
        .background(ContributionDismissObserver(hasChanges: draft.isDirty && !sent) { showClose = true })
        .confirmationDialog("Discard this place contribution?", isPresented: $showClose, titleVisibility: .visible) {
            Button("Discard and close", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) {}
        } message: { Text("Nothing will be sent. Your saved places and private pins stay unchanged.") }
        .confirmationDialog("Change to a different place?", isPresented: $showChange, titleVisibility: .visible) {
            Button("Change place", role: .destructive) { if let pending { apply(pending) }; pending = nil }
            Button("Keep current place", role: .cancel) { pending = nil }
        } message: { Text("The answers for the current place will be cleared. They may not describe the new place.") }
        .alert("This place is already on Cool Spot", isPresented: $showDuplicate) {
            Button("Review update") { if let duplicate { apply(duplicate) }; duplicate = nil }
            Button("Keep editing", role: .cancel) { duplicate = nil }
        } message: { Text("Your answers will be kept. Check the proposed changes before sending an update.") }
        .alert("Not sent", isPresented: $showFailure) {
            Button("Keep editing", role: .cancel) {}
        } message: { Text("Your answers are still here. Check the required details and try again.") }
    }

    func screen(_ destination: PlaceContributionPage) -> some View {
        content(destination)
            .navigationTitle(title(destination))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(destination == .complete)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if destination != .complete && (destination == .details || path.isEmpty) {
                        Button("Close") { if draft.isDirty { showClose = true } else { dismiss() } }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if destination == .details && !dynamicTypeSize.isAccessibilitySize { sendBar }
            }
    }
    func title(_ destination: PlaceContributionPage) -> String {
        switch destination {
        case .choose: "Choose a place"
        case .location: "Confirm the spot"
        case .details: draft.isUpdate ? "Update place details" : "Add cooling information"
        case .complete: "Sent for review"
        }
    }
    @ViewBuilder func content(_ destination: PlaceContributionPage) -> some View {
        switch destination {
        case .choose: placeChooser
        case .location:
            ContributionLocationEditor(values: $mapValues, savedPin: source.isSavedPin,
                                       onConfirm: useMapLocation,
                                       onSearch: { search = ""; path.append(.choose) })
        case .details: details
        case .complete:
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "paperplane.circle.fill").font(.largeTitle).foregroundStyle(AppStyle.actionForeground)
                    Text("Thanks for helping others find a cool spot").font(.title2.bold())
                    Text("Your information is waiting for review. It isn’t public yet.")
                    Text("Follow it in You → Places you’ve added or updated.")
                    Text("Review demo · Saved on this device")
                        .font(.footnote).foregroundStyle(AppStyle.supportingText)
                    Button("Done") { dismiss() }.buttonStyle(PrimaryButtonStyle())
                }.padding(24)
            }
        }
    }

    var placeChooser: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(AppStyle.supportingText)
                    TextField("Place name or address", text: $search, prompt: Text("Place name or address").foregroundStyle(AppStyle.supportingText)).autocorrectionDisabled()
                        .focused($focusedField, equals: .search)
                        .accessibilityLabel("Search places")
                        .submitLabel(.search)
                        .onSubmit { focusedField = nil; searchPlaces(debounce: false) }
                }
                Button { openMap() } label: { Label("Choose a spot on the map", systemImage: "mappin.and.ellipse") }
                    .frame(minHeight: 44)
            }
            Section {
                if !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    PlaceSearchStatus(state: placeSearch.state, retry: { searchPlaces(debounce: false) })
                }
                ForEach(candidates, id: \.identity) { candidate in
                    Button { select(candidate) } label: {
                        VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                            Text(candidate.displayName).font(.body).foregroundStyle(.primary)
                            Text(candidate.isUpdate ? "Already on Cool Spot · Update information" : "Add cooling information")
                                .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                            Text("\(address(candidate)) · \(distance(candidate))")
                                .font(.caption).foregroundStyle(AppStyle.supportingText)
                        }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
                if candidates.isEmpty && placeSearch.state == .loaded {
                    ContentUnavailableView.search(text: search)
                    Text("Try another name or choose the location on the map above.").font(.subheadline)
                }
            } header: { Text(search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Nearby places" : "Search results").foregroundStyle(AppStyle.supportingText) }

        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { searchPlaces() }
        .onChange(of: search) { _, _ in searchPlaces() }
        .onDisappear { placeSearch.cancel() }
    }

    func searchPlaces(debounce: Bool = true) {
        let region = MKCoordinateRegion(center: anchor, latitudinalMeters: 10_000, longitudinalMeters: 10_000)
        placeSearch.update(query: search, region: region, debounce: debounce)
    }

    var candidatePlaces: [RecognisedPlace] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        let local = query.isEmpty ? store.recognisedPlaces : PlaceSearchResults.matching(store.recognisedPlaces, query: query)
        return PlaceSearchResults.unique(placeSearch.places + local)
    }

    var candidates: [PlaceContributionDraft] {
        let known = candidatePlaces.filter { store.existingSpot(for: $0) == nil }.map {
            PlaceContributionDraft(kind: .recognised, anchor: $0.coordinate, place: $0)
        }
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        let spots = (query.isEmpty ? store.spots : store.searchCoolSpots(query: query, including: candidatePlaces))
            .map { PlaceContributionDraft(kind: .update, anchor: $0.coordinate, spot: $0) }
        return (known + spots)
            .sorted { metres($0.values.coordinate) < metres($1.values.coordinate) }
    }
    func address(_ candidate: PlaceContributionDraft) -> String {
        if let id = candidate.spotID { return store.spot(id)?.address ?? "" }
        return (store.recognisedPlaces + placeSearch.places)
            .first { "place:\($0.id)" == candidate.identity }?.address ?? ""
    }
    func metres(_ coordinate: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: anchor.latitude, longitude: anchor.longitude)
            .distance(from: .init(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
    func distance(_ candidate: PlaceContributionDraft) -> String {
        let value = metres(candidate.values.coordinate)
        let origin: String
        switch source {
        case .savedCoordinate, .exactSavedCoordinate: origin = " from your pin"
        case .recognisedPlace, .existingCoolSpot: origin = " from selected place"
        case .currentLocation: origin = " from example location"
        }
        return (value < 1000 ? "\(Int(value.rounded())) m" : String(format: "%.1f km", value / 1000)) +
            origin
    }
    func openMap() {
        editingLocation = false
        mapValues = .init(latitude: anchor.latitude, longitude: anchor.longitude)
        if rootPage == .location && path == [.choose] { path.removeAll() }
        else { path.append(.location) }
    }
    func useMapLocation() {
        let samePoint = abs(draft.values.latitude - mapValues.latitude) < 0.000001 &&
            abs(draft.values.longitude - mapValues.longitude) < 0.000001
        if draft.isUnlisted && draft.values.locationConfirmed && (editingLocation || samePoint) {
            draft.values.latitude = mapValues.latitude; draft.values.longitude = mapValues.longitude
            draft.values.locationConfirmed = true
            showDetails()
        } else {
            var selection = PlaceContributionDraft(kind: .unlisted, anchor: mapValues.coordinate)
            selection.values.locationConfirmed = true
            select(selection)
        }
    }
    func select(_ candidate: PlaceContributionDraft) {
        if let place = candidatePlaces.first(where: { "place:\($0.id)" == candidate.identity }) {
            store.remember(place)
        }
        if candidate.identity == draft.identity { showDetails(); return }
        if draft.isDirty { pending = candidate; showChange = true }
        else { apply(candidate) }
    }
    func apply(_ candidate: PlaceContributionDraft) {
        draft = candidate; mapValues = candidate.values
        areaExpanded = candidate.isUnlisted || !candidate.values.locationDetails.isEmpty
        validationAttempt = 0; focusedError = nil
        showDetails()
    }
    func showDetails() {
        if rootPage == .details { path.removeAll() }
        else { path = [.details] }
    }

    var details: some View {
        ScrollViewReader { proxy in
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        if draft.isUnlisted {
                            Map(position: .constant(.region(.init(center: draft.values.coordinate,
                                span: .init(latitudeDelta: 0.003, longitudeDelta: 0.004)))), interactionModes: []) {
                                Marker("Selected spot", coordinate: draft.values.coordinate).tint(AppStyle.actionForeground)
                            }
                            .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
                            .frame(height: 150).clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Map of the selected location")
                            Button {
                                editingLocation = true; mapValues = draft.values; path.append(.location)
                            } label: {
                                Label("Change location", systemImage: "mappin.and.ellipse").frame(minHeight: 44)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                                Text(draft.displayName).font(.headline).fixedSize(horizontal: false, vertical: true)
                                Text(address(draft)).font(.subheadline).foregroundStyle(AppStyle.supportingText)
                            }
                            Button("Change place") { search = ""; path.append(.choose) }.frame(minHeight: 44)
                        }
                        fieldError(.location)
                    }.id(ContributionField.location)
                } header: { sectionHeading("Location") } footer: {
                    if usesRefinedLayout && draft.isUpdate {
                        Text("Change only what needs updating. Unchanged details won’t be submitted.")
                            .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                    }
                }

                Section {
                    if draft.sourceSetting {
                        LabeledContent("Indoors or outdoors?") {
                            Text(draft.values.setting?.rawValue ?? "Not known")
                                .foregroundStyle(AppStyle.supportingText)
                        }
                    } else {
                        environmentQuestion.id(ContributionField.setting)
                    }
                    if draft.isUnlisted {
                        VStack(alignment: .leading, spacing: 8) {
                            ContributionFieldLabel("Place name", requirement: "Required")
                            TextField("e.g. Shade beside the playground", text: $draft.values.name,
                                      prompt: Text("e.g. Shade beside the playground").foregroundStyle(AppStyle.supportingText), axis: .vertical)
                                .lineLimit(1...3).focused($focusedField, equals: .name)
                                .contributionTextInput(isFocused: focusedField == .name)
                                .accessibilityLabel("Place name, required")
                            fieldError(.name)
                        }.id(ContributionField.name)
                    }
                    DisclosureGroup(isExpanded: $areaExpanded) {
                        VStack(alignment: .leading, spacing: 8) {
                            if usesRefinedLayout {
                                contributionHelper("Help people find the cool area within this place.")
                            }
                            TextField("e.g. Reading room on the fourth floor", text: $draft.values.locationDetails,
                                      prompt: Text("e.g. Reading room on the fourth floor").foregroundStyle(AppStyle.supportingText), axis: .vertical)
                                .focused($focusedField, equals: .locationDetails)
                                .contributionTextInput(isFocused: focusedField == .locationDetails)
                                .lineLimit(1...4).accessibilityLabel("Specific cooling area, optional")
                        }
                    } label: {
                        if usesRefinedLayout { ContributionFieldLabel("Specific area") }
                        else { Text("Specific area · Optional") }
                    }.contributionDisclosureStyle()
                    if draft.sourceType {
                        LabeledContent(usesRefinedLayout ? "Current place type" : "Place type") {
                            Text((usesRefinedLayout ? draft.original.type : draft.values.type)?.rawValue ?? "Not known")
                                .foregroundStyle(AppStyle.supportingText)
                        }
                    } else {
                        ContributionPickerRow("Place type", selection: $draft.values.type, valueText: draft.values.type?.rawValue ?? "Not sure") {
                            Text("Not sure").tag(nil as PlaceType?)
                            ForEach(PlaceType.allCases.filter { $0 != .unknown }) { Text($0.rawValue).tag(Optional($0)) }
                        }
                    }
                    fieldError(.type).id(ContributionField.type)
                    if draft.sourceName {
                        DisclosureGroup("Name or place type is incorrect", isExpanded: $correctionExpanded) {
                            if usesRefinedLayout {
                                VStack(alignment: .leading, spacing: 20) {
                                    contributionHelper("Suggest a corrected name or place type.")
                                    correctionNameField
                                    if draft.sourceType { correctionTypePicker }
                                    correctionExplanationField
                                }
                            } else {
                                Text("Suggest a correction for Cool Spot.")
                                    .font(.footnote).foregroundStyle(AppStyle.supportingText)
                                correctionNameField
                                if draft.sourceType { correctionTypePicker }
                                correctionExplanationField
                            }
                        }.font(usesRefinedLayout ? .body : .subheadline)
                            .contributionDisclosureStyle()
                    }
                } header: { sectionHeading("About the place") }

                Section {
                    if usesRefinedLayout {
                        VStack(alignment: .leading, spacing: 8) {
                            coolingQuestion.padding(.top, 16)
                            CoolingFeatureChoices(selection: $draft.values.features, compactRows: true)
                        }.id(ContributionField.features)
                            .contributionInspectionGeometry("Cooling card content", enabled: true)
                    } else {
                        coolingQuestion.id(ContributionField.features)
                        CoolingFeatureChoices(selection: $draft.values.features)
                            .labelStyle(ContributionLeadingLabelStyle())
                    }
                    if draft.needsRemovalReason {
                        VStack(alignment: .leading, spacing: 8) {
                            ContributionFieldLabel("What changed?", requirement: "Required")
                            if usesRefinedLayout {
                                contributionHelper("Explain why these features no longer apply. Only reviewers see this explanation.")
                            }
                            TextField("Why should these cooling features be removed?", text: $draft.values.removalReason,
                                      prompt: Text("Why should these cooling features be removed?").foregroundStyle(AppStyle.supportingText), axis: .vertical)
                                .lineLimit(2...6).focused($focusedField, equals: .removalReason)
                                .contributionTextInput(isFocused: focusedField == .removalReason)
                                .accessibilityLabel("What changed? Required")
                            fieldError(.removalReason)
                        }.id(ContributionField.removalReason)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        ContributionFieldLabel("Photo", requirement: draft.isUnlisted ? "Required" : "Optional")
                        Text("Show a landmark or entrance so people can find the spot.")
                            .font(usesRefinedLayout ? .subheadline : .footnote).foregroundStyle(AppStyle.supportingText)
                        fieldError(.photo)
                        ContributionPhotoField(values: $draft.values, loading: $photoLoading)
                    }.id(ContributionField.photo)
                }

                Section {
                    if usesRefinedLayout {
                        VStack(alignment: .leading, spacing: 24) {
                            entryDisclosure
                            facilitiesDisclosure
                            additionalInformationField
                        }
                    } else {
                        entryDisclosure
                        facilitiesDisclosure
                        additionalInformationField
                    }
                } header: { sectionHeading("More details") }

                if draft.isUpdate {
                    if !draft.changes.isEmpty {
                        Section {
                            ForEach(draft.changes, id: \.self) { change in
                                if usesRefinedLayout && change == coolingFeatureChangeDescription {
                                    CoolingFeatureChangeSummary(original: draft.original.features,
                                                                proposed: draft.values.features)
                                } else {
                                    Text(change).font(usesRefinedLayout ? .body : .subheadline)
                                }
                            }
                        } header: { sectionHeading("Your changes") }
                    } else if validationAttempt > 0 {
                        Section { fieldError(.changes) }.id(ContributionField.changes)
                    }
                }
                if dynamicTypeSize.isAccessibilitySize { Section { sendBar } }
            }
            .listSectionSpacing(LayoutSpacing.section)
            .environment(\.defaultMinListRowHeight, 44)
            // Refined controls own their sizing inside grouped Form rows.
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .scrollDismissesKeyboard(.immediately)
            .onScrollPhaseChange { _, phase in
                if phase == .interacting || phase == .decelerating { focusedField = nil }
            }
            .onSubmit { focusedField = nil }
            .task(id: validationAttempt) {
                guard validationAttempt > 0, let first = draft.validationIssues.first else { return }
                if first.field == .name && draft.sourceName { correctionExpanded = true }
                // Let validation rows enter the Form before resolving their scroll IDs.
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    proxy.scrollTo(first.field, anchor: .top)
                }
                // Wait for the Form's lazy row to be visible before moving VoiceOver.
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                focusedError = first.field
            }
        }
    }
    // Isolate this display row using the existing formatter, without parsing its copy
    // or changing the real draft, change detection, validation or submission.
    private var coolingFeatureChangeDescription: String? {
        var featureOnlyDraft = draft
        featureOnlyDraft.values = draft.original
        featureOnlyDraft.values.features = draft.values.features
        return featureOnlyDraft.changes.first
    }
    private var coolingQuestion: some View {
        VStack(alignment: .leading, spacing: usesRefinedLayout ? 4 : 8) {
            ContributionFieldLabel("What helps people cool down?", requirement: draft.isUpdate ? nil : "Required", emphasized: true)
            if validationAttempt == 0 || !draft.validationIssues.contains(where: { $0.field == .features }) {
                Text(draft.isUpdate ? "Change only the features you can confirm." : "Choose at least one.")
                    .font(usesRefinedLayout ? .subheadline : .footnote).foregroundStyle(AppStyle.supportingText)
            }
            fieldError(.features)
        }
    }
    private var entryDisclosure: some View {
        DisclosureGroup("Entry and seating", isExpanded: $visitingExpanded) {
            if usesRefinedLayout { VStack(spacing: 0) { entryAndSeatingFields } }
            else { entryAndSeatingFields }
        }.contributionDisclosureStyle()
    }
    private var facilitiesDisclosure: some View {
        DisclosureGroup("Facilities", isExpanded: $facilitiesExpanded) {
            if usesRefinedLayout { VStack(spacing: 0) { facilityFields } }
            else { facilityFields }
        }.contributionDisclosureStyle()
    }
    private var additionalInformationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            ContributionFieldLabel("Anything else people should know?", requirement: "Optional")
            if usesRefinedLayout {
                contributionHelper("This will appear in the place information if approved.")
            }
            TextField(usesRefinedLayout ? "e.g. Use the entrance on the south side" : "Add a useful detail", text: $draft.values.note,
                      prompt: Text(usesRefinedLayout ? "e.g. Use the entrance on the south side" : "Add a useful detail").foregroundStyle(AppStyle.supportingText), axis: .vertical)
                .lineLimit(2...6).focused($focusedField, equals: .note)
                .contributionTextInput(isFocused: focusedField == .note)
                .accessibilityLabel("Anything else people should know? Optional")
        }
    }
    @ViewBuilder private var entryAndSeatingFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            ContributionPickerRow(usesRefinedLayout ? "Who can use it?" : "Who can use this spot?", selection: $draft.values.entryEligibility, valueText: draft.values.entryEligibility.rawValue) {
                ForEach(PlaceEntryEligibility.allCases) { Text($0.rawValue).tag($0) }
            }
            if draft.values.entryEligibility == .limited {
                Text(PlaceEntryEligibility.limitedExamples)
                    .font(.footnote).foregroundStyle(AppStyle.supportingText)
            }
        }
        if usesRefinedLayout { ContributionFormSeparator("Entry first separator") }
        ContributionPickerRow("Cost to use", selection: $draft.values.access, valueText: draft.values.access.rawValue) {
            ForEach(AccessType.allCases) { Text($0.rawValue).tag($0) }
        }
        if usesRefinedLayout { ContributionFormSeparator() }
        ContributionPickerRow("Seating", selection: $draft.values.seating, valueText: draft.values.seating == .unsure ? "Not added" : draft.values.seating.displayName) {
            ForEach(SeatingType.allCases) { Text($0 == .unsure ? "Not added" : $0.displayName).tag($0) }
        }
        if usesRefinedLayout { ContributionFormSeparator() }
        factPicker("Wheelchair accessible", value: $draft.values.wheelchairAccess)
        if usesRefinedLayout { ContributionFormSeparator() }
        PostedStayLimitPicker(value: $draft.values.stayLimit)
    }
    @ViewBuilder private var facilityFields: some View {
        ContributionPickerRow("Toilets", selection: $draft.values.toilets, valueText: draft.values.toilets.choiceLabel) {
            ForEach(PlaceInformation.Toilets.allCases) { Text($0.choiceLabel).tag($0) }
        }
        if usesRefinedLayout { ContributionFormSeparator("Facilities first separator") }
        factPicker("Staff on site when open", value: $draft.values.staffedWhenOpen)
        if usesRefinedLayout { ContributionFormSeparator() }
        factPicker("Tables", value: $draft.values.tables)
    }
    private func sectionHeading(_ title: String) -> some View {
        Text(title)
            .font(usesRefinedLayout ? .body.weight(.semibold) : nil)
            .foregroundStyle(usesRefinedLayout ? Color.primary : AppStyle.supportingText)
            .textCase(nil)
    }
    private func contributionHelper(_ text: String) -> some View {
        Text(text).font(.subheadline).foregroundStyle(AppStyle.supportingText)
            .fixedSize(horizontal: false, vertical: true)
    }
    private var correctionNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            ContributionFieldLabel("Suggested name", requirement: usesRefinedLayout ? "Required" : nil)
            TextField("Suggested name", text: $draft.values.name, axis: .vertical)
                .lineLimit(1...3).focused($focusedField, equals: .name)
                .contributionTextInput(isFocused: focusedField == .name)
                .accessibilityLabel("Suggested name, required", isEnabled: usesRefinedLayout)
            fieldError(.name)
        }.id(ContributionField.name)
            .contributionInspectionGeometry("Suggested name field", enabled: usesRefinedLayout)
    }
    private var correctionTypePicker: some View {
        ContributionPickerRow("Suggested place type", selection: $draft.values.type,
                              valueText: draft.values.type?.rawValue ?? "Choose a type", stackedValue: true) {
            ForEach(PlaceType.allCases.filter { $0 != .unknown }) { Text($0.rawValue).tag(Optional($0)) }
        }
    }
    private var correctionExplanationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            ContributionFieldLabel(usesRefinedLayout ? "Reason for correction" : "Additional details", requirement: "Optional")
            if usesRefinedLayout { contributionHelper("Only reviewers see this explanation.") }
            TextField("e.g. The sign outside uses this name", text: $draft.values.sourceCorrection,
                      prompt: Text("e.g. The sign outside uses this name").foregroundStyle(AppStyle.supportingText), axis: .vertical)
                .lineLimit(2...6).focused($focusedField, equals: .correction)
                .contributionTextInput(isFocused: focusedField == .correction)
                .accessibilityLabel("Reason for correction, optional", isEnabled: usesRefinedLayout)
        }
    }
    @ViewBuilder private func fieldError(_ field: ContributionField) -> some View {
        if validationAttempt > 0, let issue = draft.validationIssues.first(where: { $0.field == field }) {
            Label {
                Text(issue.message).foregroundStyle(.primary)
            } icon: {
                Image(systemName: "exclamationmark.circle").foregroundStyle(.red)
            }
                .font(usesRefinedLayout ? .subheadline : .footnote)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Error: \(issue.message)")
                .accessibilityFocused($focusedError, equals: field)
        }
    }
    func factPicker(_ title: String, value: Binding<OptionalFact>) -> some View {
        ContributionPickerRow(title, selection: value, valueText: value.wrappedValue.rawValue) {
            ForEach(OptionalFact.allCases) { Text($0.rawValue).tag($0) }
        }
    }
    private var environmentQuestion: some View {
        VStack(alignment: .leading, spacing: 8) {
            ContributionFieldLabel("Indoors or outdoors?", requirement: draft.isUpdate ? nil : "Required")
            if dynamicTypeSize.isAccessibilitySize {
                environmentOptions(vertical: true)
            } else {
                ViewThatFits(in: .horizontal) {
                    environmentOptions(vertical: false)
                    environmentOptions(vertical: true)
                }
            }
            fieldError(.setting)
        }
        .accessibilityElement(children: .contain)
    }
    private func environmentOptions(vertical: Bool) -> some View {
        let layout = vertical ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            ForEach(PlaceEnvironment.allCases.filter { $0 != .unknown }) { environment in
                let selected = draft.values.setting == environment
                // Buttons allow an unanswered question without adding a fourth
                // placeholder option or assigning a default on the user's behalf.
                Group {
                    if usesRefinedLayout {
                        environmentButton(environment, vertical: vertical)
                            .buttonStyle(.plain)
                    } else if selected {
                        environmentButton(environment, vertical: vertical)
                            .buttonStyle(.borderedProminent)
                    } else {
                        environmentButton(environment, vertical: vertical)
                            .buttonStyle(.bordered)
                    }
                }
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
    private func environmentButton(_ environment: PlaceEnvironment, vertical: Bool) -> some View {
        Button {
            focusedField = nil
            draft.values.setting = environment
        } label: {
            Text(environment.rawValue)
                .foregroundStyle(draft.values.setting == environment
                    ? Color.white : AppStyle.actionForeground)
                .fixedSize(horizontal: !vertical, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    if usesRefinedLayout {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(draft.values.setting == environment ? AppStyle.actionFill : Color(uiColor: .quaternarySystemFill))
                    }
                }
        }
        .accessibilityLabel("\(environment.rawValue), indoors or outdoors")
    }
    var sendBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            if photoLoading {
                Text("Finishing your photo…").font(.footnote).foregroundStyle(AppStyle.supportingText)
            }
            Button {
                focusedField = nil
                focusedError = nil
                guard draft.canSend else { validationAttempt += 1; return }
                if !draft.isUpdate, let existing = store.existingSpot(for: draft) {
                    duplicate = draft.reconciled(with: existing); showDuplicate = true
                } else if store.submitPlaceContribution(draft) { sent = true; path.append(.complete) }
                else { showFailure = true }
            } label: { Text("Send for review").frame(maxWidth: .infinity) }
            .buttonStyle(PrimaryButtonStyle()).disabled(photoLoading || sent)
        }
        .padding(16).frame(maxWidth: .infinity).background(.regularMaterial)
    }
}

// Use a stable icon column so large Dynamic Type cannot squeeze the first
// line into the icon's space. Scoped to this form; report rendering is unchanged.
private struct ContributionLeadingLabelStyle: LabelStyle {
    @ScaledMetric(relativeTo: .body) private var iconWidth = 24
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            configuration.icon.frame(width: iconWidth).accessibilityHidden(true)
            configuration.title
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension View {
    func contributionTextInput(isFocused: Bool) -> some View {
        modifier(ContributionTextInputStyle(isFocused: isFocused))
    }
    @ViewBuilder func contributionDisclosureStyle() -> some View {
        modifier(ContributionDisclosureModifier())
    }
    @ViewBuilder func contributionInspectionGeometry(_ label: String, enabled: Bool) -> some View {
        #if DEBUG
        let isLayoutInspection = ProcessInfo.processInfo.arguments.contains("--contribution-layout-preview")
            || Bundle.main.bundleIdentifier?.hasPrefix("com.chihyinwang.cool-spot.contribution-preview") == true
        if enabled && isLayoutInspection {
            self.onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                print("Contribution layout · \(label) · \(frame)")
            }
        } else { self }
        #else
        self
        #endif
    }
}

private struct ContributionTextInputStyle: ViewModifier {
    @Environment(\.usesRefinedContributionLayout) private var usesRefinedLayout
    let isFocused: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if usesRefinedLayout {
            content
                .font(.body).foregroundStyle(.primary)
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isFocused ? AppStyle.actionForeground : AppStyle.supportingText.opacity(0.45),
                                      lineWidth: isFocused ? 1.5 : 1)
                        .allowsHitTesting(false)
                }
        } else { content }
    }
}

private struct ContributionDisclosureModifier: ViewModifier {
    @Environment(\.usesRefinedContributionLayout) private var usesRefinedLayout
    @ViewBuilder func body(content: Content) -> some View {
        if usesRefinedLayout { content.disclosureGroupStyle(ContributionRefinedDisclosureStyle()) }
        else { content }
    }
}

// Keep native disclosure state/semantics while owning the refined layout's inner spacing.
private struct ContributionRefinedDisclosureStyle: DisclosureGroupStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    configuration.label.frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: configuration.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.subheadline.weight(.semibold)).accessibilityHidden(true)
                }
                .font(.body).foregroundStyle(.primary)
                .frame(minHeight: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(configuration.isExpanded ? "Expanded" : "Collapsed")
            if configuration.isExpanded {
                ContributionFormSeparator()
                configuration.content.padding(.top, 8)
            }
        }
    }
}

// A drawn separator stays inside our stack; Form cannot reinterpret it as a row separator.
private struct ContributionFormSeparator: View {
    @Environment(\.displayScale) private var displayScale
    private let inspectionLabel: String?
    init(_ inspectionLabel: String? = nil) { self.inspectionLabel = inspectionLabel }
    var body: some View {
        Rectangle().fill(Color(.separator))
            .frame(height: 1 / displayScale)
            .accessibilityHidden(true)
            .contributionInspectionGeometry(inspectionLabel ?? "Separator", enabled: inspectionLabel != nil)
    }
}

private struct ContributionRefinedLayoutKey: EnvironmentKey {
    // The accepted layout is shared by normal Register and Suggest an edit flows.
    // DEBUG comparison can still explicitly select the historical layout.
    static let defaultValue = true
}
extension EnvironmentValues {
    var usesRefinedContributionLayout: Bool {
        get { self[ContributionRefinedLayoutKey.self] }
        set { self[ContributionRefinedLayoutKey.self] = newValue }
    }
}

// Requirement text always belongs to a question, never a section heading.
private struct ContributionFieldLabel: View {
    @Environment(\.usesRefinedContributionLayout) private var usesRefinedLayout
    let title: String
    let requirement: String?
    let emphasized: Bool
    init(_ title: String, requirement: String? = "Optional", emphasized: Bool = false) {
        self.title = title; self.requirement = requirement; self.emphasized = emphasized
    }
    @ViewBuilder
    var body: some View {
        if usesRefinedLayout {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(emphasized ? .semibold : .regular))
                    .foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
                if let requirement {
                    Text(requirement).font(.footnote).foregroundStyle(AppStyle.supportingText)
                }
            }
        } else {
            (Text(title).font(.subheadline.weight(.semibold)) +
             Text(requirement.map { " · \($0)" } ?? "").font(.subheadline).foregroundColor(AppStyle.supportingText))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ContributionPickerRow<Selection: Hashable, Options: View>: View {
    let title: String
    @Binding var selection: Selection
    let options: Options
    let valueText: String
    let stackedValue: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.usesRefinedContributionLayout) private var usesRefinedLayout
    init(_ title: String, selection: Binding<Selection>, valueText: String, stackedValue: Bool = false,
         @ViewBuilder options: () -> Options) {
        self.title = title; _selection = selection; self.valueText = valueText
        self.stackedValue = stackedValue; self.options = options()
    }
    var body: some View {
        Group {
            if usesRefinedLayout {
                refinedMenu
            } else if dynamicTypeSize.isAccessibilitySize {
                stacked
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        ContributionFieldLabel(title).fixedSize().accessibilityHidden(true)
                        Spacer(minLength: 0)
                        picker.fixedSize()
                    }
                    stacked
                }
            }
        }
        .frame(minHeight: usesRefinedLayout ? 56 : 44)
        .contributionInspectionGeometry(title, enabled: usesRefinedLayout)
    }
    private var refinedMenu: some View {
        Menu {
            Picker(title, selection: $selection) { options }.pickerStyle(.inline)
        } label: {
            Group {
                if stackedValue {
                    stackedValueContent
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 16) {
                            refinedLabel.fixedSize(horizontal: true, vertical: true)
                            Spacer(minLength: 0)
                            refinedValue.fixedSize(horizontal: true, vertical: true)
                        }
                        stackedValueContent
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title).accessibilityValue(valueText).accessibilityHint("Optional")
    }
    private var stackedValueContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            refinedLabel
            if stackedValue {
                refinedValue.contributionTextInput(isFocused: false)
                    .contributionInspectionGeometry("Correction type control", enabled: usesRefinedLayout)
            } else {
                refinedValue.frame(minHeight: 44, alignment: .leading)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private var refinedLabel: some View {
        ContributionFieldLabel(title)
    }
    private var refinedValue: some View {
        HStack(spacing: 6) {
            Text(valueText).font(.body).multilineTextAlignment(.leading)
            if stackedValue { Spacer(minLength: 8) }
            Image(systemName: "chevron.up.chevron.down").font(.caption)
                .accessibilityHidden(true)
        }.foregroundStyle(AppStyle.actionForeground)
    }
    private var stacked: some View {
        VStack(alignment: .leading, spacing: 8) {
            ContributionFieldLabel(title).accessibilityHidden(true)
            picker
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private var picker: some View {
        Picker(title, selection: $selection) { options }
            .pickerStyle(.menu).labelsHidden()
            .accessibilityValue(valueText)
            .accessibilityHint("Optional")
    }
}

private struct CoolingFeatureChangeSummary: View {
    let original: Set<CoolingFeature>
    let proposed: Set<CoolingFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cooling features").font(.body.weight(.semibold))
            changeGroup("Add", symbol: "plus", features: proposed.subtracting(original))
            changeGroup("Remove", symbol: "minus", features: original.subtracting(proposed))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func changeGroup(_ title: String, symbol: String, features: Set<CoolingFeature>) -> some View {
        if !features.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(AppStyle.supportingText)
                ForEach(CoolingFeature.allCases.filter { features.contains($0) }) { feature in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: symbol).font(.caption.weight(.semibold))
                            .foregroundStyle(AppStyle.supportingText).frame(width: 16)
                            .accessibilityHidden(true)
                        Text(feature.rawValue).font(.body).foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}

enum PostedStayLimitChoice: String, CaseIterable, Identifiable {
    case notAdded = "Not added", unknown = "Not sure", none = "No stated limit"
    case halfHour = "30 minutes", hour = "1 hour", twoHours = "2 hours", other = "Other duration…"
    var id: Self { self }
}

struct PostedStayLimitPicker: View {
    @Binding var value: String
    @State private var hours = 1
    @State private var minutes = 30
    var choice: PostedStayLimitChoice {
        value.isEmpty ? .notAdded : PostedStayLimitChoice(rawValue: value) ?? .other
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ContributionPickerRow("Posted time limit", selection: Binding(get: { choice }, set: { selection in
                if selection == .other { writeDuration() }
                else { value = selection == .notAdded ? "" : selection.rawValue }
            }), valueText: choice == .other ? value : choice.rawValue) {
                ForEach(PostedStayLimitChoice.allCases) { Text($0.rawValue).tag($0) }
            }
        }
        if choice == .other {
            ContributionPickerRow("Hours", selection: $hours, valueText: String(hours)) { ForEach(0...24, id: \.self) { Text("\($0)").tag($0) } }
                .onChange(of: hours) { _, _ in writeDuration() }
            ContributionPickerRow("Minutes", selection: $minutes, valueText: String(minutes)) { ForEach(0...59, id: \.self) { Text("\($0)").tag($0) } }
                .onChange(of: minutes) { _, _ in writeDuration() }
            Text(value).font(.footnote).foregroundStyle(AppStyle.supportingText)
                .onAppear {
                    let parts = value.split(separator: " ")
                    if parts.count == 4, let h = Int(parts[0]), let m = Int(parts[2]) {
                        hours = h; minutes = m
                    }
                }
        }
    }
    private func writeDuration() {
        if hours == 0 && minutes == 0 { minutes = 1 }
        // Keep custom values distinct from preset raw values, so changing hours
        // does not collapse the minute control in the middle of editing.
        value = "\(hours) hr \(minutes) min"
    }
}

// Shared, inline multi-selection: short answers never require a separate page.
struct CoolingFeatureChoices: View {
    @Binding var selection: Set<CoolingFeature>
    var compactRows = false
    @ScaledMetric(relativeTo: .body) private var iconWidth = 24
    var body: some View {
        if compactRows {
            VStack(spacing: 0) {
                ForEach(CoolingFeature.allCases) { feature in
                    featureButton(feature)
                    if feature != CoolingFeature.allCases.last {
                        ContributionFormSeparator().padding(.leading, iconWidth + LayoutSpacing.text)
                    }
                }
            }
        } else {
            ForEach(CoolingFeature.allCases) { featureButton($0) }
        }
    }
    private func featureButton(_ feature: CoolingFeature) -> some View {
        Button {
            if selection.contains(feature) { selection.remove(feature) }
            else { selection.insert(feature) }
        } label: {
            HStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: LayoutSpacing.text) {
                    Image(systemName: feature.symbol)
                        .frame(width: iconWidth).accessibilityHidden(true)
                    Text(feature.rawValue)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }.foregroundStyle(.primary)
                Spacer(minLength: 8)
                Image(systemName: selection.contains(feature) ? "checkmark.circle.fill" : "circle")
                    .frame(width: iconWidth).accessibilityHidden(true)
                    .foregroundStyle(selection.contains(feature) ? AppStyle.actionForeground : .secondary)
            }.frame(minHeight: compactRows ? 56 : 44)
        }
        .buttonStyle(.borderless)
        .contributionInspectionGeometry(feature.rawValue, enabled: compactRows)
        .accessibilityAddTraits(selection.contains(feature) ? .isSelected : [])
    }
}

struct ContributionLocationEditor: View {
    @Binding var values: PlaceContributionValues
    let savedPin: Bool
    let onConfirm: () -> Void
    let onSearch: () -> Void
    @ScaledMetric(relativeTo: .body) private var mapHeight = 300
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                    Text(savedPin ? "Start with your saved pin" : "Where is the spot?").font(.title2.bold())
                    Text("Tap the exact spot on the map.").font(.subheadline).foregroundStyle(.secondary)
                }
                    .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                MapReader { proxy in
                    Map(initialPosition: .region(.init(center: values.coordinate, span: .init(latitudeDelta: 0.004, longitudeDelta: 0.004)))) {
                        Marker("Selected spot", coordinate: values.coordinate).tint(AppStyle.actionForeground)
                    }
                    .onTapGesture { point in
                        if let coordinate = proxy.convert(point, from: .local) {
                            values.latitude = coordinate.latitude; values.longitude = coordinate.longitude
                        }
                    }
                }.frame(height: mapHeight).clipShape(RoundedRectangle(cornerRadius: 16))
                Button { values.locationConfirmed = true; onConfirm() } label: {
                    Text("Use this spot").frame(maxWidth: .infinity)
                }.buttonStyle(PrimaryButtonStyle())
                Button("Search nearby places", action: onSearch).frame(minHeight: 44)
            }.padding(20)
        }
    }
}

struct ContributionPhotoField: View {
    @Binding var values: PlaceContributionValues
    @State private var selection: PhotosPickerItem?
    @Binding var loading: Bool
    @State private var failure = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let data = values.photo, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 220)
                    .accessibilityLabel("Selected place photo")
            }
            PhotosPicker(selection: $selection, matching: .images) {
                Label(values.photo == nil ? "Add photo" : "Replace photo", systemImage: "photo")
                    .frame(minHeight: 44)
            }
            .disabled(loading)
            if values.photo != nil {
                Button("Remove photo", role: .destructive) { values.photo = nil; selection = nil }.frame(minHeight: 44)
            }
            if loading { ProgressView("Loading photo…") }
        }
        .task(id: selection) {
            guard let selection else { return }
            loading = true
            defer { loading = false }
            do {
                guard let data = try await selection.loadTransferable(type: Data.self), !Task.isCancelled,
                      let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.8) else {
                    if !Task.isCancelled { failure = true }; return
                }
                values.photo = jpeg
            } catch { if !Task.isCancelled { failure = true } }
        }
        .alert("Photo couldn’t be loaded", isPresented: $failure) {
            Button("OK", role: .cancel) { selection = nil }
        } message: { Text("Your other answers are still here. Try another image.") }
    }
}

// Observe attempted native sheet dismissal so a swipe gets the same discard
// choice as Close. Back still belongs to NavigationStack and preserves answers.
private struct ContributionDismissObserver: UIViewControllerRepresentable {
    let hasChanges: Bool
    let onAttempt: () -> Void
    func makeUIViewController(context: Context) -> ObserverController { ObserverController() }
    func updateUIViewController(_ controller: ObserverController, context: Context) {
        controller.hasChanges = hasChanges
        controller.onAttempt = onAttempt
        DispatchQueue.main.async { controller.installIfPresented() }
    }
    static func dismantleUIViewController(_ controller: ObserverController, coordinator: ()) { controller.restoreDelegate() }

    final class ObserverController: UIViewController, UIAdaptivePresentationControllerDelegate {
        var hasChanges = false
        var onAttempt: (() -> Void)?
        weak var observed: UIPresentationController?
        weak var previous: UIAdaptivePresentationControllerDelegate?
        override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); installIfPresented() }
        override func didMove(toParent parent: UIViewController?) { super.didMove(toParent: parent); installIfPresented() }
        func installIfPresented() {
            var ancestor: UIViewController? = self
            while let controller = ancestor {
                if controller.presentingViewController != nil, let presentation = controller.presentationController {
                    if presentation.delegate !== self {
                        restoreDelegate()
                        observed = presentation; previous = presentation.delegate
                        presentation.delegate = self
                    }
                    return
                }
                ancestor = controller.parent
            }
        }
        func restoreDelegate() {
            if let observed, observed.delegate === self { observed.delegate = previous }
            observed = nil; previous = nil
        }
        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            !hasChanges && (previous?.presentationControllerShouldDismiss?(presentationController) ?? true)
        }
        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            if hasChanges { onAttempt?() }
            else { previous?.presentationControllerDidAttemptToDismiss?(presentationController) }
        }
        func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
            previous?.presentationControllerWillDismiss?(presentationController)
        }
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            previous?.presentationControllerDidDismiss?(presentationController)
        }
    }
}
