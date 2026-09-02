import MapKit
import SwiftUI

struct SavedView: View {
    @ObservedObject var store: PrototypeStore
    @State private var selected: SavedLocation?
    @State private var lastSavedLocation: SavedLocation?
    @State private var showToast = false

    var body: some View {
        NavigationStack {
            Group {
                if store.savedLocations.isEmpty {
                    ContentUnavailableView("No saved locations", systemImage: "bookmark",
                        description: Text("Save a place or your current location to find it again later."))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(store.savedLocations) { saved in
                                Button { selected = saved } label: { SavedCard(store: store, saved: saved) }
                                    .buttonStyle(.plain)
                            }
                        }.padding(16)
                    }
                }
            }
            .background(AppStyle.paper.opacity(0.55)).navigationTitle("Saved")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        lastSavedLocation = store.saveCurrentLocation(); showToast = true
                    } label: { Label("Save current location", systemImage: "location.badge.plus") }
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
        .sheet(item: $selected) { SavedDetail(store: store, savedID: $0.id) }
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
                    HStack(spacing: 5) {
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
        .padding(14).background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppStyle.subtleBorder))
    }
}

struct SavedDetail: View {
    @ObservedObject var store: PrototypeStore
    let savedID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var note = ""
    @State private var showContribution = false
    @State private var useExactSavedSpot = false

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
                            Label(saved.kind == .coordinate ? "Saved coordinate" : "Saved place",
                                  systemImage: "bookmark.fill")
                                .font(.caption.bold()).foregroundStyle(AppStyle.brand)
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
                                Label("Recognised place · No public cooling information",
                                      systemImage: "building.2")
                                    .font(.headline)
                                Text("This saved place is private until cooling information is reviewed and published.")
                                    .font(.subheadline).foregroundStyle(Color.primary.opacity(0.78))
                            }
                            .padding(16)
                            .background(AppStyle.blue, in: RoundedRectangle(cornerRadius: 16))
                            Button {
                                useExactSavedSpot = false
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
            .navigationTitle("Saved location").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
        .sheet(isPresented: $showContribution) {
            if let saved {
                if let coolSpot { ContributionFlow(store: store, source: .existingCoolSpot(coolSpot)) }
                else if let place { ContributionFlow(store: store, source: .recognisedPlace(place)) }
                else if useExactSavedSpot {
                    ContributionFlow(store: store, source: .exactSavedCoordinate(saved))
                } else {
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
                        Marker("Saved location", coordinate: .init(latitude: saved.latitude,
                                                                    longitude: saved.longitude))
                            .tint(.blue)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 8) {
                    Label("Private saved location · Not on the public map",
                          systemImage: "location.circle")
                        .font(.headline)
                    Text("This point may be about 25 m from where you stood. Choose the named place yourself, or keep it as an exact unnamed spot.")
                        .font(.subheadline).foregroundStyle(Color.primary.opacity(0.78))
                    Text("Near London Bridge Station and Southwark Street · SE1")
                        .font(.caption).foregroundStyle(Color.primary.opacity(0.72))
                }
                .padding(16)
                .background(AppStyle.blue, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    var shareCoordinateOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share this as a Cool Spot").font(.title3.bold())
            Text("First decide whether you mean a named place nearby or this exact outdoor location.")
                .font(.subheadline).foregroundStyle(.secondary)
            Button {
                useExactSavedSpot = false
                showContribution = true
            } label: {
                Label("Find or add a named place", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(AppStyle.ink)
            Button {
                useExactSavedSpot = true
                showContribution = true
            } label: {
                Label("Use this exact unnamed spot", systemImage: "mappin.and.ellipse")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    var privateDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Private details").font(.title3.bold())
            TextField("Give this location a name", text: $title).textFieldStyle(.roundedBorder)
            TextField("Private note", text: $note, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(2...4)
            Text("Quick ideas").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            FlowLayout(spacing: 8) {
                ForEach(["Tree shade", "Bench", "Quiet corner", "Good for a break"], id: \.self) { idea in
                    Button(idea) {
                        if title.isEmpty || title == "Saved location" { title = idea }
                        else if !note.contains(idea) { note = note.isEmpty ? idea : "\(note) · \(idea)" }
                    }.buttonStyle(.bordered).buttonBorderShape(.capsule)
                }
            }
            Button("Save private details") { store.updateSaved(savedID, title: title, note: note) }
                .buttonStyle(.borderedProminent).tint(AppStyle.ink)
        }
        .padding(16).background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct YouView: View {
    @ObservedObject var store: PrototypeStore
    var active: [Contribution] { store.contributions.filter {
        switch $0.status { case .draft, .inReview, .actionNeeded: true; default: false }
    }}
    var past: [Contribution] { store.contributions.filter {
        switch $0.status { case .published, .notPublished, .merged: true; default: false }
    }}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if store.isSignedIn {
                        signedIn
                    } else {
                        SignInCard(savedCount: store.savedLocations.count,
                                   contributionCount: store.contributions.count) {
                            store.isSignedIn = true
                        }
                    }
                    ContributionSection(title: "Needs your attention", items: active.filter {
                        if case .actionNeeded = $0.status { true } else { false }
                    })
                    ContributionSection(title: "In progress", items: active.filter {
                        if case .actionNeeded = $0.status { false } else { true }
                    })
                    ContributionSection(title: "Recent outcomes", items: Array(past.prefix(3)))
                    if past.count > 3 {
                        NavigationLink {
                            AllContributionsView(items: store.contributions)
                        } label: {
                            Label("See all \(store.contributions.count) contributions",
                                  systemImage: "list.bullet")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                    }
                    impact
                    coolHunt
                    prototypeControls
                    Button("Settings") {}.foregroundStyle(AppStyle.brand).padding(.bottom, 20)
                }.padding(16)
            }
            .background(AppStyle.paper.opacity(0.55)).navigationTitle("You")
        }
    }

    var signedIn: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill").font(.system(size: 42)).foregroundStyle(AppStyle.brand)
            VStack(alignment: .leading) {
                Text("London explorer").font(.headline)
                Text("Saved places and contributions are kept with your account.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
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
                Text("Field guide").font(.headline)
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
    var prototypeControls: some View {
        DisclosureGroup("Prototype controls") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Change the newest place contribution to inspect each review outcome.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Needs clarification") { store.simulate(.actionNeeded("Please add a clearer photo of the shaded area.")) }
                Button("Publish") { store.simulate(.published) }
                Button("Merge with an existing place") { store.simulate(.merged("Riverside Library")) }
                Button("Do not publish") { store.simulate(.notPublished("This location is not legally open to the public.")) }
            }.padding(.top, 10)
        }.font(.subheadline)
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
