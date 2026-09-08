import MapKit
import SwiftUI
import PhotosUI

// Approved 2026-09-05: one public place form; minimum -> ready <-> optional.
// Private saved locations and visit reports are never edited by this flow.
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

enum PlaceContributionKind: Equatable { case recognised, missing, exact, update }
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
    var publicAccess = false
    var photoIdentifiesSpot = false
    var note = ""
    var sourceCorrection = ""
    var removalReason = ""
    var normalized: Self {
        var copy = self
        copy.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
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
            initial.locationConfirmed = true
        } else if let place {
            initial.name = place.name; initial.latitude = place.latitude; initial.longitude = place.longitude
            initial.type = place.hasTrustedType ? place.type : nil
            initial.setting = place.trustedSetting; initial.locationConfirmed = true
        } else if kind == .exact { initial.setting = .outdoors }
        values = initial; original = initial
    }
    var isUpdate: Bool { kind == .update }
    var isDirty: Bool { values != original }
    var displayName: String { kind == .exact ? "Unnamed outdoor spot" : values.name.trimmingCharacters(in: .whitespacesAndNewlines) }
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
        if kind == .exact {
            return values.setting == .outdoors && values.publicAccess && values.photo.flatMap { UIImage(data: $0) } != nil && values.photoIdentifiesSpot
        }
        return !displayName.isEmpty && values.type != nil
    }
    var requiredHint: String {
        if !values.locationConfirmed { return "Confirm the location to continue." }
        if kind != .exact && displayName.isEmpty { return "Add the public place name." }
        if values.setting == nil { return "Choose a setting. We don’t have a confirmed source value." }
        if kind != .exact && values.type == nil { return "Choose a place type." }
        if needsRemovalReason { return "Explain why these cooling features should be removed." }
        if !isUpdate && values.features.isEmpty { return "Choose at least one cooling feature." }
        if kind == .exact && !values.publicAccess { return "Confirm the public can legally enter this spot." }
        if kind == .exact && (values.photo == nil || !values.photoIdentifiesSpot) { return "Add a photo and confirm it identifies this exact spot." }
        return "Choose at least one detail to update."
    }
    var changes: [String] {
        let values = values.normalized
        let original = original.normalized
        var result: [String] = []
        if values.setting != original.setting { result.append("Setting: \(original.setting?.rawValue ?? "Unknown") → \(values.setting?.rawValue ?? "Unknown")") }
        if values.type != original.type { result.append("Type: \(original.type?.rawValue ?? "Unknown") → \(values.type?.rawValue ?? "Unknown")") }
        if values.features != original.features { result.append("Cooling features: \(Self.featureText(original.features)) → \(Self.featureText(values.features))") }
        if values.access != original.access { result.append("Entry: \(original.access.rawValue) → \(values.access.rawValue)") }
        if values.seating != original.seating { result.append("Seating: \(original.seating.rawValue) → \(values.seating.rawValue)") }
        if values.tables != original.tables { result.append("Tables: \(values.tables.rawValue)") }
        if values.stayLimit != original.stayLimit { result.append("Official stay limit: \(values.stayLimit)") }
        if values.accessibility != original.accessibility { result.append("Accessibility: \(values.accessibility)") }
        if values.toilets != original.toilets { result.append("Toilets: \(values.toilets.rawValue)") }
        if values.wifi != original.wifi { result.append("Wi-Fi: \(values.wifi.rawValue)") }
        if values.power != original.power { result.append("Power outlets: \(values.power.rawValue)") }
        if values.laptop != original.laptop { result.append("Laptop use welcome / allowed: \(values.laptop.rawValue)") }
        if values.photo != original.photo { result.append("Photo added") }
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
        apply(\.accessibility)
        apply(\.seating)
        apply(\.tables)
        apply(\.stayLimit)
        apply(\.toilets)
        apply(\.wifi)
        apply(\.power)
        apply(\.laptop)
        apply(\.photo)
        apply(\.note)
        apply(\.sourceCorrection)
        apply(\.removalReason)
        return update
    }
    static func featureText(_ features: Set<CoolingFeature>) -> String {
        features.isEmpty ? "None selected" : features.map(\.rawValue).sorted().joined(separator: ", ")
    }
}

enum PlaceContributionPage: Hashable {
    case choose, search, minimum, ready, basics, location, features, access, seating, facilities, photo, note, correction, complete
}

struct ContributionFlow: View {
    @ObservedObject var store: PrototypeStore
    let source: ContributionSource
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var draft: PlaceContributionDraft
    @State private var path: [PlaceContributionPage] = []
    @State private var pending: PlaceContributionDraft?
    @State private var showChange = false
    @State private var showClose = false
    @State private var showFailure = false
    @State private var duplicate: PlaceContributionDraft?
    @State private var showDuplicate = false
    @State private var search = ""
    @State private var sent = false
    @State private var rootPage: PlaceContributionPage

    init(store: PrototypeStore, source: ContributionSource) {
        self.store = store; self.source = source
        let anchor = source.anchor(current: store.currentCoordinate)
        let initial: PlaceContributionDraft
        switch source {
        case .recognisedPlace(let place):
            if let spot = store.existingSpot(for: place) {
                initial = .init(kind: .update, anchor: spot.coordinate, spot: spot)
            } else { initial = .init(kind: .recognised, anchor: place.coordinate, place: place) }
            rootPage = initial.isUpdate ? .ready : .minimum
        case .existingCoolSpot(let spot):
            initial = .init(kind: .update, anchor: spot.coordinate, spot: spot); rootPage = .ready
        case .exactSavedCoordinate:
            initial = .init(kind: .exact, anchor: anchor); rootPage = .minimum
        default:
            initial = .init(kind: .missing, anchor: anchor); rootPage = .choose
        }
        _draft = State(initialValue: initial)
    }
    var anchor: CLLocationCoordinate2D { source.anchor(current: store.currentCoordinate) }
    var currentPage: PlaceContributionPage { path.last ?? rootPage }

    var body: some View {
        NavigationStack(path: $path) {
            screen(rootPage)
                .navigationDestination(for: PlaceContributionPage.self) { screen($0) }
        }
        .tint(AppStyle.brand)
        .interactiveDismissDisabled(draft.isDirty && !sent)
        .background(ContributionDismissObserver(hasChanges: draft.isDirty && !sent) { showClose = true })
        .confirmationDialog("Discard this place contribution?", isPresented: $showClose, titleVisibility: .visible) {
            Button("Discard and close", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) {}
        } message: { Text("Nothing will be sent. Your saved places and private pins stay unchanged.") }
        .confirmationDialog("Start details for \(pending?.displayName.isEmpty == false ? pending!.displayName : "a different place")?",
                            isPresented: $showChange, titleVisibility: .visible) {
            Button("Change place") { if let pending { apply(pending) }; pending = nil }
            Button("Keep current place", role: .cancel) { pending = nil }
        } message: { Text("Cooling features, access, seating, photo and note must be confirmed again for the new place.") }
        .alert("This place is already a Cool Spot", isPresented: $showDuplicate) {
            Button("Review update") { if let duplicate { draft = duplicate; path = [.ready] }; duplicate = nil }
            Button("Keep editing", role: .cancel) { duplicate = nil }
        } message: { Text("Your proposed details will be kept for comparison with the existing place. Review the changes before sending an update.") }
        .alert("Not sent", isPresented: $showFailure) {
            Button("Keep editing", role: .cancel) {}
        } message: { Text("Your answers are still here. Check the required details and try again.") }
    }

    func screen(_ page: PlaceContributionPage) -> some View {
        pageContent(page)
            .navigationTitle(title(for: page))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if page == .choose || page == .minimum || page == .ready { Button("Close") { if draft.isDirty { showClose = true } else { dismiss() } } }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !dynamicTypeSize.isAccessibilitySize { sendBar(page) }
            }
    }

    func title(for page: PlaceContributionPage) -> String {
        switch page {
        case .choose: "Choose a place"
        case .search: "Search places"
        case .basics: "Place details"
        case .location: "Location"
        case .features: "Cooling features"
        case .access: "Entry and access"
        case .seating: "Seating and stay"
        case .facilities: "Other facilities"
        case .photo: "Photo"
        case .note: "Note"
        case .correction: "Correct source details"
        case .complete: "Sent for review"
        default: draft.isUpdate ? "Update place details" : "Add cooling information"
        }
    }

    @ViewBuilder func pageContent(_ page: PlaceContributionPage) -> some View {
        switch page {
        case .choose, .search: placeChooser(searching: page == .search)
        case .minimum: minimum
        case .ready: ready
        case .basics: Form { basics }
        case .location:
            ContributionLocationEditor(values: $draft.values)
        case .features: features
        case .access: access
        case .seating: seating
        case .facilities: facilities
        case .photo: ContributionPhotoEditor(values: $draft.values, required: draft.kind == .exact)
        case .note:
            Form { Section("Note · Optional") { TextField("Public note", text: $draft.values.note, axis: .vertical).lineLimit(4...10) } }
        case .correction:
            Form {
                Section("Source details") { Text(draft.original.name); Text(draft.original.type?.rawValue ?? "Type not supplied") }
                Section { TextField("What is incorrect, and what should it say?", text: $draft.values.sourceCorrection, axis: .vertical).lineLimit(4...10) }
                header: { Text("Report incorrect place details") }
                footer: { Text("This correction is included for review. It does not rename the source place or create another place.") }
            }
        case .complete:
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "paperplane.circle.fill").font(.largeTitle).foregroundStyle(AppStyle.brand)
                    Text("Sent for review").font(.largeTitle.bold())
                    Text("Your cooling information is not public yet.")
                    Text("Follow this in You → Places you’ve added or updated.")
                    Text("Prototype: stored for this session only. No information has been sent to a real review service.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("Done") { dismiss() }.buttonStyle(PrimaryButtonStyle())
                }.padding(24)
            }
        }
    }

    func placeChooser(searching: Bool) -> some View {
        List {
            if !searching {
                Section {
                    Map(initialPosition: .region(.init(center: anchor, span: .init(latitudeDelta: 0.008, longitudeDelta: 0.008)))) {
                        Marker(source.isSavedPin ? "Your saved pin" : "Example current location", coordinate: anchor)
                    }.frame(height: 160)
                    Text(source.isSavedPin ? "Suggestions are centred on your saved pin, not where you are now." : "Suggestions use the prototype’s example location. You can also search or choose a point on the map.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("Search all recognised places") { path.append(.search) }
                }
            } else {
                Section { TextField("Name, landmark or address", text: $search).autocorrectionDisabled() }
            }
            Section(searching ? "Place results" : "Nearby suggestions") {
                ForEach(candidates(searching: searching), id: \.identity) { candidate in
                    Button { select(candidate) } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(candidate.displayName).foregroundStyle(.primary)
                            Text(candidate.isUpdate ? "Already a Cool Spot · Update details" : "Recognised place")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text(distance(to: candidate.values.coordinate)).font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
                if candidates(searching: searching).isEmpty { Text("No recognised places found").foregroundStyle(.secondary) }
            }
            Section {
                Button("Add a missing named place") { select(.init(kind: .missing, anchor: anchor)) }
                Button("Use this exact unnamed spot") { select(.init(kind: .exact, anchor: anchor)) }
            } footer: { Text("Nearby suggestions do not confirm which place you mean. Search results are prototype examples.") }
        }
    }
    func candidates(searching: Bool) -> [PlaceContributionDraft] {
        let known = store.recognisedPlaces.filter { store.existingSpot(for: $0) == nil }.map {
            PlaceContributionDraft(kind: .recognised, anchor: $0.coordinate, place: $0)
        }
        let all = known + store.spots.map { PlaceContributionDraft(kind: .update, anchor: $0.coordinate, spot: $0) }
        return all.filter { !searching || search.isEmpty || $0.displayName.localizedCaseInsensitiveContains(search) ||
            address(for: $0).localizedCaseInsensitiveContains(search) }.sorted { metres(to: $0.values.coordinate) < metres(to: $1.values.coordinate) }
    }
    func address(for candidate: PlaceContributionDraft) -> String {
        if let id = candidate.spotID { return store.spot(id)?.address ?? "" }
        return store.recognisedPlaces.first { "place:\($0.id)" == candidate.identity }?.address ?? ""
    }
    func metres(to coordinate: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: anchor.latitude, longitude: anchor.longitude).distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
    func distance(to coordinate: CLLocationCoordinate2D) -> String {
        let value = metres(to: coordinate)
        return (value < 1000 ? "\(Int(value.rounded())) m" : String(format: "%.1f km", value / 1000)) + (source.isSavedPin ? " from saved pin" : " from example location")
    }
    func select(_ candidate: PlaceContributionDraft) {
        if candidate.identity == draft.identity {
            if currentPage == .choose || currentPage == .search { path.removeLast(min(path.count, currentPage == .search ? 2 : 1)) }
            return
        }
        if draft.isDirty { pending = candidate; showChange = true } else { apply(candidate) }
    }
    func apply(_ candidate: PlaceContributionDraft) {
        draft = candidate
        if rootPage == .choose { path = [candidate.isUpdate ? .ready : .minimum] }
        else { path = []; rootPage = candidate.isUpdate ? .ready : .minimum }
    }

    var minimum: some View {
        Form {
            Section { VStack(alignment: .leading, spacing: 12) { Text("Minimum details").font(.title2.bold()); Text("Complete these details, then send now or add more.").foregroundStyle(.secondary) } }
            basics
            Section {
                editRow("Cooling features", summary: PlaceContributionDraft.featureText(draft.values.features), page: .features)
                if draft.kind == .exact {
                    Toggle("The public can legally enter this spot", isOn: $draft.values.publicAccess)
                    editRow("Identifying photo · Required", summary: photoSummary, page: .photo)
                }
            }
            if !draft.canSend { Section { Text(draft.requiredHint).font(.footnote).foregroundStyle(.secondary) } }
            if dynamicTypeSize.isAccessibilitySize { Section { sendBar(.minimum) } }
        }
    }
    @ViewBuilder var basics: some View {
        Section("Place") {
            if draft.kind == .missing { TextField("Public place name", text: $draft.values.name) }
            else if draft.kind != .exact { sourceValue("Name", value: draft.displayName) }
            if draft.kind == .missing || draft.kind == .exact {
                editRow("Location", summary: draft.values.locationConfirmed ? "Confirmed on map" : "Confirm the exact point", page: .location)
            }
            if draft.kind == .exact { LabeledContent("Setting", value: "Outdoors") }
            else if draft.sourceSetting {
                sourceValue("Setting", value: draft.values.setting?.rawValue ?? "Unknown")
            } else {
                Picker("Setting", selection: $draft.values.setting) {
                    Text("Choose…").tag(nil as PlaceEnvironment?)
                    ForEach(PlaceEnvironment.allCases) { Text($0.rawValue).tag(Optional($0)) }
                }
            }
            if draft.kind != .exact {
                if draft.sourceType {
                    sourceValue("Type", value: draft.values.type?.rawValue ?? "Unknown")
                } else {
                    Picker("Place type", selection: $draft.values.type) {
                        Text("Choose…").tag(nil as PlaceType?)
                        ForEach(PlaceType.allCases) { Text($0.rawValue).tag(Optional($0)) }
                    }
                }
            }
        }
    }
    func sourceValue(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            LabeledContent(title, value: value)
            Text("From place source").font(.caption).foregroundStyle(.secondary)
        }
    }
    var ready: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(draft.canSend ? "Ready to send for review" : draft.isUpdate ? "Choose a detail to update" : "Check required details").font(.title2.bold())
                    if draft.canSend || !draft.isUpdate { Text(draft.canSend ? "You can send now, or add more details." : draft.requiredHint).foregroundStyle(.secondary) }
                }
            }
            Section {
                if draft.kind == .missing { editRow("Name", summary: draft.displayName, page: .basics) }
                else if draft.kind != .exact { LabeledContent("Name", value: draft.displayName) }
                if draft.kind == .exact { editRow("Location", summary: "Confirmed on map", page: .location); LabeledContent("Setting", value: "Outdoors") }
                else {
                    if draft.sourceSetting { LabeledContent("Setting", value: draft.values.setting?.rawValue ?? "Unknown") }
                    else { editRow("Setting", summary: draft.values.setting?.rawValue ?? "Choose…", page: .basics) }
                    if draft.sourceType { LabeledContent("Type", value: draft.values.type?.rawValue ?? "Unknown") }
                    else { editRow("Type", summary: draft.values.type?.rawValue ?? "Choose…", page: .basics) }
                }
                if draft.sourceName { Button("Report incorrect place details") { path.append(.correction) } }
            } header: {
                HStack { Text("Place"); Spacer(); Button("Change") { path.append(.choose) }.frame(minHeight: 44) }
            }
            Section("Cooling features") {
                editRow("Cooling features", summary: PlaceContributionDraft.featureText(draft.values.features), page: .features)
                if draft.kind == .exact {
                    Toggle("The public can legally enter this spot", isOn: $draft.values.publicAccess)
                    editRow("Identifying photo · Required", summary: photoSummary, page: .photo)
                }
            }
            if draft.isUpdate && !draft.changes.isEmpty {
                Section("Your changes") { ForEach(draft.changes, id: \.self) { Text($0).font(.subheadline) } }
            }
            Section {
                editRow("Entry and access", summary: accessSummary, page: .access)
                editRow("Seating and stay", summary: seatingSummary, page: .seating)
                editRow("Other facilities", summary: facilitySummary, page: .facilities)
                if draft.kind != .exact { editRow("Photo", summary: photoSummary, page: .photo) }
                editRow("Note", summary: draft.values.note, page: .note)
            } header: { Text("Add more details · Optional") }
            footer: { Text("Public only after review. Your private saved information is not included.") }
            if dynamicTypeSize.isAccessibilitySize { Section { sendBar(.ready) } }
        }
    }
    func editRow(_ title: String, summary: String, page: PlaceContributionPage) -> some View {
        Button { path.append(page) } label: {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    summaryLabel(title, summary: summary); Spacer(minLength: 8)
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(AppStyle.brand)
                }
                VStack(alignment: .leading, spacing: 6) { summaryLabel(title, summary: summary); Text("Change").foregroundStyle(AppStyle.brand) }
            }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }.foregroundStyle(.primary)
    }
    func summaryLabel(_ title: String, summary: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
            if !summary.isEmpty { Text(summary).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
        }
    }
    var photoSummary: String { draft.values.photo == nil ? "Not added" : draft.kind == .exact && !draft.values.photoIdentifiesSpot ? "Check that this photo identifies the spot" : "Added" }
    var accessSummary: String { [draft.values.access == .unsure ? "" : draft.values.access.rawValue, draft.values.accessibility].filter { !$0.isEmpty }.joined(separator: " · ") }
    var seatingSummary: String { [draft.values.seating == .unsure ? "" : draft.values.seating.rawValue, draft.values.tables == .unknown ? "" : "Tables: \(draft.values.tables.rawValue)", draft.values.stayLimit].filter { !$0.isEmpty }.joined(separator: " · ") }
    var facilitySummary: String {
        [("Toilets", draft.values.toilets), ("Wi-Fi", draft.values.wifi), ("Power outlets", draft.values.power), ("Laptop use", draft.values.laptop)]
            .filter { $0.1 != .unknown }.map { "\($0.0): \($0.1.rawValue)" }.joined(separator: " · ")
    }
    var features: some View {
        Form {
            Section {
                ForEach(CoolingFeature.allCases) { feature in
                    Button {
                        if draft.values.features.contains(feature) { draft.values.features.remove(feature) }
                        else { draft.values.features.insert(feature) }
                    } label: {
                        HStack { Label(feature.rawValue, systemImage: feature.symbol); Spacer(); Image(systemName: draft.values.features.contains(feature) ? "checkmark.circle.fill" : "circle") }
                            .frame(minHeight: 44)
                    }.foregroundStyle(.primary).accessibilityAddTraits(draft.values.features.contains(feature) ? .isSelected : [])
                }
            } header: { Text("What helps people cool down?") }
            footer: { Text("Choose what you can confirm. This describes the place, not how a particular visit felt.") }
            if draft.needsRemovalReason {
                Section { TextField("Why should these cooling features be removed?", text: $draft.values.removalReason, axis: .vertical) }
                header: { Text("Removal for review") }
                footer: { Text("You don’t need to choose an untrue replacement. Explain what changed so a reviewer can assess this place.") }
            }
        }
    }
    var access: some View {
        Form {
            Section("Entry and access · Optional") {
                Picker("Entry cost", selection: $draft.values.access) { ForEach(AccessType.allCases) { Text($0 == .unsure ? "Not added" : $0.rawValue).tag($0) } }
                TextField("Accessibility information", text: $draft.values.accessibility, axis: .vertical).lineLimit(3...8)
            }
            Section { Text("Public access does not necessarily mean free entry. Add only conditions you know; leave uncertain details blank.").font(.footnote).foregroundStyle(.secondary) }
        }
    }
    var seating: some View {
        Form {
            Section("Seating and stay · Optional") {
                Picker("Seating", selection: $draft.values.seating) { ForEach(SeatingType.allCases) { Text($0 == .unsure ? "Not added" : $0.rawValue).tag($0) } }
                factPicker("Tables available", value: $draft.values.tables)
                TextField("Known official stay limit", text: $draft.values.stayLimit, axis: .vertical).lineLimit(2...6)
            }
            Section { Text("A formal rule from the place, such as a posted limit. Don’t infer this from how long you or other visitors stayed.").font(.footnote).foregroundStyle(.secondary) }
        }
    }
    var facilities: some View {
        Form {
            Section("Other facilities · Optional") {
                factPicker("Toilets", value: $draft.values.toilets)
                factPicker("Wi-Fi", value: $draft.values.wifi)
                factPicker("Power outlets", value: $draft.values.power)
                factPicker("Laptop use welcome / allowed", value: $draft.values.laptop)
            }
            Section { Text("Power outlets do not mean laptop use is allowed. Leave information you don’t know as Not added.").font(.footnote).foregroundStyle(.secondary) }
        }
    }
    func factPicker(_ title: String, value: Binding<OptionalFact>) -> some View {
        Picker(title, selection: value) { ForEach(OptionalFact.allCases) { Text($0.rawValue).tag($0) } }
    }
    @ViewBuilder func sendBar(_ page: PlaceContributionPage) -> some View {
        if page == .minimum || page == .ready {
            Button {
                if page == .minimum { path.append(.ready) }
                else if !draft.isUpdate, let existing = store.existingSpot(for: draft) {
                    // Retain the answers; switch identity only after explicit confirmation.
                    duplicate = draft.reconciled(with: existing); showDuplicate = true
                } else if store.submitPlaceContribution(draft) { sent = true; path.append(.complete) }
                else { showFailure = true }
            } label: { Text(page == .minimum ? "Continue" : "Send for review").frame(maxWidth: .infinity) }
            .buttonStyle(PrimaryButtonStyle()).disabled(!draft.canSend)
                .padding(16).frame(maxWidth: .infinity).background(.regularMaterial)
        }
    }
}

struct ContributionLocationEditor: View {
    @Binding var values: PlaceContributionValues
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Confirm the location").font(.title2.bold())
                Text("Tap the map to position the public place pin. Your private saved pin stays unchanged.")
                MapReader { proxy in
                    Map(initialPosition: .region(.init(center: values.coordinate, span: .init(latitudeDelta: 0.004, longitudeDelta: 0.004)))) {
                        Marker("Public place location", coordinate: values.coordinate)
                    }
                    .onTapGesture { point in
                        if let coordinate = proxy.convert(point, from: .local) {
                            values.latitude = coordinate.latitude; values.longitude = coordinate.longitude; values.locationConfirmed = false
                        }
                    }
                }.frame(height: 280)
                LabeledContent("Latitude", value: String(format: "%.6f", values.latitude))
                LabeledContent("Longitude", value: String(format: "%.6f", values.longitude))
                Button("Use this location") { values.locationConfirmed = true; dismiss() }.buttonStyle(PrimaryButtonStyle())
            }.padding(20)
        }
    }
}

struct ContributionPhotoEditor: View {
    @Binding var values: PlaceContributionValues
    let required: Bool
    @State private var selection: PhotosPickerItem?
    @State private var loading = false
    @State private var failure = false
    var body: some View {
        Form {
            Section(required ? "Identifying photo · Required" : "Photo · Optional") {
                if let data = values.photo, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 240)
                        .accessibilityLabel("Selected place photo")
                    Button("Remove photo", role: .destructive) { values.photo = nil; values.photoIdentifiesSpot = false; selection = nil }
                }
                PhotosPicker(selection: $selection, matching: .images) { Label(values.photo == nil ? "Choose photo" : "Replace photo", systemImage: "photo") }
                if loading { ProgressView("Loading photo…") }
                if required && values.photo != nil { Toggle("This photo clearly identifies the exact spot", isOn: $values.photoIdentifiesSpot) }
            }
            Section { Text("The photo and place will be reviewed together. Prototype: selected photos stay in this session and are not uploaded.").font(.footnote).foregroundStyle(.secondary) }
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
                values.photo = jpeg; values.photoIdentifiesSpot = false
            } catch { if !Task.isCancelled { failure = true } }
        }
        .alert("Photo couldn’t be loaded", isPresented: $failure) {
            Button("Choose another photo", role: .cancel) { selection = nil }
        } message: { Text("Your other answers are still here. Try choosing the photo again or use another image.") }
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
