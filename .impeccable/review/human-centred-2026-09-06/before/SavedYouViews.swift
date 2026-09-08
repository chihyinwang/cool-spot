import MapKit
import SwiftUI

struct SavedView: View {
    @ObservedObject var store: PrototypeStore
    @State private var selected: SavedLocation?
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
                            footer: { Text("Private points you marked to find again. Saving a pin doesn’t start a report.") }
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
            Text("Mark where you are so you can find it again in Saved → Pins. Only you can see it. This doesn’t start a report. Location is simulated in this prototype.")
        }
        .sheet(item: $selected) { saved in
            if case .coolSpot(let id) = saved.kind, let spot = store.spot(id) {
                CoolSpotDetailView(store: store, spot: spot)
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
        if case .coolSpot(let id) = saved.kind { store.spot(id) } else { nil }
    }
    var isCoordinate: Bool { if case .coordinate = saved.kind { true } else { false } }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: coolSpot?.type.symbol ?? (isCoordinate ? "mappin.and.ellipse" : "building.2.fill"))
                .font(.title3).foregroundStyle(.white).frame(width: 48, height: 48)
                .background(coolSpot == nil ? Color.secondary : AppStyle.ink,
                            in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 5) {
                Text(saved.title).font(.headline)
                Text(saved.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                if let spot = coolSpot {
                    VStack(alignment: .leading, spacing: 5) {
                        SourceBadge(source: spot.source)
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
        .padding(.vertical, 6)
    }
}

struct SavedDetail: View {
    @ObservedObject var store: PrototypeStore
    let savedID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var note = ""
    @State private var showContribution = false

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
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 6) {
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
                            FactRow(symbol: "door.left.hand.open", title: spot.access.rawValue)
                            FactRow(symbol: "chair.lounge.fill", title: spot.seating.rawValue)
                            Button { showContribution = true } label: {
                                Text("Add or correct place details").frame(maxWidth: .infinity)
                            }.buttonStyle(PrimaryButtonStyle())
                        } else if let place {
                            privateDetails
                            VStack(alignment: .leading, spacing: 8) {
                                Label("No cooling information yet",
                                      systemImage: "building.2")
                                    .font(.headline)
                                Text("Your bookmark stays private. You can choose to add cooling information for review.")
                                    .font(.subheadline).foregroundStyle(Color.primary.opacity(0.78))
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
                            shareCoordinateOptions
                        }
                        Text("Saving stays private. Cooling information is a separate contribution and is reviewed before becoming public.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .onAppear { title = saved.title; note = saved.note }
                }
            }
            .navigationTitle(saved?.kind == .coordinate ? "Saved pin" : "Saved place").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
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
                        Marker("Saved pin", coordinate: .init(latitude: saved.latitude,
                                                                    longitude: saved.longitude))
                            .tint(.blue)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text("Only you can see this saved pin.")
                    .font(.footnote).foregroundStyle(.secondary)
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

    var privateDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Private details").font(.title3.bold())
            TextField("Name to help you remember", text: $title).textFieldStyle(.roundedBorder)
            TextField("Private note", text: $note, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(2...4)
            Button("Save private details") { store.updateSaved(savedID, title: title, note: note) }
                .buttonStyle(.borderedProminent).tint(AppStyle.ink)
        }
        .padding(16).background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
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
                        VStack(alignment: .leading, spacing: 5) {
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
                        VStack(alignment: .leading, spacing: 5) {
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
                            VStack(alignment: .leading, spacing: 6) {
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
                            VStack(alignment: .leading, spacing: 6) {
                                Text(spot.name).font(.headline)
                                if let deadline = store.reportingDeadline(for: spot.id) {
                                    Text("Start by \(deadline.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }
                                Button("Share how it felt") { open(spot) }.frame(minHeight: 44)
                            }.padding(.vertical, 4)
                        }
                    } header: { Text("Visits you can report") }
                    footer: { Text("You shared that you were cooling off here, but haven’t started a report. Once started, you can finish it later.") }
                }
                if !store.visitReports.isEmpty {
                    Section("Published") {
                        ForEach(store.visitReports.sorted { $0.visitedAt > $1.visitedAt }) { report in
                            NavigationLink {
                                PublishedVisitReportView(store: store, report: report)
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
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
                Text(store.spot(report.spotID)?.name ?? "Cool Spot").font(.headline)
                Text("Visit: \(report.visitedAt.formatted(date: .abbreviated, time: .shortened))")
                Text("Published: \(report.submittedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Section("How it felt compared with outside") { Text(report.experience.rawValue) }
            if !report.helpedFeatures.isEmpty {
                Section("What helped") {
                    ForEach(CoolingFeature.allCases.filter { report.helpedFeatures.contains($0) }) { Text($0.rawValue) }
                }
            }
            if let stay = report.stayLength { Section("Time spent here") { Text(stay.rawValue) } }
            if !report.comment.isEmpty { Section("Your comment") { Text(report.comment) } }
            if store.hasReceivedExamplePopsicle(for: report.id) {
                Section { ReceivedPopsicleExample() }
            }
        }
        .navigationTitle("Your report").navigationBarTitleDisplayMode(.inline)
    }
}

struct PlaceContributionsView: View {
    @ObservedObject var store: PrototypeStore
    var items: [Contribution] { store.contributions.filter { $0.kind != .visitReport } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
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
            }.padding(16)
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
                Label("London explorer", systemImage: "person.crop.circle.fill").font(.headline).padding(20)
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
            VStack(alignment: .leading, spacing: 28) { coolHunt; impact }.padding(16)
        }
        .background(AppStyle.paper.opacity(0.55))
        .navigationTitle("Cool Hunt").navigationBarTitleDisplayMode(.inline)
    }
    var impact: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Your help").font(.title2.bold())
                Text("Contributions you’ve made to the shared map")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                ImpactStat(value: 4, label: "Cool Spots added")
                ImpactStat(value: 2, label: "Place details improved")
                ImpactStat(value: 7 + store.visitReports.count, label: "Visits shared")
            }
            Text("These places belong to the shared map. The numbers recognise how you helped.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    var coolHunt: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
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
                Text("\(store.unlockedTypes.count)/\(PlaceType.allCases.count) discovered")
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
                Button("Simulate leaving after 24 hours") { store.simulateExpiredReports() }
                Text("Started reports remain available. Visits with no report started can no longer begin one from afar.")
                    .font(.caption).foregroundStyle(.secondary)
                Divider()
                Text("Change the newest place contribution to inspect each review outcome.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Needs clarification") { store.simulate(.actionNeeded("Please add a clearer photo of the shaded area.")) }
                Button("Publish") { store.simulate(.published) }
                Button("Merge with an existing place") { store.simulate(.merged("Riverside Library")) }
                Button("Do not publish") { store.simulate(.notPublished("This location is not legally open to the public.")) }
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
            } footer: {
                Text("Match System follows your device’s light or dark appearance.")
                    .foregroundStyle(.primary)
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
        if savedCount == 0 && contributionCount == 0 {
            return "Keep future saved places, contributions and Cool Hunt progress with your account across devices."
        }
        return "Keep \(savedCount) saved \(savedCount == 1 ? "place" : "places"), \(contributionCount) \(contributionCount == 1 ? "contribution" : "contributions") and Cool Hunt progress with your account—even if you change phones."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Keep what’s on this phone", systemImage: "person.crop.circle.badge.plus")
                .font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(Color.primary.opacity(0.78))
            Button("Sign in", action: action).buttonStyle(.borderedProminent).tint(AppStyle.ink)
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
        case .actionNeeded, .notPublished: .orange
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
                Text(item.kind.rawValue).font(.caption).foregroundStyle(.secondary)
                Text(item.status.title).font(.subheadline.weight(.semibold)).foregroundStyle(color)
                Text(item.status.detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14).background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}
