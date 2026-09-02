import SwiftUI

struct CoolSpotDetailView: View {
    @ObservedObject var store: PrototypeStore
    let spot: CoolSpot
    @Environment(\.dismiss) private var dismiss
    @State private var showVisitReport = false
    @State private var showContribution = false
    @State private var showLocationWarning = false
    @State private var showProblem = false
    @State private var expandStays = false
    @State private var reportAnswer: Bool?

    var counts: (Int, Int) { store.reportCounts(for: spot) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PlaceCover(type: spot.type, environment: spot.environment).frame(height: 210)
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        actionBar
                        livePresence
                        coolingFeatures
                        Divider()
                        visitPlanning
                        Divider()
                        recentExperience
                        Divider()
                        VStack(spacing: 10) {
                            Button("Report a problem") { showProblem = true }.foregroundStyle(.red)
                        }
                        .frame(maxWidth: .infinity)
                        Text(spot.source == .gla
                             ? "Core place information supplied by the Greater London Authority. Visitor experiences are community-submitted."
                             : "Place information was community-submitted and reviewed before publication.")
                            .font(.caption).foregroundStyle(.secondary).padding(.bottom, 20)
                    }
                    .padding(20)
                }
            }
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .topTrailing) { closeButton }
        }
        .alert("You need to be nearby", isPresented: $showLocationWarning) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("A ten-minute check-in uses your location once when you tap. It never creates a location history.")
        }
        .alert("Report a problem", isPresented: $showProblem) {
            Button("Cancel", role: .cancel) {}
            Button("Send report") {}
        } message: {
            Text("Use this for a missing place, private residence, misplaced pin, duplicate, or unsafe content—not simply because it felt warm today.")
        }
        .sheet(isPresented: $showVisitReport) {
            VisitReportFlow(store: store, spot: spot, initialFoundCool: reportAnswer)
        }
        .sheet(isPresented: $showContribution) {
            ContributionFlow(store: store, source: .existingCoolSpot(spot))
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                SourceBadge(source: spot.source)
                Text(spot.type.shortName).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            Text(spot.name).font(.largeTitle.bold())
            Text("\(spot.distance) · \(spot.address)").font(.subheadline).foregroundStyle(.secondary)
        }
    }

    var actionBar: some View {
        HStack(spacing: 0) {
            DetailAction(symbol: "arrow.triangle.turn.up.right.diamond.fill", title: "Directions") {}
            DetailAction(symbol: store.isSaved(spotID: spot.id) ? "bookmark.fill" : "bookmark",
                         title: store.isSaved(spotID: spot.id) ? "Saved" : "Save") {
                _ = store.toggleSaved(spot)
            }
        }
    }

    var livePresence: some View {
        LivePresenceCard(count: store.presence(for: spot),
                         isCheckedIn: store.activePresenceSpotID == spot.id) {
            if store.activePresenceSpotID == spot.id {
                store.activePresenceSpotID = nil
            } else if spot.isNearby {
                store.checkIn(spot)
            } else {
                showLocationWarning = true
            }
        }
    }

    var coolingFeatures: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why it may help").font(.title3.bold())
            FlowLayout(spacing: 8) {
                ForEach(spot.features) { InfoPill(feature: $0) }
            }
            if !spot.features.contains(.airConditioning) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Air conditioning not confirmed", systemImage: "questionmark.circle")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button("Edit cooling features") { showContribution = true }
                        .font(.subheadline.weight(.semibold))
                        .tint(AppStyle.brand)
                }
            }
        }
    }

    var visitPlanning: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plan your visit").font(.title3.bold())
            FactRow(symbol: "door.left.hand.open", title: spot.access.rawValue)
            FactRow(symbol: "chair.lounge.fill", title: spot.seating.rawValue)
            FactRow(symbol: "clock", title: "Opening hours not verified")
            FactRow(symbol: "figure.roll", title: "Wheelchair access not confirmed")
            Button("Add or correct place details") { showContribution = true }
                .font(.subheadline.weight(.semibold))
            Text("Cooling features, access, seating or photo")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    var recentExperience: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Recent experiences").font(.title3.bold())
                Text("Personal reports, not a guarantee of current conditions")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                ReportCount(title: "Felt cool", count: counts.0, tint: AppStyle.mint)
                ReportCount(title: "Didn’t feel cool", count: counts.1, tint: .orange.opacity(0.16))
            }
            DisclosureGroup(isExpanded: $expandStays) {
                StayDistribution(reports: store.stays(for: spot)).padding(.top, 10)
            } label: {
                HStack {
                    Label("How long people stayed", systemImage: "hourglass")
                    Spacer()
                    Text("\(store.stays(for: spot).values.reduce(0, +)) reports")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            ForEach(Array(store.comments(for: spot).prefix(2).enumerated()), id: \.offset) { _, text in
                VStack(alignment: .leading, spacing: 6) {
                    Text("“\(text)”").font(.subheadline)
                    Text("Visitor report · Report").font(.caption).foregroundStyle(.secondary)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Did it feel cool when you visited?").font(.headline)
                HStack(spacing: 10) {
                    ReportChoice(title: "Felt cool", symbol: "snowflake", selected: false) {
                        reportAnswer = true
                        showVisitReport = true
                    }
                    ReportChoice(title: "Didn’t", symbol: "sun.max.fill", selected: false) {
                        reportAnswer = false
                        showVisitReport = true
                    }
                }
                Text("Share one past visit. You can add how long you stayed and a comment before publishing.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark").font(.headline).frame(width: 36, height: 36)
                .background(.ultraThickMaterial, in: Circle())
        }
        .buttonStyle(.plain).padding(16)
    }
}

struct LivePresenceCard: View {
    let count: Int
    let isCheckedIn: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                HStack(spacing: 3) {
                    ForEach(0..<min(count, 3), id: \.self) { _ in
                        Circle().fill(AppStyle.sun).frame(width: 11, height: 11)
                    }
                    if count == 0 {
                        Image(systemName: "person.2")
                            .foregroundStyle(.secondary)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(count == 0
                         ? "No recent check-ins"
                         : "\(count) \(count == 1 ? "person is" : "people are") cooling off here")
                        .font(.subheadline.weight(.semibold))
                    Text("Self-reported in the last 10 minutes")
                        .font(.caption).foregroundStyle(Color.primary.opacity(0.78))
                }
                Spacer()
            }
            Text("Share one anonymous presence for 10 minutes. Your location is checked once when you tap.")
                .font(.caption).foregroundStyle(Color.primary.opacity(0.78))
            Button(isCheckedIn ? "Stop sharing presence" : "I’m cooling off here", action: action)
                .buttonStyle(.borderedProminent)
                .tint(AppStyle.ink)
                .frame(maxWidth: .infinity)
                .accessibilityHint("Shares an anonymous ten-minute check-in")
        }
        .padding(14)
        .background(AppStyle.sunSurface, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PresenceCard: View {
    let count: Int
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 3) {
                ForEach(0..<min(count, 3), id: \.self) { _ in
                    Circle().fill(AppStyle.sun).frame(width: 11, height: 11)
                }
            }
            Text("\(count) \(count == 1 ? "person" : "people") cooling off here")
                .font(.subheadline.weight(.semibold))
        }
        .padding(14).background(AppStyle.sunSurface, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ReportCount: View {
    let title: String
    let count: Int
    let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(count)").font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(Color.primary.opacity(0.74))
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(tint, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct StayDistribution: View {
    let reports: [StayLength: Int]
    let rows: [StayLength] = [.under15, .under30, .under60, .under120, .over120]
    var maxCount: Int { max(reports.values.max() ?? 1, 1) }
    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows) { length in
                HStack(spacing: 8) {
                    Text(length.compact).font(.caption.monospacedDigit()).frame(width: 55, alignment: .leading)
                    GeometryReader { proxy in
                        Capsule().fill(AppStyle.mint)
                            .frame(width: proxy.size.width * CGFloat(reports[length, default: 0]) / CGFloat(maxCount))
                    }
                    .frame(height: 9)
                    Text("\(reports[length, default: 0])").font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary).frame(width: 22, alignment: .trailing)
                }
            }
        }
    }
}

struct RecognisedPlaceDetailView: View {
    @ObservedObject var store: PrototypeStore
    let place: RecognisedPlace
    @Environment(\.dismiss) private var dismiss
    @State private var showContribution = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    PlaceCover(type: place.type, environment: .indoors)
                        .frame(height: 210).padding(.horizontal, -20).padding(.top, -20)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("PLACE RESULT").font(.caption2.bold()).foregroundStyle(.secondary)
                        Text(place.name).font(.largeTitle.bold())
                        Text("\(place.distance) · \(place.address)").font(.subheadline).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 0) {
                        DetailAction(symbol: "arrow.triangle.turn.up.right.diamond.fill", title: "Directions") {}
                        DetailAction(symbol: store.isSaved(placeID: place.id) ? "bookmark.fill" : "bookmark",
                                     title: store.isSaved(placeID: place.id) ? "Saved" : "Save") {
                            _ = store.toggleSaved(place)
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Label("No cooling information yet", systemImage: "thermometer.sun.fill").font(.headline)
                        Text("This is a recognised map place, but it is not shown as a Cool Spot. Saving it remains private.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(16).background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                    Button { showContribution = true } label: {
                        Text("Add cooling information").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Text("Cooling information will be reviewed before this place can appear on the public map.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .topTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").frame(width: 36, height: 36)
                        .background(.ultraThickMaterial, in: Circle())
                }.buttonStyle(.plain).padding(16)
            }
        }
        .sheet(isPresented: $showContribution) {
            ContributionFlow(store: store, source: .recognisedPlace(place))
        }
    }
}

struct VisitReportFlow: View {
    @ObservedObject var store: PrototypeStore
    let spot: CoolSpot
    @Environment(\.dismiss) private var dismiss
    @State private var foundCool: Bool?
    @State private var stay: StayLength?
    @State private var comment = ""
    @State private var submitted = false

    init(store: PrototypeStore, spot: CoolSpot, initialFoundCool: Bool? = nil) {
        self.store = store
        self.spot = spot
        _foundCool = State(initialValue: initialFoundCool)
    }

    var body: some View {
        NavigationStack {
            if submitted {
                VStack(spacing: 18) {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 72)).foregroundStyle(AppStyle.brand)
                    Text("Thanks for the update").font(.title.bold())
                    Text("Your report is visible now. Other people can report the comment if it contains a problem.")
                        .multilineTextAlignment(.center).foregroundStyle(.secondary).padding(.horizontal, 26)
                    Spacer()
                    Button("Done") { dismiss() }.buttonStyle(PrimaryButtonStyle()).padding(20)
                }
            } else {
                Form {
                    Section("Did it feel cool when you visited?") {
                        HStack(spacing: 12) {
                            ReportChoice(title: "Yes", symbol: "snowflake", selected: foundCool == true) { foundCool = true }
                            ReportChoice(title: "No", symbol: "sun.max.fill", selected: foundCool == false) { foundCool = false }
                        }.padding(.vertical, 6)
                    }
                    Section {
                        Picker("How long did you stay?", selection: $stay) {
                            Text("Skip").tag(StayLength?.none)
                            ForEach(StayLength.allCases) { Text($0.rawValue).tag(StayLength?.some($0)) }
                        }
                    } footer: {
                        Text("Optional. Results appear as a compact distribution with a sample size.")
                    }
                    Section {
                        TextField("Optional comment", text: $comment, axis: .vertical).lineLimit(3...6)
                    } footer: {
                        Text("Comments publish with the report and can be reported for abuse or private information.")
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Button {
                        guard let foundCool else { return }
                        store.submitReport(spot: spot, foundCool: foundCool, stay: stay, comment: comment)
                        submitted = true
                    } label: { Text("Publish visit report").frame(maxWidth: .infinity) }
                        .buttonStyle(PrimaryButtonStyle()).disabled(foundCool == nil)
                        .padding(16).background(.ultraThickMaterial)
                }
            }
        }
    }
}

struct ReportChoice: View {
    let title: String, symbol: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                Text(title)
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
            }
            .font(.headline)
            .foregroundStyle(selected ? .white : AppStyle.brand)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(selected ? AppStyle.ink : AppStyle.controlSurface,
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(selected ? AppStyle.brand : AppStyle.subtleBorder, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
