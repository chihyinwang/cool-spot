import MapKit
import SwiftUI
private struct VisitReportPresentation: Identifiable {
    let id = UUID()
    let initialExperience: CoolingExperience?
}

struct CoolSpotDetailView: View {
    @ObservedObject var store: PrototypeStore
    let spot: CoolSpot
    var distanceContext: String? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContribution = false
    @State private var showPresenceExplanation = false
    @State private var showProblem = false
    @State private var expandFeatures = false
    @State private var expandStays = false
    @State private var expandFacilities = false
    @State private var visitReportPresentation: VisitReportPresentation?
    @State private var showReportUnavailable = false
    @State private var showReportingHelp = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: LayoutSpacing.majorSection) {
                        header
                        recentExperience.id("visitorReports")
                        VStack(alignment: .leading, spacing: LayoutSpacing.group) {
                            CurrentUseSummary(count: store.presence(for: spot))
                            livePresence
                        }
                        VStack(alignment: .leading, spacing: LayoutSpacing.group) {
                            PlacePhoto(spot: spot)
                            ApplePlaceInformationView(coordinate: spot.coordinate,
                                                      placeIdentifier: spot.applePlaceID.flatMap(MKMapItem.Identifier.init(rawValue:)),
                                                      isExample: spot.applePlaceID == nil && spot.isExample,
                                                      showsPlaceDetails: false).id(spot.id)
                            Button { showContribution = true } label: {
                                Label("Suggest an edit", systemImage: "square.and.pencil")
                                    .font(.subheadline).frame(minHeight: 44)
                            }
                            .tint(AppStyle.brand)
                        }
                        if let saved = store.savedLocation(for: spot) {
                            SavedNoteSummary(store: store, saved: saved).id(saved.id)
                        }
                        Button { showProblem = true } label: {
                            Text("Report a problem")
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .overlay(alignment: .topTrailing) { closeButton }
            .safeAreaInset(edge: .bottom) { actionBar }
            .task {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--preview-bottom") {
                    try? await Task.sleep(for: .milliseconds(250))
                    proxy.scrollTo("visitorReports", anchor: .top)
                }
                #endif
            }
            }
        }
        .tint(AppStyle.brand)
        .alert("Report a problem", isPresented: $showProblem) {
            Button("Done", role: .cancel) {}
        } message: {
            Text("Problem reporting is currently unavailable.")
        }
        .alert("Start your report while you’re here", isPresented: $showReportUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You need to be near this Cool Spot to start a report. Once started, you can finish it later in You → Your reports, even after leaving.")
        }
        .sheet(item: $visitReportPresentation) { presentation in
            VisitReportFlow(store: store, spot: spot, initialExperience: presentation.initialExperience)
        }
        .sheet(isPresented: $showContribution) {
            ContributionFlow(store: store, source: .existingCoolSpot(spot))
        }
        .sheet(isPresented: $showPresenceExplanation) {
            PresenceExplanationSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .tint(AppStyle.brand)
        }
        .sheet(isPresented: $showReportingHelp) {
            ReportingHelpSheet()
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.group) {
            PlaceIdentityHeader(name: spot.name,
                                address: [distanceContext ?? spot.distance, spot.address]
                                    .filter { !$0.isEmpty }.joined(separator: " · "),
                                category: spot.type.shortName, source: spot.information.source)
            VStack(alignment: .leading, spacing: LayoutSpacing.related) {
                coolingFeatures
                if let note = spot.information.coolingDetails, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(note).font(.subheadline)
                }
            }
            visitingInformation
            VStack(alignment: .leading, spacing: 0) {
                facilities
                if let identifier = spot.applePlaceID.flatMap(MKMapItem.Identifier.init(rawValue:)) {
                    ApplePlaceInformationView(coordinate: spot.coordinate, placeIdentifier: identifier,
                                              showsPlaceDetails: true, showsNearbyStreets: false).id(spot.id)
                }
            }
        }
    }

    private var visitingInformation: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.related) {
            VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                let summary = [spot.access == .unsure ? nil : spot.access.summary,
                               spot.seating == .unsure ? nil : spot.seating.displayName]
                    .compactMap { $0 }.joined(separator: " · ")
                if !summary.isEmpty { Text(summary).fontWeight(.medium) }
                if let entry = spot.entrySummary { Text(entry) }
                if !spot.entryInformation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(spot.entryInformation)
                }
            }
            if let area = spot.information.instructions, !area.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                    Text("Cooling area").fontWeight(.semibold)
                    Text(area)
                }
            }
            if let minutes = spot.information.postedStayLimitMinutes {
                Text("Stay limit: \(minutes) minutes")
            }
        }
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var facilities: some View {
        if spot.information.hasFacilities || spot.information.wheelchairAccessible != nil {
            DisclosureGroup(isExpanded: $expandFacilities) {
                VStack(alignment: .leading, spacing: LayoutSpacing.related) {
                    if let toilets = spot.information.toilets.label {
                        Label(toilets, systemImage: "toilet")
                    }
                    if let accessible = spot.information.wheelchairAccessible {
                        Label(accessible ? "Wheelchair accessible" : "Not wheelchair accessible",
                              systemImage: "figure.roll")
                    }
                    if let staffed = spot.information.staffedWhenOpen {
                        Label(staffed ? "Staff on site when open" : "No staff on site",
                              systemImage: "person.fill")
                    }
                    if let tables = spot.information.tables {
                        Label(tables ? "Tables provided" : "No tables", systemImage: "table.furniture")
                    }
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, LayoutSpacing.related)
            } label: {
                Label("Facilities & accessibility", systemImage: "list.bullet")
                    .labelStyle(PlaceActionLabelStyle())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppStyle.brand)
                    .frame(minHeight: 44)
            }
        }
    }

    var actionBar: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 8) { placeActions }
            } else {
                HStack(spacing: 12) { placeActions }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
    }

    @ViewBuilder var placeActions: some View {
        Link(destination: directionsURL) {
            Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())

        PlaceSaveButton(store: store,
                        saved: store.savedLocations.first { $0.kind == .coolSpot(spot.id) },
                        toggle: { _ = store.toggleSaved(spot) })
    }

    var directionsURL: URL {
        URL(string: "https://maps.apple.com/?daddr=\(spot.latitude),\(spot.longitude)&dirflg=w")!
    }

    var experienceSummary: some View {
        let evidence = store.coolingEvidence(for: spot)
        return VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
            if evidence.total > 0 {
                Text(evidence.leadingExperience == nil
                     ? "\(evidence.total) reports · Mixed experiences"
                     : "\(evidence.attribution) \(evidence.headline.lowercased())")
                    .font(.subheadline.weight(.semibold))
                if let latest = store.latestReportDate(for: spot) {
                    Text("Latest reported visit \(latest.formatted(.relative(presentation: .numeric)))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("No visitor experiences yet").font(.subheadline.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var livePresence: some View {
        LivePresenceCard(isCheckedIn: store.isSharingPresence(for: spot),
                         isNearby: spot.isNearby,
                         presenceDeadline: store.presenceEndsAt,
                         canShareReport: store.canReportVisit(for: spot),
                         hasUnfinishedReport: store.hasUnfinishedReport(for: spot.id),
                         action: {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                if store.isSharingPresence(for: spot) {
                    store.activePresenceSpotID = nil
                } else {
                    store.checkIn(spot)
                }
            }
        }, showExplanation: {
            showPresenceExplanation = true
        }, report: { experience in
            openVisitReport(initialExperience: experience)
        })
    }

    private func openVisitReport(initialExperience: CoolingExperience? = nil) {
        guard store.beginVisitReport(for: spot) else {
            showReportUnavailable = true
            return
        }
        visitReportPresentation = VisitReportPresentation(initialExperience: initialExperience)
    }

    private var orderedFeatures: [CoolingFeature] {
        let priority: [CoolingFeature] = [.airConditioning, .fans, .drinkingWater, .treeShade,
                                         .structuralShade, .ventilation, .coolerIndoors, .waterFeature]
        return priority.filter { spot.features.contains($0) }
    }

    var coolingFeatures: some View {
        VStack(alignment: .leading, spacing: 4) {
            FlowLayout(spacing: 8) {
                ForEach(expandFeatures ? orderedFeatures : Array(orderedFeatures.prefix(2))) {
                    InfoPill(feature: $0)
                }
            }
            if spot.features.count > 2 {
                Button {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { expandFeatures.toggle() }
                } label: {
                    Label(expandFeatures ? "Show fewer cooling features"
                                         : "Show all \(spot.features.count) cooling features",
                          systemImage: expandFeatures ? "chevron.up" : "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain).foregroundStyle(AppStyle.brand)
            }
        }
    }

    var recentExperience: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.group) {
            Text("Visitor reports").font(.headline).accessibilityAddTraits(.isHeader)
            if store.experienceReportTotal(for: spot) > 0 {
                VStack(alignment: .leading, spacing: LayoutSpacing.related) {
                    experienceSummary
                    ExperienceDistribution(reports: store.coolingEvidence(for: spot).counts)
                }
                if !store.stays(for: spot).isEmpty { visitorDetails }
            }
            if let item = store.visitorReportItems(for: spot).first {
                VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                    if let report = item.report {
                        Label(report.experience.summary, systemImage: report.experience.symbol)
                            .font(.subheadline.weight(.semibold)).foregroundStyle(AppStyle.brand)
                    }
                    if !item.comment.isEmpty { Text("“\(item.comment)”").font(.body) }
                    if let report = item.report {
                        Text("\(item.sourceLabel) · \(report.visitedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundStyle(AppStyle.supportingText)
                    } else {
                        Text("\(item.sourceLabel) · Visit date unavailable")
                            .font(.caption).foregroundStyle(AppStyle.supportingText)
                    }
                }
                readAllReports
            } else if store.experienceReportTotal(for: spot) == 0 {
                Text("No reports yet").foregroundStyle(.secondary)
            }
            TimelineView(.periodic(from: .now, by: 15)) { context in
                reportEntry(at: context.date)
            }
        }
    }

    var readAllReports: some View {
        NavigationLink { VisitorReportsView(store: store, spot: spot) } label: {
            HStack {
                Label("Read all reports", systemImage: "text.bubble")
                    .labelStyle(PlaceActionLabelStyle())
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold))
            }
            .font(.subheadline.weight(.semibold))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }.accessibilityLabel("Read all visitor reports")
    }

    private func reportEntry(at now: Date) -> some View {
        let isCurrent = store.hasCurrentConfirmation(for: spot, at: now) || store.hasUnfinishedReport(for: spot.id)
        return VStack(alignment: .leading, spacing: LayoutSpacing.text) {
            if isCurrent, store.publishedReport(for: spot.id) != nil {
                Label("You’ve shared this visit", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(AppStyle.brand)
                if spot.isNearby {
                    Button("Share a new visit") {
                        if store.beginNewVisitReport(for: spot) { openVisitReport() }
                    }.frame(minHeight: 44)
                }
            } else {
                Button { openVisitReport() } label: {
                    Label(store.reportDrafts[spot.id] != nil && isCurrent
                          ? "Continue report" : "Share how it felt", systemImage: "text.bubble")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(!store.canReportVisit(for: spot, at: now))
                .accessibilityIdentifier("independentVisitReport")
                if store.hasUnfinishedReport(for: spot.id) {
                    Text("Draft saved").font(.footnote).foregroundStyle(.secondary)
                } else if !isCurrent && !spot.isNearby {
                    Button { showReportingHelp = true } label: {
                        Text("Why can’t I share?").font(.subheadline.weight(.semibold))
                            .frame(minHeight: 44).contentShape(Rectangle())
                    }
                }
            }
        }
    }

    var visitorDetails: some View {
        DisclosureGroup(isExpanded: $expandStays) {
            StayDistribution(reports: store.stays(for: spot)).padding(.top, 10)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Label("How long people stayed", systemImage: "hourglass")
                Text("\(store.stays(for: spot).values.reduce(0, +)) reports")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.font(.subheadline)
    }

    var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark").font(.headline).frame(minWidth: 44, minHeight: 44)
                .background(.ultraThickMaterial, in: Circle())
        }
        .buttonStyle(.plain).padding(16)
    }
}

struct PlacePhoto: View {
    let spot: CoolSpot

    var body: some View {
        if spot.id == "library",
           let url = Bundle.main.url(forResource: "RiversideLibraryPrototype", withExtension: "png"),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable().scaledToFill()
                .frame(height: 184).clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Riverside Library example photo")
        }
    }
}

struct CurrentUseSummary: View {
    let count: Int
    @ScaledMetric(relativeTo: .subheadline) private var countSize = 36

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(count)")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(.primary)
                .frame(minWidth: countSize, minHeight: countSize)
                .background(AppStyle.mint, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(count == 0
                     ? "No one has shared recently"
                     : "\(count) \(count == 1 ? "person is" : "people are") cooling off here")
                    .font(.subheadline.weight(.semibold))
                Text("Shared in the last 10 minutes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

struct LivePresenceCard: View {
    let isCheckedIn: Bool
    let isNearby: Bool
    let presenceDeadline: Date?
    let canShareReport: Bool
    let hasUnfinishedReport: Bool
    let action: () -> Void
    let showExplanation: () -> Void
    let report: (CoolingExperience) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.group) {
            if isCheckedIn {
                VStack(alignment: .leading, spacing: 8) {
                    Label("You’re sharing that you’re here",
                          systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppStyle.brand)
                    Text("Your name isn’t shown · Ends at \(presenceDeadline?.formatted(date: .omitted, time: .shortened) ?? "—")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Stop sharing", action: action)
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                }

                Divider()

                if canShareReport || hasUnfinishedReport {
                VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                    Text("How did it feel compared with outside?")
                        .font(.headline)
                    QuickExperienceChoices(action: report)
                }
                } else {
                    Label("You’ve shared this visit", systemImage: "checkmark.circle")
                        .font(.subheadline).foregroundStyle(AppStyle.brand)
                }
            } else {
                Text("Here to cool down?").font(.headline).accessibilityAddTraits(.isHeader)
                if isNearby {
                    shareActionButton
                } else {
                    Text("Available when you’re nearby")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    shareActionButton
                        .disabled(true)
                }

                HStack(spacing: LayoutSpacing.text) {
                    Text("Anonymous · 10 minutes").font(.caption).foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    explanationButton
                }
            }
        }
        .padding(20)
        .background(AppStyle.blue, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
    }

    private var shareActionButton: some View {
        Button(action: action) {
            Text("I’m cooling off here")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityHint("Adds one anonymous person for 10 minutes after checking that you’re nearby")
    }

    private var explanationButton: some View {
        Button("How this works", action: showExplanation)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppStyle.brand)
            .frame(minHeight: 44)
            .buttonStyle(.plain)
    }
}

struct ReportingHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Confirm a visit while you’re nearby").font(.title2.bold())
                    Text("Start a report or share that you’re cooling off here while nearby. You can then start or finish that visit’s report whenever you’re ready, even after leaving.")
                    Text("Already left? Any visit you confirmed is in You → Your reports. There is no deadline. Saving a place alone doesn’t confirm a visit.")
                }.padding(20)
            }
            .navigationTitle("Sharing a visit").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .tint(AppStyle.brand)
    }
}

struct QuickExperienceChoices: View {
    let action: (CoolingExperience) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 8) {
                choices
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { choices }
                VStack(spacing: 8) { choices }
            }
        }
    }

    @ViewBuilder private var choices: some View {
        ForEach(CoolingExperience.allCases) { experience in
            Button(experience.rawValue) { action(experience) }
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 48)
                .padding(.horizontal, 6)
                .foregroundStyle(AppStyle.brand)
                .background(Color(uiColor: .systemBackground),
                            in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppStyle.subtleBorder, lineWidth: 1)
                }
                .buttonStyle(.plain)
        }
    }
}

struct PresenceExplanationSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    PresenceExplanationRow(symbol: "location.fill",
                                           text: "We briefly check that you’re near this Cool Spot.")
                    PresenceExplanationRow(symbol: "person.badge.plus",
                                           text: "The number of people cooling off here increases by one.")
                    PresenceExplanationRow(symbol: "eye.slash.fill",
                                           text: "Your name and exact location aren’t shown.")
                    PresenceExplanationRow(symbol: "clock.fill",
                                           text: "Your share ends automatically after 10 minutes, or you can stop it sooner.")
                    Text("This shows that someone is using the place to cool down. It doesn’t say whether the place feels cool or has space available.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                    PresenceMapExample().padding(.top, 8)
                }
                .padding(20)
            }
            .navigationTitle("How this works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct PresenceExplanationRow: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(AppStyle.brand)
                .frame(width: 30, height: 30)
                .background(AppStyle.mint, in: Circle())
            Text(text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ExperienceDistribution: View {
    let reports: [CoolingExperience: Int]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var maxCount: Int { max(reports.values.max() ?? 1, 1) }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(CoolingExperience.allCases.reversed()) { experience in
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(experience.rawValue).fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                                Text("\(reports[experience, default: 0])").monospacedDigit().fixedSize()
                            }
                            bar(for: experience)
                        }
                    } else {
                        HStack(spacing: 12) {
                            Text(experience.rawValue)
                                .frame(width: 100, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                            bar(for: experience)
                            Text("\(reports[experience, default: 0])")
                                .monospacedDigit().fixedSize()
                                .frame(minWidth: 24, alignment: .trailing)
                        }
                    }
                }
                .font(.caption)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(experience.rawValue): \(reports[experience, default: 0]) \(reports[experience, default: 0] == 1 ? "report" : "reports")")
            }
        }
    }

    private func bar(for experience: CoolingExperience) -> some View {
        GeometryReader { proxy in
            Capsule().fill(AppStyle.brand)
                .frame(width: proxy.size.width * CGFloat(reports[experience, default: 0]) / CGFloat(maxCount))
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

struct StayDistribution: View {
    let reports: [StayLength: Int]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let rows: [StayLength] = [.under15, .under30, .under60, .under120, .over120]
    var maxCount: Int { max(reports.values.max() ?? 1, 1) }
    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows) { length in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(dynamicTypeSize.isAccessibilitySize ? length.rawValue : length.compact)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        Text("\(reports[length, default: 0])").monospacedDigit().fixedSize()
                    }
                    .font(.caption)
                    GeometryReader { proxy in
                        Capsule().fill(AppStyle.brand)
                            .frame(width: proxy.size.width * CGFloat(reports[length, default: 0]) / CGFloat(maxCount))
                    }
                    .frame(height: 9)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(length.rawValue): \(reports[length, default: 0]) reports")
            }
        }
    }
}

struct RecognisedPlaceDetailView: View {
    @ObservedObject var store: PrototypeStore
    let place: RecognisedPlace
    var findNearby: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showContribution = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LayoutSpacing.section) {
                    PlaceIdentityHeader(name: place.name,
                                        address: [place.distance, place.address].filter { !$0.isEmpty }.joined(separator: " · "),
                                        category: place.categoryLabel)
                    VStack(alignment: .leading, spacing: LayoutSpacing.related) {
                        Label("No cooling information yet", systemImage: "thermometer.sun.fill")
                            .font(.headline)
                        if let findNearby {
                            Button(action: findNearby) {
                                Label("Find nearby Cool Spots", systemImage: "map")
                                    .frame(maxWidth: .infinity)
                            }.buttonStyle(PrimaryButtonStyle())
                        }
                    }
                    ApplePlaceInformationView(coordinate: place.coordinate,
                                              placeIdentifier: place.appleMapItemIdentifier,
                                              isExample: !place.id.hasPrefix("apple-maps:"))
                        .id(place.id)
                    Button { showContribution = true } label: {
                        Text("Add cooling information").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    if let saved = store.savedLocations.first(where: { $0.kind == .recognisedPlace(place.id) }) {
                        SavedNoteSummary(store: store, saved: saved).id(saved.id)
                    }
                }
                .padding(20)
            }
            .safeAreaInset(edge: .bottom) {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(spacing: 12) { placeActions }
                    } else {
                        HStack(spacing: 12) { placeActions }
                    }
                }
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
                .background(.bar)
            }
            .overlay(alignment: .topTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").frame(width: 44, height: 44)
                        .background(.ultraThickMaterial, in: Circle())
                }.buttonStyle(.plain).accessibilityLabel("Close").padding(12)
            }
        }
        .tint(AppStyle.brand)
        .sheet(isPresented: $showContribution) {
            ContributionFlow(store: store, source: .recognisedPlace(place))
        }
    }

    @ViewBuilder private var placeActions: some View {
        Link(destination: URL(string: "https://maps.apple.com/?daddr=\(place.latitude),\(place.longitude)&dirflg=w")!) {
            Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        PlaceSaveButton(store: store,
                        saved: store.savedLocations.first { $0.kind == .recognisedPlace(place.id) },
                        toggle: { _ = store.toggleSaved(place) })
    }
}

private struct PlaceActionLabelStyle: LabelStyle {
    @ScaledMetric(relativeTo: .subheadline) private var iconWidth = 20

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            configuration.icon.frame(width: iconWidth).accessibilityHidden(true)
            configuration.title
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ApplePlaceInformationView: View {
    let coordinate: CLLocationCoordinate2D
    var placeIdentifier: MKMapItem.Identifier? = nil
    var isExample = false
    var showsPlaceDetails = true
    var showsNearbyStreets = true
    @State private var scene: MKLookAroundScene?
    @State private var sceneRequest: MKLookAroundSceneRequest?
    @State private var sceneItemRequest: MKMapItemRequest?
    @State private var showStreetView = false
    @State private var loadingScene = true
    @State private var sceneFailed = false
    @State private var sceneAttempt = 0
    @State private var mapItem: MKMapItem?
    @State private var detailRequest: MKMapItemRequest?
    @State private var detailAttempt = 0
    @State private var loadingDetails = false
    @State private var showDetails = false
    @State private var showDetailError = false

    private var sceneKey: String { "\(coordinate.latitude),\(coordinate.longitude):\(sceneAttempt)" }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsPlaceDetails, placeIdentifier != nil {
                Button {
                    if mapItem != nil { showDetails = true }
                    else { detailAttempt += 1 }
                } label: {
                    HStack(spacing: 10) {
                        if loadingDetails { ProgressView() }
                        Label("Place details", systemImage: "info.circle")
                            .labelStyle(PlaceActionLabelStyle())
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain).foregroundStyle(AppStyle.brand)
                .disabled(loadingDetails)
            }
            if showsNearbyStreets {
                DisclosureGroup(isExpanded: $showStreetView) {
                    if showStreetView {
                        VStack(alignment: .leading, spacing: 12) {
                            if let scene {
                                LookAroundPreview(initialScene: scene, pointsOfInterest: .excludingAll)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Text(isExample ? "Near the example location" : "Nearby streets")
                                    .font(.caption).foregroundStyle(AppStyle.supportingText)
                            } else if loadingScene {
                                HStack(spacing: 10) {
                                    ProgressView()
                                    Text("Loading street view…").font(.subheadline)
                                }
                                .frame(minHeight: 44)
                            } else if sceneFailed {
                                Text("Street view couldn’t load.")
                                    .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                                Button("Try street view again") { sceneAttempt += 1 }.frame(minHeight: 44)
                            } else {
                                Text("Street view isn’t available here.")
                                    .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                            }
                        }
                        .padding(.top, 8)
                        .task(id: sceneKey) { await loadScene() }
                        .onDisappear {
                            sceneRequest?.cancel()
                            sceneItemRequest?.cancel()
                        }
                    }
                } label: {
                    Text("View nearby streets").frame(minHeight: 44)
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .task(id: detailAttempt) {
            guard detailAttempt > 0, mapItem == nil else { return }
            await loadDetails()
        }
        .onDisappear {
            sceneRequest?.cancel()
            sceneItemRequest?.cancel()
            detailRequest?.cancel()
        }
        .mapItemDetailSheet(isPresented: $showDetails, item: mapItem)
        .alert("Couldn’t load place details", isPresented: $showDetailError) {
            Button("Try again") { detailAttempt += 1 }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Check your connection and try again.")
        }
    }

    @MainActor private func loadScene() async {
        guard scene == nil else { return }
        sceneRequest?.cancel()
        sceneItemRequest?.cancel()
        scene = nil
        loadingScene = true
        sceneFailed = false
        defer {
            if !Task.isCancelled {
                loadingScene = false
                sceneRequest = nil
                sceneItemRequest = nil
            }
        }
        do {
            if mapItem == nil, let placeIdentifier {
                let itemRequest = MKMapItemRequest(mapItemIdentifier: placeIdentifier)
                sceneItemRequest = itemRequest
                let item = try await itemRequest.mapItem
                try Task.checkCancellation()
                mapItem = item
            }
            let request: MKLookAroundSceneRequest
            if let mapItem {
                // Preserve the place identity instead of treating its coordinate as an entrance.
                request = MKLookAroundSceneRequest(mapItem: mapItem)
            } else {
                request = MKLookAroundSceneRequest(coordinate: coordinate)
            }
            sceneRequest = request
            let result = try await request.scene
            guard !Task.isCancelled else { return }
            scene = result
        } catch {
            guard !Task.isCancelled else { return }
            sceneFailed = true
        }
    }

    @MainActor private func loadDetails() async {
        guard let placeIdentifier else { return }
        loadingDetails = true
        let request = MKMapItemRequest(mapItemIdentifier: placeIdentifier)
        detailRequest = request
        defer {
            if !Task.isCancelled { loadingDetails = false; detailRequest = nil }
        }
        do {
            let result = try await request.mapItem
            guard !Task.isCancelled else { return }
            mapItem = result
            showDetails = true
        } catch {
            guard !Task.isCancelled else { return }
            showDetailError = true
        }
    }
}

struct VisitReportFlow: View {
    @ObservedObject var store: PrototypeStore
    let spot: CoolSpot
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var draft: VisitReportDraft
    @State private var submitted = false
    @State private var helpedExpanded = false
    @State private var showPublishFailure = false
    @State private var showDiscardConfirmation = false

    init(store: PrototypeStore, spot: CoolSpot, initialExperience: CoolingExperience? = nil) {
        self.store = store; self.spot = spot
        var saved = store.reportDrafts[spot.id] ?? VisitReportDraft(visitedAt: store.visitConfirmedAt[spot.id] ?? .now)
        if saved.experience == nil { saved.experience = initialExperience }
        _draft = State(initialValue: saved)
    }
    var body: some View {
        NavigationStack {
            if submitted {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Image(systemName: "checkmark.circle.fill").font(.largeTitle).foregroundStyle(AppStyle.brand)
                        Text("Thanks for the update").font(.largeTitle.bold())
                        Text("Report saved on this device.")
                        Button("Done") { dismiss() }.buttonStyle(PrimaryButtonStyle())
                    }.padding(24)
                }
            } else {
                Form {
                    Section {
                        Text("How did it feel compared with outside?").font(.headline)
                        ForEach(CoolingExperience.allCases) { option in
                            ReportChoice(title: option.rawValue, symbol: option.symbol, selected: draft.experience == option) {
                                draft.experience = option
                            }
                        }
                        DatePicker("Visit time", selection: $draft.visitedAt,
                                   in: ...Date.now,
                                   displayedComponents: [.date, .hourAndMinute])
                    } header: { Text(spot.name).textCase(nil).foregroundStyle(AppStyle.supportingText) }

                    Section {
                        DisclosureGroup(isExpanded: $helpedExpanded) {
                            CoolingFeatureChoices(selection: $draft.helpedFeatures)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("What helped")
                                if !draft.helpedFeatures.isEmpty {
                                    Text(CoolingFeature.allCases.filter { draft.helpedFeatures.contains($0) }.map(\.rawValue).joined(separator: ", "))
                                        .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }.frame(minHeight: 44)
                        }
                        Picker("Time here", selection: $draft.stay) {
                            Text("Not added").tag(nil as StayLength?)
                            ForEach(StayLength.allCases) { Text($0.rawValue).tag(Optional($0)) }
                        }
                        VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                            Text("Comment").font(.subheadline.weight(.semibold))
                            TextField("What would help someone decide?", text: $draft.comment, axis: .vertical)
                                .lineLimit(3...8).accessibilityLabel("Comment, optional")
                        }
                    } header: { Text("More about your visit · Optional").foregroundStyle(AppStyle.supportingText) }
                    footer: { Text("Your draft is saved until you publish.").foregroundStyle(AppStyle.supportingText) }
                    Section { Button("Discard answers", role: .destructive) { showDiscardConfirmation = true } }
                    if dynamicTypeSize.isAccessibilitySize { Section { publishBar } }
                }
                .scrollDismissesKeyboard(.interactively)
                .navigationTitle("Your report")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) {
                    Button("Finish later") { store.saveReportDraft(draft, for: spot.id); dismiss() }
                } }
                .safeAreaInset(edge: .bottom) {
                    if !dynamicTypeSize.isAccessibilitySize { publishBar }
                }
            }
        }
        .tint(AppStyle.brand)
        .onAppear { store.saveReportDraft(draft, for: spot.id) }
        .onChange(of: draft) { _, value in store.saveReportDraft(value, for: spot.id) }
        .confirmationDialog("Discard your private answers?", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
            Button("Discard answers", role: .destructive) { store.discardReportAnswers(spot.id); dismiss() }
        } message: { Text("Your answers will be cleared. Nothing will be published. You can start this confirmed visit’s report again later.") }
        .alert("Report wasn’t published", isPresented: $showPublishFailure) {
            Button("Keep editing", role: .cancel) {}
        } message: { Text("Your answers remain private. Check the visit time and try again.") }
    }
    var publishBar: some View {
        Button {
            guard let experience = draft.experience else { return }
            if store.hasUnfinishedReport(for: spot.id),
               store.submitReport(spot: store.spot(spot.id) ?? spot, experience: experience,
                                  helpedFeatures: draft.helpedFeatures, stay: draft.stay,
                                  comment: draft.comment, visitedAt: draft.visitedAt) {
                submitted = true
            } else { showPublishFailure = true }
        } label: { Text("Publish report").frame(maxWidth: .infinity) }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(draft.experience == nil || !store.hasUnfinishedReport(for: spot.id))
        .padding(16).frame(maxWidth: .infinity).background(.regularMaterial)
    }
}

struct ReportChoice: View {
    let title: String, symbol: String
    let selected: Bool
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: symbol)
                }
                Text(title).layoutPriority(1).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.body)
            }
            .font(.body.weight(selected ? .semibold : .regular))
            .foregroundStyle(selected ? AppStyle.brand : Color.primary)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct PlaceIdentityHeader: View {
    let name: String
    let address: String
    let category: String?
    var source: PlaceInformation.Source? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
            Text(name).font(.title.bold()).padding(.trailing, 44)
                .accessibilityAddTraits(.isHeader)
            if !address.isEmpty { Text(address).font(.subheadline).foregroundStyle(.secondary) }
            HStack(spacing: 6) {
                if let category { Text(category).foregroundStyle(.secondary) }
                if let source {
                    if category != nil { Text("·").foregroundStyle(.secondary) }
                    if let url = source.url {
                        Link(source.label, destination: url)
                            .accessibilityLabel("Place information source: \(source.label)")
                    } else {
                        Text(source.label).foregroundStyle(.secondary)
                    }
                }
            }
            .font(.caption)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
