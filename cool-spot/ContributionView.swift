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

enum PlaceContributionKind: Equatable { case recognised, missing, exact, unlisted, update }
enum OptionalFact: String, CaseIterable, Identifiable {
    case unknown = "Not added", yes = "Yes", no = "No"
    var id: Self { self }
}

struct PlaceContributionValues: Equatable {
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
    var stayLimit = ""
    var toilets: OptionalFact = .unknown
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

struct PlaceContributionDraft: Identifiable, Equatable {
    let id = UUID()
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
        self.kind = kind
        spotID = spot?.id
        identity = spot.map { "spot:\($0.id)" } ?? place.map { "place:\($0.id)" } ?? UUID().uuidString
        sourceName = place != nil || spot != nil
        sourceType = spot != nil || place?.hasTrustedType == true
        sourceSetting = place?.trustedSetting != nil
        var initial = PlaceContributionValues(latitude: anchor.latitude, longitude: anchor.longitude)
        if let spot {
            initial.name = spot.name; initial.latitude = spot.latitude; initial.longitude = spot.longitude
            initial.type = spot.type; initial.setting = spot.environment
            initial.features = Set(spot.features); initial.access = spot.access; initial.seating = spot.seating
            initial.entryEligibility = spot.entryEligibility
            initial.entryRequirement = spot.entryEligibility == .limited ? spot.entryRequirement : ""
            initial.accessibility = spot.entryInformation
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
    var canSend: Bool {
        guard CLLocationCoordinate2DIsValid(values.coordinate), values.locationConfirmed else { return false }
        if isUpdate {
            guard !changes.isEmpty else { return false }
            if values.setting != original.setting && values.setting == nil { return false }
            if values.type != original.type && values.type == nil { return false }
            if values.photo != original.photo, let photo = values.photo, UIImage(data: photo) == nil { return false }
            return !needsRemovalReason || !values.normalized.removalReason.isEmpty
        }
        guard values.setting != nil, !values.features.isEmpty else { return false }
        if let photo = values.photo, UIImage(data: photo) == nil { return false }
        if isExactSpot {
            return values.photo.flatMap { UIImage(data: $0) } != nil
        }
        return !values.normalized.name.isEmpty
    }
    var requiredHint: String {
        if !values.locationConfirmed { return "Confirm the location to continue." }
        if values.setting == nil { return "Choose indoors, outdoors or both." }
        if needsRemovalReason { return "Explain why these cooling features should be removed." }
        if !isUpdate && values.features.isEmpty { return "Choose at least one cooling feature." }
        if isExactSpot && values.photo.flatMap({ UIImage(data: $0) }) == nil { return "Add a photo that helps people find this spot." }
        return "Choose at least one detail to update."
    }
    var changes: [String] {
        let values = values.normalized
        let original = original.normalized
        var result: [String] = []
        if values.setting != original.setting { result.append("Setting: \(original.setting?.rawValue ?? "Unknown") → \(values.setting?.rawValue ?? "Unknown")") }
        if values.type != original.type { result.append("Type: \(original.type?.rawValue ?? "Unknown") → \(values.type?.rawValue ?? "Unknown")") }
        if values.features != original.features { result.append("Cooling features: \(Self.featureText(original.features)) → \(Self.featureText(values.features))") }
        if values.access != original.access { result.append("Cost to use: \(original.access.rawValue) → \(values.access.rawValue)") }
        if values.entryEligibility != original.entryEligibility { result.append("Who can use it: \(values.entryEligibility.rawValue)") }
        if values.entryRequirement != original.entryRequirement { result.append("Who it is limited to: \(values.entryRequirement.isEmpty ? "Not added" : values.entryRequirement)") }
        if values.seating != original.seating { result.append("Seating: \(original.seating.rawValue) → \(values.seating.rawValue)") }
        if values.tables != original.tables { result.append("Tables: \(values.tables.rawValue)") }
        if values.stayLimit != original.stayLimit { result.append("Time limit: \(values.stayLimit.isEmpty ? "Not added" : values.stayLimit)") }
        if values.accessibility != original.accessibility { result.append("Tickets and booking: \(values.accessibility.isEmpty ? "Not added" : values.accessibility)") }
        if values.toilets != original.toilets { result.append("Toilets: \(values.toilets.rawValue)") }
        if values.wifi != original.wifi { result.append("Wi-Fi: \(values.wifi.rawValue)") }
        if values.power != original.power { result.append("Power outlets: \(values.power.rawValue)") }
        if values.laptop != original.laptop { result.append("Laptop use welcome / allowed: \(values.laptop.rawValue)") }
        if values.photo != original.photo { result.append("Photo added") }
        if values.locationDetails != original.locationDetails { result.append("How to find it: \(values.locationDetails)") }
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
        apply(\.setting)
        apply(\.type)
        apply(\.features)
        apply(\.access)
        apply(\.entryEligibility)
        apply(\.entryRequirement)
        apply(\.accessibility)
        apply(\.seating)
        apply(\.tables)
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
    @State private var sent = false
    @State private var visitingExpanded = false
    @State private var facilitiesExpanded = false
    @State private var correctionExpanded = false
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
        .tint(AppStyle.brand)
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
                    Image(systemName: "paperplane.circle.fill").font(.largeTitle).foregroundStyle(AppStyle.brand)
                    Text("Thanks for helping others find a cool spot").font(.title2.bold())
                    Text("Your information is waiting for review. It isn’t public yet.")
                    Text("Follow it in You → Places you’ve added or updated.")
                    Text("Prototype: saved for this session. No real review service is connected.")
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
                }
                Button { openMap() } label: { Label("Choose a spot on the map", systemImage: "mappin.and.ellipse") }
                    .frame(minHeight: 44)
            } footer: {
                Text("Choose where you want to add cooling information.").foregroundStyle(AppStyle.supportingText)
            }
            Section {
                ForEach(candidates, id: \.identity) { candidate in
                    Button { select(candidate) } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(candidate.displayName).font(.body).foregroundStyle(.primary)
                            Text(candidate.isUpdate ? "Already on Cool Spot · Update information" : "Add cooling information")
                                .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                            Text("\(address(candidate)) · \(distance(candidate))")
                                .font(.caption).foregroundStyle(AppStyle.supportingText)
                        }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
                if candidates.isEmpty {
                    ContentUnavailableView.search(text: search)
                    Text("Try another name or choose the location on the map above.").font(.subheadline)
                }
            } header: { Text(search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Nearby places" : "Search results").foregroundStyle(AppStyle.supportingText) }
            footer: { Text("Prototype example places. Nearby does not mean this is a confirmed cooling place.").foregroundStyle(AppStyle.supportingText) }
        }
        .scrollDismissesKeyboard(.interactively)
    }
    var candidates: [PlaceContributionDraft] {
        let known = store.recognisedPlaces.filter { store.existingSpot(for: $0) == nil }.map {
            PlaceContributionDraft(kind: .recognised, anchor: $0.coordinate, place: $0)
        }
        let all = known + store.spots.map { PlaceContributionDraft(kind: .update, anchor: $0.coordinate, spot: $0) }
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return all.filter { query.isEmpty || $0.displayName.localizedCaseInsensitiveContains(query) || address($0).localizedCaseInsensitiveContains(query) }
            .sorted { metres($0.values.coordinate) < metres($1.values.coordinate) }
    }
    func address(_ candidate: PlaceContributionDraft) -> String {
        if let id = candidate.spotID { return store.spot(id)?.address ?? "" }
        return store.recognisedPlaces.first { "place:\($0.id)" == candidate.identity }?.address ?? ""
    }
    func metres(_ coordinate: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: anchor.latitude, longitude: anchor.longitude)
            .distance(from: .init(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
    func distance(_ candidate: PlaceContributionDraft) -> String {
        let value = metres(candidate.values.coordinate)
        return (value < 1000 ? "\(Int(value.rounded())) m" : String(format: "%.1f km", value / 1000)) +
            (source.isSavedPin ? " from your pin" : " from example location")
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
        if candidate.identity == draft.identity { showDetails(); return }
        if draft.isDirty { pending = candidate; showChange = true }
        else { apply(candidate) }
    }
    func apply(_ candidate: PlaceContributionDraft) {
        draft = candidate; mapValues = candidate.values
        showDetails()
    }
    func showDetails() {
        if rootPage == .details { path.removeAll() }
        else { path = [.details] }
    }

    var details: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    if draft.isUnlisted {
                        Map(position: .constant(.region(.init(center: draft.values.coordinate,
                            span: .init(latitudeDelta: 0.003, longitudeDelta: 0.004)))), interactionModes: []) {
                            Marker("Selected spot", coordinate: draft.values.coordinate).tint(AppStyle.brand)
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
                        Text(draft.displayName).font(.headline).fixedSize(horizontal: false, vertical: true)
                        Text(address(draft)).font(.subheadline).foregroundStyle(AppStyle.supportingText)
                        Button("Change place") { search = ""; path.append(.choose) }.frame(minHeight: 44)
                    }
                }
            } header: { Text("Location").foregroundStyle(AppStyle.supportingText) }
            footer: { Text("Public after review. Your private saved notes stay private.").foregroundStyle(AppStyle.supportingText) }

            Section {
                if draft.sourceSetting {
                    LabeledContent("Indoors or outdoors?") {
                        Text(draft.values.setting?.rawValue ?? "Not known")
                            .foregroundStyle(AppStyle.supportingText)
                    }
                } else {
                    environmentQuestion
                }
                if draft.isUnlisted {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Place name · Optional").font(.subheadline.weight(.semibold))
                        TextField("e.g. Riverside Library", text: $draft.values.name,
                                  prompt: Text("e.g. Riverside Library").foregroundStyle(AppStyle.supportingText))
                            .focused($focusedField, equals: .name)
                            .accessibilityLabel("Place name, optional")
                        Text("Use the name people know.")
                            .font(.footnote).foregroundStyle(AppStyle.supportingText)
                    }.padding(.vertical, 4)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to find this spot · Optional").font(.subheadline.weight(.semibold))
                    TextField("e.g. Fourth floor, by the windows", text: $draft.values.locationDetails,
                              prompt: Text("e.g. Fourth floor, by the windows").foregroundStyle(AppStyle.supportingText), axis: .vertical)
                        .focused($focusedField, equals: .locationDetails)
                        .lineLimit(1...4).accessibilityLabel("How to find this spot, optional")
                }.padding(.vertical, 4)
                if draft.sourceType {
                    LabeledContent("Place type") { Text(draft.values.type?.rawValue ?? "Not known").foregroundStyle(AppStyle.supportingText) }
                } else {
                    Picker("Place type · Optional", selection: $draft.values.type) {
                        Text("Not sure").tag(nil as PlaceType?)
                        ForEach(PlaceType.allCases) { Text($0.rawValue).tag(Optional($0)) }
                    }
                }
                if draft.sourceName {
                    DisclosureGroup("Name or place type is incorrect", isExpanded: $correctionExpanded) {
                        TextField("What should be corrected?", text: $draft.values.sourceCorrection, prompt: Text("What should be corrected?").foregroundStyle(AppStyle.supportingText), axis: .vertical).lineLimit(2...6)
                            .focused($focusedField, equals: .correction)
                    }.font(.subheadline)
                }
            } header: { Text("About the place").foregroundStyle(AppStyle.supportingText) }

            Section {
                CoolingFeatureChoices(selection: $draft.values.features)
                if draft.needsRemovalReason {
                    TextField("What changed? Explain why the cooling features should be removed.", text: $draft.values.removalReason, prompt: Text("What changed? Explain why the cooling features should be removed.").foregroundStyle(AppStyle.supportingText), axis: .vertical).lineLimit(2...6)
                        .focused($focusedField, equals: .removalReason)
                }
            } header: { Text("What helps people cool down?").foregroundStyle(AppStyle.supportingText) }
            footer: { Text(draft.isUpdate ? "Change only what you know. Existing details are already selected." : "Choose at least one feature you can confirm.").foregroundStyle(AppStyle.supportingText) }

            if draft.isExactSpot {
                Section {
                    ContributionPhotoField(values: $draft.values, required: true, loading: $photoLoading)
                } header: { Text("Help people find this spot · Required").foregroundStyle(AppStyle.supportingText) }
                footer: { Text("A photo is required for a spot without a place name. The location and photo are reviewed together.").foregroundStyle(AppStyle.supportingText) }
            }

            Section {
                DisclosureGroup("Entry and seating", isExpanded: $visitingExpanded) {
                    VStack(alignment: .leading, spacing: 8) {
                        entryQuestion("Who can use this spot?") { entryEligibilityPicker }
                        Text(PlaceEntryEligibility.limitedExamples)
                            .font(.footnote).foregroundStyle(AppStyle.supportingText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    entryQuestion("Cost to use") { entryCostPicker }
                    Picker("Seating", selection: $draft.values.seating) {
                        ForEach(SeatingType.allCases) { Text($0 == .unsure ? "Not added" : $0.rawValue).tag($0) }
                    }
                    factPicker("Tables", value: $draft.values.tables)
                    PostedStayLimitPicker(value: $draft.values.stayLimit)
                }
                DisclosureGroup("Other facilities", isExpanded: $facilitiesExpanded) {
                    factPicker("Toilets", value: $draft.values.toilets)
                    factPicker("Wi-Fi", value: $draft.values.wifi)
                    factPicker("Power outlets", value: $draft.values.power)
                    factPicker("Laptop use allowed", value: $draft.values.laptop)
                }
                TextField("Anything else people should know?", text: $draft.values.note, prompt: Text("Anything else people should know?").foregroundStyle(AppStyle.supportingText), axis: .vertical).lineLimit(2...6)
                    .focused($focusedField, equals: .note)
            } header: { Text("More details · Optional").foregroundStyle(AppStyle.supportingText) }
            footer: { Text("Leave anything you don’t know blank. A visit’s duration is different from a posted stay limit.").foregroundStyle(AppStyle.supportingText) }

            if !draft.isExactSpot {
                Section { ContributionPhotoField(values: $draft.values, required: false, loading: $photoLoading) }
                header: { Text("Photo · Optional").foregroundStyle(AppStyle.supportingText) }
            }
            if draft.isUpdate && !draft.changes.isEmpty {
                Section("Your changes") { ForEach(draft.changes, id: \.self) { Text($0).font(.subheadline) } }
            }
            if dynamicTypeSize.isAccessibilitySize { Section { sendBar } }
        }
        // End editing when leaving a field, including with a hardware keyboard.
        // Otherwise a Picker can restore off-screen text focus and jump the Form.
        .scrollDismissesKeyboard(.immediately)
        .onScrollPhaseChange { _, phase in
            if phase == .interacting || phase == .decelerating { focusedField = nil }
        }
        .onSubmit { focusedField = nil }
    }
    func factPicker(_ title: String, value: Binding<OptionalFact>) -> some View {
        Picker(title, selection: value) { ForEach(OptionalFact.allCases) { Text($0.rawValue).tag($0) } }
    }
    private var environmentQuestion: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(draft.isUpdate ? "Indoors or outdoors?" : "Indoors or outdoors? · Required")
                .font(.subheadline.weight(.semibold))
            if dynamicTypeSize.isAccessibilitySize {
                environmentOptions(vertical: true)
            } else {
                ViewThatFits(in: .horizontal) {
                    environmentOptions(vertical: false)
                    environmentOptions(vertical: true)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
    }
    private func environmentOptions(vertical: Bool) -> some View {
        let layout = vertical ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            ForEach(PlaceEnvironment.allCases) { environment in
                let selected = draft.values.setting == environment
                // Buttons allow an unanswered question without adding a fourth
                // placeholder option or assigning a default on the user's behalf.
                Group {
                    if selected {
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
                    ? Color(uiColor: .systemBackground) : AppStyle.brand)
                .fixedSize(horizontal: !vertical, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .accessibilityLabel("\(environment.rawValue), indoors or outdoors")
    }
    @ViewBuilder
    private func entryQuestion<Content: View>(_ title: String, @ViewBuilder picker: () -> Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                picker().pickerStyle(.inline).labelsHidden()
            }
        } else {
            ViewThatFits(in: .horizontal) {
                // The native picker already includes horizontal control padding.
                HStack(spacing: 0) {
                    Text(title).fixedSize().accessibilityHidden(true)
                    Spacer(minLength: 0)
                    picker().labelsHidden().fixedSize()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(title).accessibilityHidden(true)
                    picker().labelsHidden()
                }
            }
        }
    }
    private var entryEligibilityPicker: some View {
        Picker("Who can use this spot?", selection: $draft.values.entryEligibility) {
            ForEach(PlaceEntryEligibility.allCases) {
                Text($0.rawValue).fixedSize(horizontal: false, vertical: true).tag($0)
            }
        }
    }
    private var entryCostPicker: some View {
        Picker("Cost to use", selection: $draft.values.access) {
            ForEach(AccessType.allCases) {
                Text($0.rawValue).fixedSize(horizontal: false, vertical: true).tag($0)
            }
        }
    }
    var sendBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            if photoLoading { Text("Finishing your photo…").font(.footnote).foregroundStyle(AppStyle.supportingText) }
            else if !draft.canSend { Text(draft.requiredHint).font(.footnote).foregroundStyle(AppStyle.supportingText).fixedSize(horizontal: false, vertical: true) }
            Button {
                if !draft.isUpdate, let existing = store.existingSpot(for: draft) {
                    duplicate = draft.reconciled(with: existing); showDuplicate = true
                } else if store.submitPlaceContribution(draft) { sent = true; path.append(.complete) }
                else { showFailure = true }
            } label: { Text("Send for review").frame(maxWidth: .infinity) }
            .buttonStyle(PrimaryButtonStyle()).disabled(!draft.canSend || photoLoading)
        }
        .padding(16).frame(maxWidth: .infinity).background(.regularMaterial)
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
        Picker("Time limit", selection: Binding(get: { choice }, set: { selection in
            if selection == .other { writeDuration() }
            else { value = selection == .notAdded ? "" : selection.rawValue }
        })) {
            ForEach(PostedStayLimitChoice.allCases) { Text($0.rawValue).tag($0) }
        }
        if choice == .other {
            Picker("Hours", selection: $hours) { ForEach(0...24, id: \.self) { Text("\($0)").tag($0) } }
                .onChange(of: hours) { _, _ in writeDuration() }
            Picker("Minutes", selection: $minutes) { ForEach(0...59, id: \.self) { Text("\($0)").tag($0) } }
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
    var body: some View {
        ForEach(CoolingFeature.allCases) { feature in
            Button {
                if selection.contains(feature) { selection.remove(feature) }
                else { selection.insert(feature) }
            } label: {
                HStack(spacing: 12) {
                    Label(feature.rawValue, systemImage: feature.symbol).foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Image(systemName: selection.contains(feature) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selection.contains(feature) ? AppStyle.brand : .secondary)
                }.frame(minHeight: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityAddTraits(selection.contains(feature) ? .isSelected : [])
        }
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
                Text(savedPin ? "Start with your saved pin" : "Where is the spot?").font(.title2.bold())
                Text("Move around the map, then tap the exact spot you want to share.")
                    .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                MapReader { proxy in
                    Map(initialPosition: .region(.init(center: values.coordinate, span: .init(latitudeDelta: 0.004, longitudeDelta: 0.004)))) {
                        Marker("Selected spot", coordinate: values.coordinate).tint(AppStyle.brand)
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
                if savedPin { Text("Your original saved pin and private notes stay unchanged.").font(.footnote).foregroundStyle(AppStyle.supportingText) }
            }.padding(20)
        }
    }
}

struct ContributionPhotoField: View {
    @Binding var values: PlaceContributionValues
    let required: Bool
    @State private var selection: PhotosPickerItem?
    @Binding var loading: Bool
    @State private var failure = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if required {
                Text("Show a landmark or entrance so someone else can find the same spot.")
                    .font(.subheadline).foregroundStyle(AppStyle.supportingText)
            }
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
