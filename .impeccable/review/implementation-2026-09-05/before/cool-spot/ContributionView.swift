import MapKit
import SwiftUI

enum ContributionSource {
    case currentLocation
    case savedCoordinate(SavedLocation)
    case exactSavedCoordinate(SavedLocation)
    case recognisedPlace(RecognisedPlace)
    case existingCoolSpot(CoolSpot)

    var needsMatch: Bool {
        switch self {
        case .currentLocation, .savedCoordinate: true
        case .exactSavedCoordinate, .recognisedPlace, .existingCoolSpot: false
        }
    }
    var isUpdate: Bool {
        if case .existingCoolSpot = self { true } else { false }
    }
    var initialName: String {
        switch self {
        case .currentLocation, .savedCoordinate, .exactSavedCoordinate: ""
        case .recognisedPlace(let place): place.name
        case .existingCoolSpot(let spot): spot.name
        }
    }
}

enum ContributionStep: Int {
    case match, basics, features, access, evidence, review, complete
}

struct ContributionFlow: View {
    @ObservedObject var store: PrototypeStore
    let source: ContributionSource
    @Environment(\.dismiss) private var dismiss
    @State private var step: ContributionStep
    @State private var matchedPlace: RecognisedPlace?
    @State private var exactSpot = false
    @State private var missingNamedPlace = false
    @State private var placeSearch = ""
    @State private var name: String
    @State private var environment: PlaceEnvironment = .indoors
    @State private var type: PlaceType = .library
    @State private var features: Set<CoolingFeature> = []
    @State private var access: AccessType = .unsure
    @State private var seating: SeatingType = .unsure
    @State private var hasPhoto = false
    @State private var publicAccessConfirmed = false
    @State private var note = ""

    init(store: PrototypeStore, source: ContributionSource) {
        self.store = store
        self.source = source
        let initialStep: ContributionStep
        if case .exactSavedCoordinate = source {
            initialStep = .basics
        } else {
            initialStep = source.needsMatch ? .match : .features
        }
        _step = State(initialValue: initialStep)
        _name = State(initialValue: source.initialName)
        switch source {
        case .recognisedPlace(let place):
            _type = State(initialValue: place.type)
        case .existingCoolSpot(let spot):
            _type = State(initialValue: spot.type)
            _environment = State(initialValue: spot.environment)
            _features = State(initialValue: Set(spot.features))
            _access = State(initialValue: spot.access)
            _seating = State(initialValue: spot.seating)
        case .exactSavedCoordinate:
            _exactSpot = State(initialValue: true)
            _environment = State(initialValue: .outdoors)
            _type = State(initialValue: .park)
        default: break
        }
    }

    var visibleSteps: [ContributionStep] {
        if source.needsMatch {
            return exactSpot || missingNamedPlace
                ? [.match, .basics, .features, .review]
                : [.match, .features, .review]
        }
        return exactSpot ? [.basics, .features, .review] : [.features, .review]
    }
    var progress: Double {
        guard let index = visibleSteps.firstIndex(of: step) else { return 1 }
        return Double(index + 1) / Double(visibleSteps.count)
    }
    var photoRequired: Bool { exactSpot }
    var visiblePlaceMatches: [RecognisedPlace] {
        guard !placeSearch.isEmpty else { return store.recognisedPlaces }
        return store.recognisedPlaces.filter {
            $0.name.localizedCaseInsensitiveContains(placeSearch) ||
            $0.address.localizedCaseInsensitiveContains(placeSearch)
        }
    }
    var canContinue: Bool {
        switch step {
        case .match: matchedPlace != nil || exactSpot || missingNamedPlace
        case .basics: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .features:
            !features.isEmpty && (!photoRequired || hasPhoto) && (!exactSpot || publicAccessConfirmed)
        case .evidence: !photoRequired || hasPhoto
        default: true
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .match: matchStep
                case .basics: basicsStep
                case .features: featuresStep
                case .access: accessStep
                case .evidence: evidenceStep
                case .review: reviewStep
                case .complete: completeStep
                }
            }
            .navigationTitle(step == .complete ? "Sent" : source.isUpdate ? "Edit place details" : "Add cooling information")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) { bottomBar }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step != .complete { Button("Cancel") { dismiss() } }
                }
            }
        }
    }

    @ViewBuilder var bottomBar: some View {
        if step != .complete {
            VStack(spacing: 10) {
                ProgressView(value: progress).tint(AppStyle.brand)
                HStack(spacing: 12) {
                    if step != visibleSteps.first {
                        Button("Back") { move(-1) }.buttonStyle(.bordered)
                    }
                    Spacer()
                    Button(step == .review ? "Send for review" : "Continue") {
                        if step == .review {
                            store.submitContribution(title: name.isEmpty ? "Unnamed cooling place" : name,
                                                     kind: source.isUpdate ? .placeUpdate : .newPlace)
                            step = .complete
                        } else { move(1) }
                    }
                    .buttonStyle(.borderedProminent).tint(AppStyle.ink).disabled(!canContinue)
                }
            }
            .padding(16).background(.ultraThickMaterial)
        }
    }

    var matchStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Which place were you at?").font(.title2.bold())
                Text("Your saved location may be imprecise. Only you can confirm the correct place.")
                    .font(.subheadline).foregroundStyle(.secondary)

                Map(initialPosition: .region(.init(center: store.currentCoordinate,
                                                    span: .init(latitudeDelta: 0.004,
                                                                longitudeDelta: 0.004)))) {
                    Annotation("Saved point", coordinate: store.currentCoordinate) {
                        CurrentLocationMarker()
                    }
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(alignment: .bottomLeading) {
                    Text("Saved point · estimated accuracy 25 m")
                        .font(.caption.weight(.medium))
                        .padding(8)
                        .background(.ultraThickMaterial, in: Capsule())
                        .padding(8)
                }

                TextField("", text: $placeSearch,
                          prompt: Text("Search place, landmark or address")
                            .foregroundStyle(Color.primary.opacity(0.66)))
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.search)

                Text(placeSearch.isEmpty ? "Nearby suggestions" : "Place results")
                    .font(.headline)
                ForEach(visiblePlaceMatches) { place in
                    SelectionCard(symbol: place.type.symbol, title: place.name,
                                  subtitle: "\(place.distance) · \(place.address)",
                                  selected: matchedPlace?.id == place.id) {
                        matchedPlace = place
                        exactSpot = false
                        missingNamedPlace = false
                        name = place.name
                        type = place.type
                    }
                }

                if !placeSearch.isEmpty && visiblePlaceMatches.isEmpty {
                    Text("No recognised places found")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                Text("Not in the results?").font(.headline).padding(.top, 4)
                SelectionCard(symbol: "building.2.crop.circle", title: "Add a missing named place",
                              subtitle: "For a shop, café, library or other named venue",
                              selected: missingNamedPlace) {
                    matchedPlace = nil
                    exactSpot = false
                    missingNamedPlace = true
                    name = placeSearch
                    environment = .indoors
                    type = .shop
                }
                SelectionCard(symbol: "mappin.and.ellipse", title: "This exact unnamed spot",
                              subtitle: "For a tree, bench, shaded corner or similar spot",
                              selected: exactSpot) {
                    matchedPlace = nil
                    exactSpot = true
                    missingNamedPlace = false
                    name = ""
                    environment = .outdoors
                    type = .park
                }
            }
            .padding(20)
        }
    }

    var basicsStep: some View {
        Form {
            Section("Place") {
                TextField("A name people can recognise", text: $name)
                    .disabled(matchedPlace != nil || !source.initialName.isEmpty)
                Picker("Setting", selection: $environment) {
                    ForEach(PlaceEnvironment.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
            }
            Section {
                NavigationLink {
                    PlaceTypePicker(selection: $type)
                } label: { LabeledContent("Place type", value: type.rawValue) }
            } header: { Text("Type") } footer: {
                Text("The headings organise the list. People still choose a specific place type.")
            }
        }
    }

    var featuresStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("What helps people cool down?").font(.title2.bold())
                Text("Choose at least one thing you personally observed. You can submit after this; other details are optional.")
                    .font(.subheadline).foregroundStyle(.secondary)
                ForEach(CoolingFeature.allCases) { feature in
                    SelectionCard(symbol: feature.symbol, title: feature.rawValue, selected: features.contains(feature)) {
                        if features.contains(feature) { features.remove(feature) } else { features.insert(feature) }
                    }
                }
                if let first = features.sorted(by: { $0.rawValue < $1.rawValue }).first {
                    Label("People will know about \(first.rawValue.lowercased()).",
                          systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppStyle.brand)
                        .padding(.top, 4)
                }
                if exactSpot {
                    Divider().padding(.vertical, 4)
                    Toggle("This spot is publicly and legally accessible", isOn: $publicAccessConfirmed)
                    Button { hasPhoto.toggle() } label: {
                        Label(hasPhoto ? "Photo added" : "Add a photo of this exact spot",
                              systemImage: hasPhoto ? "checkmark.circle.fill" : "photo.badge.plus")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    Text("A photo is required so people and reviewers can identify an unnamed outdoor spot.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
    }

    var accessStep: some View {
        Form {
            Section {
                Picker("Access", selection: $access) {
                    ForEach(AccessType.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.inline)
            } header: { Text("How can people enter?") } footer: {
                Text("Purchase expected means no entry ticket, but people are normally expected to buy something—for example, a café.")
            }
            Section("Seating") {
                Picker("Seating", selection: $seating) {
                    ForEach(SeatingType.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.inline)
            }
        }
    }

    var evidenceStep: some View {
        Form {
            Section {
                Button { hasPhoto.toggle() } label: {
                    HStack(spacing: 14) {
                        Image(systemName: hasPhoto ? "checkmark.circle.fill" : "photo.badge.plus")
                            .font(.title2).foregroundStyle(AppStyle.brand)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(hasPhoto ? "Photo added" : "Add photo").font(.headline)
                            Text(photoRequired ? "Required for this unnamed outdoor spot" : "Optional, but useful for finding a specific corner")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            } header: { Text("Photo") } footer: {
                Text("The place and photo are reviewed together before publication.")
            }
            Section("Anything else?") {
                TextField("Optional note (up to 200 characters)", text: $note, axis: .vertical).lineLimit(3...6)
            }
        }
    }

    var reviewStep: some View {
        List {
            Section("Place") {
                LabeledContent("Name", value: name)
                LabeledContent("Setting", value: environment.rawValue)
                LabeledContent("Type", value: type.rawValue)
            }
            Section("Cooling features") {
                ForEach(features.sorted { $0.rawValue < $1.rawValue }) {
                    Label($0.rawValue, systemImage: $0.symbol)
                }
            }
            Section {
                Picker("Access", selection: $access) {
                    ForEach(AccessType.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Seating", selection: $seating) {
                    ForEach(SeatingType.allCases) { Text($0.rawValue).tag($0) }
                }
                if !photoRequired {
                    Button { hasPhoto.toggle() } label: {
                        LabeledContent("Photo", value: hasPhoto ? "Added" : "Optional")
                    }
                }
                TextField("Optional note", text: $note, axis: .vertical).lineLimit(2...4)
            } header: {
                Text("Optional details")
            } footer: {
                Text("Submit now or add whatever you can confirm.")
            }
            Section {
                Text("A reviewer may correct the name, pin or type, or merge this with an existing Cool Spot. A material change will be sent back to you.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    var completeStep: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "paperplane.circle.fill").font(.system(size: 78)).foregroundStyle(AppStyle.brand)
                .symbolEffect(.bounce, value: step)
            Text("Sent for review").font(.largeTitle.bold())
            Text(source.isUpdate
                 ? "Thanks for improving this place’s cooling information. We’ll let you know if anything needs clarification."
                 : "Thanks for helping map a cooler London. If published, this type joins your Cool Hunt.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary).padding(.horizontal, 24)
            Label("Follow this in You → Your contributions", systemImage: "clock.fill")
                .font(.subheadline.weight(.medium)).padding(14)
                .background(AppStyle.mint, in: RoundedRectangle(cornerRadius: 14))
            Spacer()
            Button("Done") { dismiss() }.buttonStyle(PrimaryButtonStyle()).padding(20)
        }
    }

    func move(_ offset: Int) {
        guard let index = visibleSteps.firstIndex(of: step) else { return }
        let next = index + offset
        guard visibleSteps.indices.contains(next) else { return }
        step = visibleSteps[next]
    }
}

struct PlaceTypePicker: View {
    @Binding var selection: PlaceType
    var body: some View {
        List {
            TypeSection(title: "Learning & public", types: [.library, .publicService, .faith], selection: $selection)
            TypeSection(title: "Culture & leisure", types: [.culture, .leisure], selection: $selection)
            TypeSection(title: "Commercial", types: [.shop, .food], selection: $selection)
            TypeSection(title: "Outdoor", types: [.park, .square, .waterside], selection: $selection)
            TypeSection(title: "Other", types: [.transport, .other], selection: $selection)
        }
        .navigationTitle("Place type")
    }
}

struct TypeSection: View {
    let title: String
    let types: [PlaceType]
    @Binding var selection: PlaceType
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Section(title) {
            ForEach(types) { type in
                Button {
                    selection = type; dismiss()
                } label: {
                    HStack {
                        Label(type.rawValue, systemImage: type.symbol)
                        Spacer()
                        if selection == type { Image(systemName: "checkmark").foregroundStyle(AppStyle.brand) }
                    }
                }.foregroundStyle(.primary)
            }
        }
    }
}
