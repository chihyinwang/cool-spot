import SwiftUI
import TipKit

struct LivePresenceTip: Tip {
    var title: Text {
        Text("Help others decide whether to come here")
    }

    var message: Text? {
        Text("Let others know you’re here to cool down. For 10 minutes, they’ll see one more person here—not your name.")
    }

    var image: Image? {
        Image(systemName: "person.2.fill")
    }
}

private struct VisitReportPresentation: Identifiable {
    let id = UUID()
    let initialExperience: CoolingExperience?
}

// Local reading rhythm, not a new app-wide design system. Keep copy and flow intact.
private enum PlaceDetailRhythm {
    static let relatedText: CGFloat = 8
    static let sectionContent: CGFloat = 16
    static let relatedSections: CGFloat = 24
    static let sectionBreak: CGFloat = 32
}

struct CoolSpotDetailView: View {
    @ObservedObject var store: PrototypeStore
    let spot: CoolSpot
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContribution = false
    @State private var showPresenceExplanation = false
    @State private var showProblem = false
    @State private var expandFeatures = false
    @State private var expandStays = false
    @State private var visitReportPresentation: VisitReportPresentation?
    @State private var showReportUnavailable = false
    @State private var showReportingHelp = false

    private let livePresenceTip = LivePresenceTip()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PlacePhoto(spot: spot)
                        .frame(height: 184)
                        .clipped()
                    VStack(alignment: .leading, spacing: PlaceDetailRhythm.sectionBreak) {
                        VStack(alignment: .leading, spacing: PlaceDetailRhythm.relatedSections) {
                            header
                            experienceSummary
                        }
                        VStack(alignment: .leading, spacing: PlaceDetailRhythm.sectionContent) {
                            coolingFeatures
                            CurrentUseSummary(count: store.presence(for: spot))
                        }
                        visitPlanning
                        recentExperience
                        livePresence
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
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .topTrailing) { closeButton }
            .safeAreaInset(edge: .bottom) { actionBar }
        }
        .tint(AppStyle.brand)
        .alert("Report a problem", isPresented: $showProblem) {
            Button("Cancel", role: .cancel) {}
            Button("Send report") {}
        } message: {
            Text("Use this for a missing place, private residence, misplaced pin, duplicate, or unsafe content—not simply because it felt warm today.")
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
            ReportingHelpSheet(hasExpiredVisit: store.visitConfirmedAt[spot.id] != nil)
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(spot.name).font(.title.bold())
                .accessibilityAddTraits(.isHeader)
            Text("\(spot.distance) · \(spot.address)").font(.subheadline).foregroundStyle(.secondary)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 8) { sourceAndType }
                    .fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: 8) { sourceAndType }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(spot.access == .unsure ? "Entry requirements not confirmed" : spot.access.rawValue) · \(spot.seating == .unsure ? "Seating not confirmed" : spot.seating.rawValue)")
                    .font(.subheadline.weight(.medium))
                Text("Opening hours not verified")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
        }
    }

    @ViewBuilder private var sourceAndType: some View {
        SourceBadge(source: spot.source)
        Text(spot.type == .culture ? spot.type.rawValue : spot.type.shortName)
            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
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

        Button {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                _ = store.toggleSaved(spot)
            }
        } label: {
            Label(store.isSaved(spotID: spot.id) ? "Saved" : "Save",
                  systemImage: store.isSaved(spotID: spot.id) ? "bookmark.fill" : "bookmark")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    var directionsURL: URL {
        URL(string: "https://maps.apple.com/?daddr=\(spot.latitude),\(spot.longitude)&dirflg=w")!
    }

    var experienceSummary: some View {
        let evidence = store.coolingEvidence(for: spot)
        return VStack(alignment: .leading, spacing: 12) {
            if evidence.total > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text(evidence.attribution)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                    Text(evidence.headline)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    if let latest = store.latestReportDate(for: spot) {
                        Text("Latest reported visit \(latest.formatted(.relative(presentation: .numeric)))")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.82))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppStyle.ink, in: RoundedRectangle(cornerRadius: 16))
                .accessibilityElement(children: .combine)
                ExperienceDistribution(reports: evidence.counts)
                Text("Visitor experiences, not a guarantee of current conditions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(evidence.headline).font(.headline)
                    Text("We don’t yet know how it felt to visitors. Use the cooling features and entry information to help you decide.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppStyle.controlSurface, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    var livePresence: some View {
        LivePresenceCard(isCheckedIn: store.isSharingPresence(for: spot),
                         isNearby: spot.isNearby,
                         presenceDeadline: store.presenceEndsAt,
                         reportDeadline: store.publishedReport(for: spot.id) == nil ? store.reportingDeadline(for: spot.id) : nil,
                         hasUnfinishedReport: store.hasUnfinishedReport(for: spot.id),
                         tip: livePresenceTip,
                         action: {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                if store.isSharingPresence(for: spot) {
                    store.activePresenceSpotID = nil
                } else {
                    store.checkIn(spot)
                    livePresenceTip.invalidate(reason: .actionPerformed)
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

    var coolingFeatures: some View {
        VStack(alignment: .leading, spacing: PlaceDetailRhythm.sectionContent) {
            VStack(alignment: .leading, spacing: PlaceDetailRhythm.relatedText) {
                Text("Why it may help you cool down").font(.title3.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(spot.source == .gla ? "Place information from the Greater London Authority"
                                        : "Community-submitted place information, reviewed before publication")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 4) {
                FlowLayout(spacing: 8) {
                    ForEach(expandFeatures ? spot.features : Array(spot.features.prefix(3))) {
                        InfoPill(feature: $0)
                    }
                }
                if spot.features.count > 3 {
                    Button {
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { expandFeatures.toggle() }
                    } label: {
                        Label(expandFeatures ? "Show fewer cooling features"
                                             : "Show all \(spot.features.count) cooling features",
                              systemImage: expandFeatures ? "chevron.up" : "chevron.down")
                            .font(.subheadline.weight(.semibold))
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppStyle.brand)
                }
            }
            if !spot.features.contains(.airConditioning) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Air conditioning not confirmed", systemImage: "questionmark.circle")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button { showContribution = true } label: {
                        Text("Edit cooling features")
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .font(.subheadline.weight(.semibold))
                    .tint(AppStyle.brand)
                }
            }
        }
    }

    var visitPlanning: some View {
        VStack(alignment: .leading, spacing: PlaceDetailRhythm.sectionContent) {
            VStack(alignment: .leading, spacing: PlaceDetailRhythm.relatedText) {
                Text("Before you go").font(.headline).accessibilityAddTraits(.isHeader)
                Text("Check the venue’s opening hours before setting off.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            FactRow(symbol: "figure.roll", title: "Wheelchair access not confirmed")
            VStack(alignment: .leading, spacing: 0) {
                Button { showContribution = true } label: {
                    Text("Add or correct place details")
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .font(.subheadline.weight(.semibold))
                Text("Cooling features, access, seating or photo")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    var recentExperience: some View {
        VStack(alignment: .leading, spacing: PlaceDetailRhythm.sectionContent) {
            Text("Visitor reports").font(.headline).accessibilityAddTraits(.isHeader)
            visitorDetails
            NavigationLink {
                VisitorReportsView(store: store, spot: spot)
            } label: {
                Label("Read all visitor reports", systemImage: "text.bubble")
                    .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
            }
            TimelineView(.periodic(from: .now, by: 15)) { context in
                reportEntry(at: context.date)
            }
        }
    }

    private func reportEntry(at now: Date) -> some View {
        let isCurrent = store.hasCurrentConfirmation(for: spot, at: now) || store.hasUnfinishedReport(for: spot.id)
        return VStack(alignment: .leading, spacing: PlaceDetailRhythm.relatedText) {
            if isCurrent, store.publishedReport(for: spot.id) != nil {
                Label("You’ve shared this visit", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(AppStyle.brand)
            } else {
                Button { openVisitReport() } label: {
                    Label(store.reportDrafts[spot.id] != nil && isCurrent
                          ? "Continue report" : "Share how it felt", systemImage: "text.bubble")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(!store.canReportVisit(for: spot, at: now))
                .accessibilityIdentifier("independentVisitReport")
                if store.hasUnfinishedReport(for: spot.id) {
                    Text("Your answers are private. Continue here or in You → Your reports, even after leaving.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else if isCurrent, let deadline = store.reportingDeadline(for: spot.id) {
                    Text("Start by \(deadline.formatted(date: .abbreviated, time: .shortened)). Once started, you can finish later in You → Your reports.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else if spot.isNearby {
                    Text("Start while you’re here. You can finish later in You → Your reports, even after leaving.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else {
                    Text(store.visitConfirmedAt[spot.id] == nil
                         ? "Start while you’re here. You can finish later, even after leaving."
                         : "There’s no started report for this visit. Start one when you’re here again.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button { showReportingHelp = true } label: {
                        Text("Why can’t I share?").font(.subheadline.weight(.semibold))
                            .frame(minHeight: 44).contentShape(Rectangle())
                    }
                }
            }
        }
    }

    var visitorDetails: some View {
        VStack(alignment: .leading, spacing: PlaceDetailRhythm.sectionContent) {
            DisclosureGroup(isExpanded: $expandStays) {
                StayDistribution(reports: store.stays(for: spot)).padding(.top, 10)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Label("How long people stayed", systemImage: "hourglass")
                    Text("\(store.stays(for: spot).values.reduce(0, +)) reports")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            ForEach(Array(store.comments(for: spot).prefix(2).enumerated()), id: \.offset) { _, text in
                VStack(alignment: .leading, spacing: PlaceDetailRhythm.relatedText) {
                    NavigationLink {
                        VisitorReportsView(store: store, spot: spot)
                    } label: {
                        Text("“\(text)”").font(.subheadline).foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    Text("Visitor report").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
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
        Group {
            if spot.id == "library",
               let url = Bundle.main.url(forResource: "RiversideLibraryPrototype", withExtension: "png"),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel("Riverside Library entrance")
            } else {
                PlaceCover(type: spot.type, environment: spot.environment)
            }
        }
        .clipped()
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
    let reportDeadline: Date?
    let hasUnfinishedReport: Bool
    let tip: LivePresenceTip
    let action: () -> Void
    let showExplanation: () -> Void
    let report: (CoolingExperience) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PlaceDetailRhythm.sectionContent) {
            if isCheckedIn {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Others can now see one more person here",
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

                if reportDeadline != nil || hasUnfinishedReport {
                VStack(alignment: .leading, spacing: 9) {
                    Text("How did it feel compared with outside?")
                        .font(.headline)
                    Text("Optional. This is separate from letting people know you’re here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    QuickExperienceChoices(action: report)
                    if hasUnfinishedReport {
                        Text("Your report is started. You can finish it later in You → Your reports.")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else if let reportDeadline {
                        Text("Start a report by \(reportDeadline.formatted(date: .abbreviated, time: .shortened)) in You → Your reports. Once started, you can finish later.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                } else {
                    Label("You’ve shared this visit", systemImage: "checkmark.circle")
                        .font(.subheadline).foregroundStyle(AppStyle.brand)
                }
            } else {
                Text("Here to cool down?").font(.headline).accessibilityAddTraits(.isHeader)
                if isNearby {
                    TipView(tip, arrowEdge: .bottom)
                    shareActionButton
                } else {
                    Text("You can share this when you’re near this Cool Spot.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    shareActionButton
                        .disabled(true)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 5) {
                        Text("Others see the number, not your name")
                        Text("·")
                        explanationButton
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Others see the number, not your name")
                        explanationButton
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
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
    let hasExpiredVisit: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(hasExpiredVisit ? "The time to share this visit has ended" : "Start your report before you leave")
                        .font(.title2.bold())
                    Text(hasExpiredVisit
                         ? "Sharing that you’re cooling off here gives you 24 hours to start a report. Once you start a report, there’s no deadline to finish it."
                         : "To help keep reports tied to visits, we check that you’re nearby when you start a report or share that you’re cooling off here.")
                    if !hasExpiredVisit {
                        Text("Already left? If you didn’t do either while nearby, this visit can’t be shared. Saving a place or location doesn’t start a report.")
                        Text("Next time, open Share how it felt while you’re there and choose Finish later. Continue in You → Your reports whenever you’re ready. This won’t add you to the people count.")
                    }
                    Text("Being nearby doesn’t prove someone went inside or felt cool.")
                        .font(.footnote).foregroundStyle(.secondary)
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var draft: VisitReportDraft
    @State private var submitted = false
    @State private var showPublishFailure = false
    @State private var showDiscardConfirmation = false

    init(store: PrototypeStore, spot: CoolSpot, initialExperience: CoolingExperience? = nil) {
        self.store = store
        self.spot = spot
        var savedDraft = store.reportDrafts[spot.id]
            ?? VisitReportDraft(visitedAt: store.visitConfirmedAt[spot.id] ?? .now)
        if savedDraft.experience == nil { savedDraft.experience = initialExperience }
        _draft = State(initialValue: savedDraft)
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
                    Section { Text(spot.name).font(.headline) }
                    Section {
                        VStack(spacing: 10) {
                            ForEach(CoolingExperience.allCases) { option in
                                ReportChoice(title: option.rawValue,
                                             symbol: option.symbol,
                                             selected: draft.experience == option) {
                                    draft.experience = option
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    } header: {
                        Text("How did it feel compared with outside?")
                    } footer: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Choose Finish later to return from You → Your reports.")
                            if dynamicTypeSize.isAccessibilitySize {
                                TimelineView(.periodic(from: .now, by: 15)) { context in
                                    publicationStatus(at: context.date)
                                }
                            }
                        }
                    }
                    Section {
                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Visit time").font(.headline)
                                visitTimePicker.labelsHidden()
                            }
                        } else {
                            visitTimePicker
                        }
                    } footer: {
                        Text("Check the time of the visit you’re sharing.")
                    }
                    Section("What helped? (Optional)") {
                        ForEach(CoolingFeature.allCases) { feature in
                            Button {
                                if draft.helpedFeatures.contains(feature) {
                                    draft.helpedFeatures.remove(feature)
                                } else {
                                    draft.helpedFeatures.insert(feature)
                                }
                            } label: {
                                HStack {
                                    Label(feature.rawValue, systemImage: feature.symbol)
                                    Spacer()
                                    if draft.helpedFeatures.contains(feature) {
                                        Image(systemName: "checkmark")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .foregroundStyle(.primary)
                            }
                            .accessibilityAddTraits(draft.helpedFeatures.contains(feature) ? .isSelected : [])
                            .buttonStyle(.plain)
                        }
                    }
                    Section {
                        Picker("How long did you stay?", selection: $draft.stay) {
                            Text("Skip").tag(StayLength?.none)
                            ForEach(StayLength.allCases) { Text($0.rawValue).tag(StayLength?.some($0)) }
                        }
                    } footer: {
                        Text("Optional. Results appear as a compact distribution with a sample size.")
                    }
                    Section {
                        TextField("Optional comment", text: $draft.comment, axis: .vertical).lineLimit(3...6)
                    } footer: {
                        Text("Comments publish with the report and can be reported for abuse or private information.")
                    }
                    Section {
                        Button("Discard answers", role: .destructive) { showDiscardConfirmation = true }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    TimelineView(.periodic(from: .now, by: 15)) { context in
                    VStack(spacing: 8) {
                        if !dynamicTypeSize.isAccessibilitySize {
                            publicationStatus(at: context.date).multilineTextAlignment(.center)
                        }
                        if draft.experience == nil {
                            Text("Choose how it felt to publish")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Button {
                            guard let experience = draft.experience else { return }
                            // An open form belongs to its original visit. Never silently renew it.
                            if store.hasUnfinishedReport(for: spot.id),
                               store.submitReport(spot: store.spot(spot.id) ?? spot, experience: experience,
                                                  helpedFeatures: draft.helpedFeatures,
                                                  stay: draft.stay, comment: draft.comment,
                                                  visitedAt: draft.visitedAt) {
                                submitted = true
                            } else {
                                showPublishFailure = true
                            }
                        } label: { Text("Publish report").frame(maxWidth: .infinity) }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(draft.experience == nil || !store.hasUnfinishedReport(for: spot.id))
                    }
                    .padding(16).background(.ultraThickMaterial)
                    }
                }
                .navigationTitle("Your report")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Finish later") {
                            store.saveReportDraft(draft, for: spot.id)
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear { store.saveReportDraft(draft, for: spot.id) }
        .tint(AppStyle.brand)
        .onChange(of: draft) { _, value in store.saveReportDraft(value, for: spot.id) }
        .confirmationDialog("Discard your private answers?", isPresented: $showDiscardConfirmation,
                            titleVisibility: .visible) {
            Button("Discard answers", role: .destructive) {
                store.removePrivateVisit(spot.id)
                dismiss()
            }
        } message: {
            Text("Nothing will be published. If you’ve left, you won’t be able to start this report again.")
        }
        .alert("Report wasn’t published", isPresented: $showPublishFailure) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your answers remain private. Check the visit time and try again.")
        }
    }

    private var visitTimePicker: some View {
        DatePicker("Visit time", selection: $draft.visitedAt,
                   in: (store.visitConfirmedAt[spot.id] ?? .now).addingTimeInterval(-24 * 60 * 60)...Date.now,
                   displayedComponents: [.date, .hourAndMinute])
    }

    @ViewBuilder private func publicationStatus(at now: Date) -> some View {
        Text("Your answers stay private until you publish.")
            .font(.caption).foregroundStyle(.secondary)
    }
}

struct ReportChoice: View {
    let title: String, symbol: String
    let selected: Bool
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: symbol)
                }
                Text(title).layoutPriority(1)
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.body)
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
