import MapKit
import SwiftUI

struct SavedView: View {
    @ObservedObject var store: PrototypeStore
    var findNearby: ((RecognisedPlace) -> Void)? = nil
    @State private var selected: SavedLocation?
    @State private var pendingNearbyPlace: RecognisedPlace?
    @State private var lastSavedLocation: SavedLocation?
    @State private var showToast = false
    @State private var showPinPrompt = false

    var body: some View {
        NavigationStack {
            Group {
                if store.savedLocations.isEmpty {
                    ContentUnavailableView("Nothing saved yet", systemImage: "bookmark",
                        description: Text("Save places you want to find again, or drop a private pin where you are now."))
                } else {
                    List {
                        let places = store.savedLocations.filter { $0.kind != .coordinate }
                        let pins = store.savedLocations.filter { $0.kind == .coordinate }
                        if !places.isEmpty {
                            Section("Places") {
                                ForEach(places) { saved in
                                    Button { selected = saved } label: { SavedCard(store: store, saved: saved) }
                                        .buttonStyle(.plain)
                                }
                            }
                        }
                        if !pins.isEmpty {
                            Section {
                                ForEach(pins) { saved in
                                    Button { selected = saved } label: { SavedCard(store: store, saved: saved) }
                                        .buttonStyle(.plain)
                                }
                            } header: { Text("Pins") }
                            footer: { Text("Only you can see your pins.") }
                            }
                    }.listStyle(.insetGrouped)
                }
            }
            .background(AppStyle.paper.opacity(0.55)).navigationTitle("Saved")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPinPrompt = true
                    } label: { Label("Save a pin here", systemImage: "mappin.and.ellipse") }
                }
            }
            .overlay(alignment: .top) {
                if showToast {
                    SavedToast {
                        selected = lastSavedLocation
                        showToast = false
                    }
                    .padding(16)
                }
            }
        }
        .alert("Save a pin here?", isPresented: $showPinPrompt) {
            Button("Cancel", role: .cancel) {}
            Button("Save pin") { lastSavedLocation = store.saveCurrentLocation(); showToast = true }
        } message: {
            Text("Save this location to your private pins?")
        }
        .sheet(item: $selected, onDismiss: {
            if let place = pendingNearbyPlace {
                pendingNearbyPlace = nil
                findNearby?(place)
            }
        }) { saved in
            if case .coolSpot(let id) = saved.kind, let spot = store.spot(id) {
                CoolSpotDetailView(store: store, spot: spot)
            } else if case .recognisedPlace(let id) = saved.kind, let place = store.place(id) {
                if let spot = store.existingSpot(for: place) {
                    CoolSpotDetailView(store: store, spot: spot)
                } else {
                    RecognisedPlaceDetailView(store: store, place: place, findNearby: findNearby == nil ? nil : {
                        pendingNearbyPlace = place
                        selected = nil
                    })
                }
            } else {
                SavedDetail(store: store, savedID: saved.id)
            }
        }
    }
}

struct SavedCard: View {
    @ObservedObject var store: PrototypeStore
    let saved: SavedLocation
    var coolSpot: CoolSpot? {
        if case .coolSpot(let id) = saved.kind { return store.spot(id) }
        if case .recognisedPlace(let id) = saved.kind, let place = store.place(id) { return store.existingSpot(for: place) }
        return nil
    }
    var isCoordinate: Bool { if case .coordinate = saved.kind { true } else { false } }

    var body: some View {
        HStack(spacing: LayoutSpacing.related) {
            Image(systemName: coolSpot?.type.symbol ?? (isCoordinate ? "mappin.and.ellipse" : "building.2.fill"))
                .font(.title3).foregroundStyle(.white).frame(width: 48, height: 48)
                .background(coolSpot == nil ? Color.secondary : AppStyle.ink,
                            in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                Text(saved.title).font(.headline)
                Text(saved.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                if let spot = coolSpot {
                    VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                        Text(spot.metadataLabel).font(.caption).foregroundStyle(.secondary)
                        Text(spot.features.first?.rawValue ?? "").font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    Text("Saved \(saved.savedAt.formatted(.relative(presentation: .named)))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(.vertical, LayoutSpacing.text)
    }
}

struct SavedDetail: View {
    @ObservedObject var store: PrototypeStore
    let savedID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var showContribution = false
    @State private var showEditor = false

    var saved: SavedLocation? { store.savedLocations.first { $0.id == savedID } }
    var coolSpot: CoolSpot? {
        guard let saved, case .coolSpot(let id) = saved.kind else { return nil }
        return store.spot(id)
    }
    var place: RecognisedPlace? {
        guard let saved, case .recognisedPlace(let id) = saved.kind else { return nil }
        return store.place(id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let saved {
                    VStack(alignment: .leading, spacing: LayoutSpacing.section) {
                        VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                            Text(saved.title).font(.largeTitle.bold())
                            Text(saved.subtitle).font(.subheadline).foregroundStyle(.secondary)
                            Text("Saved \(saved.savedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if let spot = coolSpot {
                            Label("Published on the Cool Spot map", systemImage: "checkmark.seal.fill")
                                .font(.subheadline.weight(.semibold)).foregroundStyle(AppStyle.brand)
                            SourceBadge(source: spot.source)
                            FlowLayout(spacing: 8) { ForEach(spot.features) { InfoPill(feature: $0) } }
                            FactRow(symbol: "creditcard", title: spot.access.summary)
                            if let entrySummary = spot.entrySummary {
                                FactRow(symbol: "person.crop.rectangle", title: entrySummary)
                            }
                            if !spot.entryInformation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                FactRow(symbol: "ticket", title: spot.entryInformation)
                            }
                            FactRow(symbol: "chair.lounge.fill", title: spot.seating.displayName)
                            Button { showContribution = true } label: {
                                Text("Suggest an edit").frame(maxWidth: .infinity)
                            }.buttonStyle(PrimaryButtonStyle())
                        } else if let place {
                            privateDetails
                            VStack(alignment: .leading, spacing: 8) {
                                Label("No cooling information yet",
                                      systemImage: "building.2")
                                    .font(.headline)
                            }
                            .padding(16)
                            .background(AppStyle.blue, in: RoundedRectangle(cornerRadius: 16))
                            Button {
                                showContribution = true
                            } label: {
                                Text("Add cooling information for \(place.name)")
                                    .frame(maxWidth: .infinity)
                            }.buttonStyle(PrimaryButtonStyle())
                        } else {
                            coordinateOverview
                            privateDetails
                            if store.usesAPICatalogue, case .coolSpot = saved.kind {
                                Label("Cooling information is currently unavailable", systemImage: "info.circle")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            } else {
                                shareCoordinateOptions
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(saved?.kind == .coordinate ? "Saved pin" : "Saved place").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Edit") { showEditor = true }
                        .accessibilityLabel(saved?.kind == .coordinate ? "Edit saved pin" : "Edit saved place")
                }
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
        .sheet(isPresented: $showEditor) {
            if let saved { SavedPlaceEditor(store: store, saved: saved) }
        }
        .sheet(isPresented: $showContribution) {
            if let saved {
                if let coolSpot { ContributionFlow(store: store, source: .existingCoolSpot(coolSpot)) }
                else if let place { ContributionFlow(store: store, source: .recognisedPlace(place)) }
                else {
                    ContributionFlow(store: store, source: .savedCoordinate(saved))
                }
            }
        }
    }

    var coordinateOverview: some View {
        Group {
            if let saved {
                Map(initialPosition: .region(.init(
                    center: .init(latitude: saved.latitude, longitude: saved.longitude),
                    span: .init(latitudeDelta: 0.004, longitudeDelta: 0.004)))) {
                        Marker(saved.kind == .coordinate ? "Saved pin" : "Saved place", coordinate: .init(latitude: saved.latitude,
                                                                    longitude: saved.longitude))
                            .tint(.blue)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

            }
        }
    }

    var shareCoordinateOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cooling information").font(.headline)
            Text("No cooling information yet")
            Button { showContribution = true } label: {
                Text("Add cooling information").frame(maxWidth: .infinity)
            }.buttonStyle(SecondaryButtonStyle())
        }
    }

    @ViewBuilder var privateDetails: some View {
        if let saved {
            SavedNoteSummary(store: store, saved: saved, allowsEditing: false)
        }
    }
}

// Saving is one action; editing a bookmark is a separate, explicit task.
struct PlaceSaveButton: View {
    @ObservedObject var store: PrototypeStore
    let saved: SavedLocation?
    let toggle: () -> Void
    @State private var showEditor = false
    @State private var confirmRemoval = false

    var body: some View {
        Group {
            if let saved {
                Menu {
                    Button("Edit saved place", systemImage: "square.and.pencil") { showEditor = true }
                    Button("Remove from Saved", systemImage: "bookmark.slash", role: .destructive) {
                        if saved.note.isEmpty { toggle() }
                        else { confirmRemoval = true }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Label("Saved", systemImage: "bookmark.fill")
                        Image(systemName: "chevron.down").font(.caption.weight(.semibold))
                    }.frame(maxWidth: .infinity)
                }
            } else {
                Button(action: toggle) {
                    Label("Save", systemImage: "bookmark").frame(maxWidth: .infinity)
                }
            }
        }
        .buttonStyle(SecondaryButtonStyle())
        .sheet(isPresented: $showEditor) {
            if let saved { SavedPlaceEditor(store: store, saved: saved) }
        }
        .confirmationDialog("Remove this saved place and its note?", isPresented: $confirmRemoval,
                            titleVisibility: .visible) {
            Button("Remove from Saved", role: .destructive, action: toggle)
        }
    }
}

struct SavedNoteSummary: View {
    @ObservedObject var store: PrototypeStore
    let saved: SavedLocation
    var allowsEditing = true
    @State private var showEditor = false

    var body: some View {
        if !saved.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                HStack {
                    Label("Your note", systemImage: "lock").font(.headline)
                    Spacer()
                    if allowsEditing {
                        Button("Edit") { showEditor = true }.frame(minHeight: 44)
                    }
                }
                Text(saved.note).font(.body)
            }
            .sheet(isPresented: $showEditor) { SavedPlaceEditor(store: store, saved: saved) }
        }
    }
}

struct SavedPlaceEditor: View {
    @ObservedObject var store: PrototypeStore
    let saved: SavedLocation
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var note: String
    @State private var confirmDiscard = false

    init(store: PrototypeStore, saved: SavedLocation) {
        self.store = store
        self.saved = saved
        _title = State(initialValue: saved.title)
        _note = State(initialValue: saved.note)
    }

    private var placeName: String {
        switch saved.kind {
        case .coolSpot(let id): store.spot(id)?.name ?? saved.title
        case .recognisedPlace(let id): store.place(id)?.name ?? saved.title
        case .coordinate: "Saved pin"
        }
    }

    private var changed: Bool { title != saved.title || note != saved.note }
    private var validTitle: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                        Text(placeName).font(.headline)
                        Text(saved.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    }.padding(.vertical, LayoutSpacing.metadata)
                }
                Section {
                    TextField("Name in Saved", text: $title, axis: .vertical)
                        .lineLimit(1...3)
                    if !validTitle { Text("Enter a name.").font(.footnote).foregroundStyle(.red) }
                } header: { Text("Name in Saved") }
                Section {
                    TextField("Add a note", text: $note, axis: .vertical).lineLimit(4...8)
                        .accessibilityLabel("Your note")
                } header: { Text("Your note") }
                footer: { Text("Only you can see this.") }
            }
            .listSectionSpacing(LayoutSpacing.section)
            .navigationTitle(saved.kind == .coordinate ? "Edit saved pin" : "Edit saved place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if changed { confirmDiscard = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save changes") {
                        store.updateSaved(saved.id, title: title.trimmingCharacters(in: .whitespacesAndNewlines), note: note)
                        UIAccessibility.post(notification: .announcement, argument: "Changes saved")
                        dismiss()
                    }.disabled(!changed || !validTitle)
                }
            }
        }
        .tint(AppStyle.brand)
        .interactiveDismissDisabled(changed)
        .confirmationDialog("Discard changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Discard changes", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) {}
        }
    }
}

struct YouView: View {
    @ObservedObject var store: PrototypeStore
    @Binding var appearance: AppAppearance

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        AccountView(store: store)
                    } label: {
                        Label(store.isSignedIn ? "Your account" : "Sign in", systemImage: "person.crop.circle")
                    }
                }
                Section {
                    NavigationLink {
                        YourReportsView(store: store)
                    } label: {
                        VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                            Text("Your reports")
                            let count = store.unfinishedReportSpots.count
                            if count > 0 {
                                Text("\(count) unfinished \(count == 1 ? "report" : "reports")")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityIdentifier("yourReportsEntry")
                    NavigationLink {
                        PlaceContributionsView(store: store)
                    } label: {
                        VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                            Text("Places you’ve added or updated")
                            let count = store.contributions.filter {
                                if case .actionNeeded = $0.status { return $0.kind != .visitReport }
                                return false
                            }.count
                            if count > 0 {
                                Text("\(count) \(count == 1 ? "update needs" : "updates need") more information")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                    NavigationLink("Cool Hunt") { CoolHuntView(store: store) }
                    NavigationLink("Settings") { SettingsView(store: store, appearance: $appearance) }
                }
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--reports-test-fixtures") {
                    Section { Text("Example reports for testing — not real visitor data.").font(.caption).foregroundStyle(.secondary) }
                }
                #endif
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppStyle.paper.opacity(0.55))
            .navigationTitle("You")
        }
    }
}

struct YourReportsView: View {
    @ObservedObject var store: PrototypeStore
    @State private var visitToOpen: CoolSpot?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let unfinished = store.unfinishedReportSpots
            let notStarted = store.visitsWithoutReports(at: context.date)
            List {
                if unfinished.isEmpty && store.visitReports.isEmpty && notStarted.isEmpty {
                    ContentUnavailableView("No reports yet", systemImage: "text.bubble",
                        description: Text("Start a report from a place page while you’re nearby. You can finish it later here."))
                        .listRowBackground(Color.clear)
                }
                if !unfinished.isEmpty {
                    Section {
                        ForEach(unfinished) { spot in
                            VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                                Text(spot.name).font(.headline)
                                if let draft = store.reportDrafts[spot.id] {
                                    Text("Visit: \(draft.visitedAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }
                                Button("Continue report") { open(spot) }
                                    .frame(minHeight: 44)
                                    .accessibilityIdentifier("continueReport-\(spot.id)")
                                    .accessibilityLabel("Continue report for \(spot.name)")
                            }.padding(.vertical, 4)
                        }
                    } header: {
                        Text("Unfinished (\(unfinished.count))")
                    } footer: {
                        Text("Your answers stay private until you publish.")
                    }
                }
                if !notStarted.isEmpty {
                    Section {
                        ForEach(notStarted) { spot in
                            VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                                Text(spot.name).font(.headline)
                                if let visit = store.visitConfirmedAt[spot.id] {
                                    Text("Visit: \(visit.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }
                                Button("Share how it felt") { open(spot) }.frame(minHeight: 44)
                            }.padding(.vertical, 4)
                        }
                    } header: { Text("Visits you can report") }
                }
                if !store.visitReports.isEmpty {
                    Section("Published") {
                        ForEach(store.visitReports.sorted { $0.visitedAt > $1.visitedAt }) { report in
                            NavigationLink {
                                PublishedVisitReportView(store: store, report: report)
                            } label: {
                                VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                                    Text(store.spot(report.spotID)?.name ?? "Cool Spot").font(.headline)
                                    Text("Visit: \(report.visitedAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                    Text(report.experience.rawValue).font(.subheadline)
                                    if store.hasReceivedExamplePopsicle(for: report.id) {
                                        Label { Text("Popsicle received · Example") } icon: { PopsicleMark() }
                                            .font(.caption).foregroundStyle(AppStyle.brand)
                                    }
                                }.padding(.vertical, 4)
                            }
                        }
                    }
                }
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--reports-test-fixtures") {
                    Section { Text("Example reports for testing — not real visitor data.").font(.caption).foregroundStyle(.secondary) }
                }
                #endif
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Your reports").navigationBarTitleDisplayMode(.inline)
        .sheet(item: $visitToOpen) { spot in VisitReportFlow(store: store, spot: spot) }
    }

    private func open(_ spot: CoolSpot) {
        let current = store.spot(spot.id) ?? spot
        if store.beginVisitReport(for: current) { visitToOpen = current }
    }
}

struct PublishedVisitReportView: View {
    @ObservedObject var store: PrototypeStore
    let report: VisitReport
    var body: some View {
        List {
            Section {
                VisitorReportContent(item: .init(id: report.id.uuidString, comment: report.comment,
                                                 report: report, provenance: .own))
                if store.hasReceivedExamplePopsicle(for: report.id) { ReceivedPopsicleExample() }
            } header: {
                Text(store.spot(report.spotID)?.name ?? "Cool Spot")
                    .font(.subheadline.weight(.semibold)).textCase(nil)
                    .foregroundStyle(AppStyle.supportingText)
            } footer: {
                Text("Published \(report.submittedAt.formatted(date: .abbreviated, time: .shortened))")
                    .foregroundStyle(AppStyle.supportingText)
            }
        }.listStyle(.plain)
        .navigationTitle("Your report").navigationBarTitleDisplayMode(.inline)
    }
}

struct PlaceContributionsView: View {
    @ObservedObject var store: PrototypeStore
    var items: [Contribution] { store.contributions.filter { $0.kind != .visitReport } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Review demo · Saved on this device")
                    .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                ContributionSection(title: "Needs your attention", items: items.filter {
                    if case .actionNeeded = $0.status { true } else { false }
                })
                ContributionSection(title: "In progress", items: items.filter {
                    switch $0.status { case .draft, .inReview: true; default: false }
                })
                ContributionSection(title: "Outcomes", items: items.filter {
                    switch $0.status { case .published, .notPublished, .merged: true; default: false }
                })
                if items.isEmpty {
                    ContentUnavailableView("No place updates yet", systemImage: "mappin.and.ellipse",
                        description: Text("Places you add and details you update will appear here."))
                }
            }.padding(LayoutSpacing.page)
        }
        .background(AppStyle.paper.opacity(0.55))
        .navigationTitle("Places you’ve added or updated").navigationBarTitleDisplayMode(.inline)
    }
}

struct AccountView: View {
    @ObservedObject var store: PrototypeStore
    var body: some View {
        ScrollView {
            if store.isSignedIn {
                VStack(alignment: .leading, spacing: 12) {
                    Label("London explorer", systemImage: "person.crop.circle.fill").font(.headline)
                    Text("Account preview · Sync unavailable")
                        .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                }.padding(20)
            } else {
                SignInCard(savedCount: store.savedLocations.count, contributionCount: store.contributions.count) {
                    store.isSignedIn = true
                }.padding(16)
            }
        }
        .navigationTitle("Your account").navigationBarTitleDisplayMode(.inline)
    }
}

struct CoolHuntView: View {
    @ObservedObject var store: PrototypeStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutSpacing.majorSection) { coolHunt; impact }.padding(LayoutSpacing.page)
        }
        .background(AppStyle.paper.opacity(0.55))
        .navigationTitle("Cool Hunt").navigationBarTitleDisplayMode(.inline)
    }
    var impact: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                Text("Your help").font(.title2.bold())
                Text("Contributions you’ve made to the shared map")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                ImpactStat(value: 4, label: "Cool Spots added")
                ImpactStat(value: 2, label: "Place details improved")
                ImpactStat(value: 7 + store.visitReports.count, label: "Visits shared")
            }
            Text("Example progress")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    var coolHunt: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                Text("Cool Hunt").font(.title2.bold())
                Text("Small exploration goals, unlocked by nearby check-ins")
                    .font(.caption).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Shade finder", systemImage: "leaf.fill").font(.headline)
                    Spacer()
                    Text("1 of 2").font(.subheadline.weight(.semibold))
                }
                ProgressView(value: 0.5).tint(AppStyle.brand)
                Text("Next: cool off beneath structural shade")
                    .font(.subheadline).foregroundStyle(Color.primary.opacity(0.78))
            }
            .padding(16)
            .background(AppStyle.mint, in: RoundedRectangle(cornerRadius: 16))
            HStack {
                Text("Place types discovered").font(.headline)
                Spacer()
                Text("\(store.unlockedTypes.count)/\(PlaceType.allCases.filter { $0 != .unknown }.count) discovered")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(PlaceType.allCases.prefix(6))) { type in
                        HuntTile(type: type, unlocked: store.unlockedTypes.contains(type))
                            .frame(width: 104)
                    }
                }
            }
        }
    }
}

struct PrototypeControlsView: View {
    @ObservedObject var store: PrototypeStore
    private var latestPlaceContribution: Contribution? { store.contributions.first { $0.kind != .visitReport } }
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 10) {
                Text("Location is simulated. Use these controls to test arriving and leaving.")
                    .font(.caption).foregroundStyle(.secondary)
                Picker("Nearby place", selection: Binding(
                    get: { store.spots.first(where: \.isNearby)?.id ?? "away" },
                    set: { store.simulateNearbySpot($0 == "away" ? nil : $0) }
                )) {
                    Text("Away from all Cool Spots").tag("away")
                    ForEach(store.spots) { Text($0.name).tag($0.id) }
                }
                Button("Simulate a visit 7 days ago") { store.simulateEarlierVisits() }
                Text("Moves unstarted, confirmed visits back seven days and sets you away. They stay available to report.")
                    .font(.caption).foregroundStyle(.secondary)
                Divider()
                Text("Simulate review of your newest place contribution on this device.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Needs clarification") { store.simulate(.actionNeeded("Please add a clearer photo of the shaded area.")) }
                    .disabled(latestPlaceContribution == nil || latestPlaceContribution?.status == .published)
                if let latest = latestPlaceContribution {
                    Text("\(latest.title) · \(latest.status.title)").font(.subheadline)
                }
                if store.usesAPICatalogue {
                    Text("Public place publishing requires the backend. Proposals remain saved on this device.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Button("Publish locally") { store.simulate(.published) }
                        .disabled(latestPlaceContribution?.status != .inReview)
                }
                if let error = store.contributionError { Text(error).font(.footnote).foregroundStyle(.red) }
                Button("Do not publish") { store.simulate(.notPublished("This spot is not open to visitors.")) }
                    .disabled(latestPlaceContribution == nil || latestPlaceContribution?.status == .published)
            }.padding(.top, 10)
        }
        // Several prototype actions share one form row; keep their tap handling independent.
        .buttonStyle(.borderless)
        .navigationTitle("Prototype controls").navigationBarTitleDisplayMode(.inline)
    }
}


struct SettingsView: View {
    @ObservedObject var store: PrototypeStore
    @Binding var appearance: AppAppearance

    var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: $appearance) {
                    ForEach(AppAppearance.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.inline)
            }
            Section("Popsicle thank-you example") {
                if let report = store.visitReports.first {
                    Text("For your report at \(store.spot(report.spotID)?.name ?? "Cool Spot")")
                    Button("Simulate receiving a popsicle") { store.simulateReceivedPopsicle(for: report.id) }
                    Text("See it in You → Your reports → Published. This is a demonstration, not a real thank-you.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Publish a report first, then return here to try receiving a thank-you.")
                }
            }
            Section { NavigationLink("Prototype controls") { PrototypeControlsView(store: store) } }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SignInCard: View {
    let savedCount: Int
    let contributionCount: Int
    let action: () -> Void

    var detail: String {
        "Saved on this device. Account sync isn’t available yet."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your account", systemImage: "person.crop.circle.badge.plus")
                .font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(Color.primary.opacity(0.78))
            Button("Preview account", action: action).buttonStyle(.borderedProminent).tint(AppStyle.ink)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(AppStyle.blue, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct ImpactStat: View {
    let value: Int
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)").font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .padding(12).frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct AllContributionsView: View {
    let items: [Contribution]

    var body: some View {
        List(items) { item in
            ContributionRow(item: item)
                .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .navigationTitle("All contributions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HuntTile: View {
    let type: PlaceType
    let unlocked: Bool
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: unlocked ? type.symbol : "questionmark").font(.title2)
                .foregroundStyle(unlocked ? AppStyle.brand : .secondary).frame(width: 46, height: 46)
                .background(unlocked ? AppStyle.mint : Color.secondary.opacity(0.10), in: Circle())
            Text(unlocked ? type.shortName : "Undiscovered").font(.caption.weight(.semibold))
                .multilineTextAlignment(.center).lineLimit(2)
        }
        .padding(10).frame(maxWidth: .infinity, minHeight: 94)
        .background(.background, in: RoundedRectangle(cornerRadius: 14)).opacity(unlocked ? 1 : 0.65)
    }
}

struct ContributionSection: View {
    let title: String
    let items: [Contribution]
    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.title3.bold())
                ForEach(items) { ContributionRow(item: $0) }
            }
        }
    }
}

struct ContributionRow: View {
    let item: Contribution
    var color: Color {
        switch item.status {
        case .actionNeeded, .notPublished: .primary
        case .published, .merged: AppStyle.brand
        case .draft, .inReview: .blue
        }
    }
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.status.symbol).font(.title3).foregroundStyle(color)
                .frame(width: 34, height: 34).background(color.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.headline)
                Text(item.kind.rawValue).font(.caption).foregroundStyle(AppStyle.supportingText)
                Text(item.status.title).font(.subheadline.weight(.semibold)).foregroundStyle(color)
                Text(item.status.detail).font(.subheadline).foregroundStyle(AppStyle.supportingText)
            }
            Spacer()
        }
        .padding(LayoutSpacing.group).background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}
