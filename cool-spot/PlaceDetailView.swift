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
    @State private var expandFeatures = false
    @State private var expandStays = false
    @State private var expandFacilities = false
    @State private var expandMoreInformation = false
    @State private var visitReportPresentation: VisitReportPresentation?
    @State private var showReportUnavailable = false
    @State private var showReportingHelp = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header.padding(.bottom, LayoutSpacing.section)
                        Divider()
                        recentExperience
                            .padding(.vertical, LayoutSpacing.section)
                            .id("visitorReports")
                        if !spot.photos.isEmpty {
                            Divider()
                            PlacePhotoStrip(photos: spot.photos, placeName: spot.name)
                                .padding(.vertical, LayoutSpacing.section)
                        }
                        Divider()
                        supplementaryInformation.padding(.vertical, LayoutSpacing.section)
                        Divider()
                        presenceSection.padding(.vertical, LayoutSpacing.section)
                        if let saved = store.savedLocation(for: spot),
                           !saved.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Divider()
                            SavedNoteSummary(store: store, saved: saved)
                                .padding(.vertical, LayoutSpacing.section).id(saved.id)
                        }
                    }
                    .padding(.horizontal, LayoutSpacing.page)
                    .padding(.top, LayoutSpacing.related)
                }
                .safeAreaInset(edge: .bottom) { actionBar }
                .toolbar { ToolbarItem(placement: .topBarTrailing) { closeButton } }
                .task {
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("--preview-bottom") {
                        proxy.scrollTo("visitorReports", anchor: .top)
                    }
                    #endif
                }
            }
        }
        .tint(AppStyle.actionForeground)
        .alert("Start your report while you’re here", isPresented: $showReportUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You need to be near this Cool Spot to start a report. Once started, you can finish it later in You → Your reports, even after leaving.")
        }
        .sheet(item: $visitReportPresentation) { presentation in
            VisitReportFlow(store: store, spot: spot, initialExperience: presentation.initialExperience)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showContribution) {
            ContributionFlow(store: store, source: .existingCoolSpot(spot))
        }
        .sheet(isPresented: $showPresenceExplanation) {
            PresenceExplanationSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .tint(AppStyle.actionForeground)
        }
        .sheet(isPresented: $showReportingHelp) { ReportingHelpSheet() }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            PlaceIdentityHeader(name: spot.name,
                                address: [distanceContext ?? spot.distance, spot.address]
                                    .filter { !$0.isEmpty }.joined(separator: " · "),
                                category: nil, source: spot.information.source)
                // A source link already contributes a 44-point row around its caption.
                .padding(.bottom, spot.information.source.url == nil ? LayoutSpacing.group : 0)
            VStack(alignment: .leading, spacing: LayoutSpacing.related) {
                coolingFeatures
                if let note = spot.information.coolingDetails,
                   !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(note).font(.subheadline)
                }
            }
            visitingInformation.padding(.top, LayoutSpacing.group)
        }
    }

    private var visitingInformation: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.related) {
            let entry = [spot.access == .unsure ? nil : spot.access.summary, spot.entrySummary]
                .compactMap { $0 }.joined(separator: " · ")
            if !entry.isEmpty { Text(entry) }
            if spot.seating == .none || spot.seating == .limited {
                Text(spot.seating.displayName).fontWeight(.semibold)
            }
            if spot.information.wheelchairAccessible == false {
                Text("Not wheelchair accessible").fontWeight(.semibold)
            }
            if let limit = spot.information.postedStayLimit.label {
                Text(limit).fontWeight(.medium)
            }
            if let area = spot.information.areaDescription,
               !area.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                    Text("Cooling area").fontWeight(.semibold)
                    Text(area)
                }
            }
        }
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var supplementaryInformation: some View {
        VStack(alignment: .leading, spacing: 0) {
            if hasFacilities {
                facilities.padding(.bottom, LayoutSpacing.section)
                Divider()
            }
            DisclosureGroup(isExpanded: $expandMoreInformation) {
                VStack(alignment: .leading, spacing: 0) {
                    if let detail = spot.information.additionalInformation,
                       !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(detail).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, LayoutSpacing.text)
                    }
                    ApplePlaceInformationView(coordinate: spot.coordinate,
                                              placeIdentifier: spot.detailsApplePlaceID.flatMap(MKMapItem.Identifier.init(rawValue:)),
                                              isExample: spot.applePlaceID == nil && spot.isExample).id(spot.id)
                    Button { showContribution = true } label: {
                        Label("Suggest an edit", systemImage: "square.and.pencil")
                            .labelStyle(PlaceActionLabelStyle())
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain).foregroundStyle(AppStyle.actionForeground)
                }
            } label: {
                Text("More place information").font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary).frame(minHeight: 44)
            }
            .padding(.top, hasFacilities ? LayoutSpacing.section : 0)
        }
    }

    private var hasFacilities: Bool {
        spot.information.hasFacilities || spot.information.wheelchairAccessible != nil
            || spot.information.drinkingWater != nil || spot.seating != .unsure
    }

    @ViewBuilder private var facilities: some View {
        if hasFacilities {
            DisclosureGroup(isExpanded: $expandFacilities) {
                VStack(alignment: .leading, spacing: LayoutSpacing.related) {
                    if spot.seating != .unsure {
                        FactRow(symbol: "chair", title: spot.seating.displayName)
                    }
                    if let water = spot.information.drinkingWater {
                        FactRow(symbol: "waterbottle", title: water ? "Drinking water" : "No drinking water")
                    }
                    if let toilets = spot.information.toilets.label {
                        FactRow(symbol: "toilet", title: toilets)
                    }
                    if let accessible = spot.information.wheelchairAccessible {
                        FactRow(symbol: "figure.roll", title: accessible ? "Wheelchair accessible" : "Not wheelchair accessible")
                    }
                    if let staffed = spot.information.staffedWhenOpen {
                        FactRow(symbol: "person.fill", title: staffed ? "Staff on site when open" : "No staff on site")
                    }
                    if let tables = spot.information.tables {
                        FactRow(symbol: "table.furniture", title: tables ? "Tables provided" : "No tables")
                    }
                }
                .padding(.top, LayoutSpacing.text)
            } label: {
                Text("Facilities & accessibility").font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary).frame(minHeight: 44)
            }
        }
    }

    var actionBar: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: LayoutSpacing.text) { placeActions }
            } else {
                HStack(spacing: LayoutSpacing.related) { placeActions }
            }
        }
        .padding(.horizontal, LayoutSpacing.page)
        .padding(.top, LayoutSpacing.related)
        .padding(.bottom, LayoutSpacing.text)
        .background(.bar)
    }

    @ViewBuilder var placeActions: some View {
        Link(destination: directionsURL) {
            Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                .frame(maxWidth: .infinity)
        }.buttonStyle(PrimaryButtonStyle())
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
            Text(evidence.leadingExperience == nil
                 ? "\(evidence.total) reports · Mixed experiences"
                 : "\(evidence.attribution) \(evidence.headline.lowercased())")
                .font(.subheadline.weight(.semibold))
            if let latest = store.latestReportDate(for: spot) {
                Text("Latest visit \(latest.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).foregroundStyle(AppStyle.supportingText)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var presenceSection: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.related) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text("People cooling here").font(.title3.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: LayoutSpacing.text)
                    presenceHelp
                }
                VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                    Text("People cooling here").font(.title3.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    presenceHelp
                }
            }
            CurrentUseSummary(count: store.presence(for: spot))
            LivePresenceActions(isCheckedIn: store.isSharingPresence(for: spot),
                                isNearby: spot.isNearby, presenceDeadline: store.presenceEndsAt,
                                action: {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                    if store.isSharingPresence(for: spot) { store.activePresenceSpotID = nil }
                    else { store.checkIn(spot) }
                }
            })
        }
    }

    private var presenceHelp: some View {
        Button("How it works") { showPresenceExplanation = true }
            .font(.caption.weight(.semibold)).frame(minHeight: 44)
    }

    private func openVisitReport(initialExperience: CoolingExperience? = nil) {
        guard store.beginVisitReport(for: spot, initialExperience: initialExperience) else {
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
        VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
            FlowLayout(spacing: LayoutSpacing.text) {
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
                        .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                }.buttonStyle(.plain).foregroundStyle(AppStyle.actionForeground)
            }
        }
    }

    var recentExperience: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.group) {
            Text("Visitor experiences").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
            if store.experienceReportTotal(for: spot) > 0 {
                VStack(alignment: .leading, spacing: LayoutSpacing.related) {
                    experienceSummary
                    ExperienceDistribution(reports: store.coolingEvidence(for: spot).counts)
                }
                if !store.stays(for: spot).isEmpty { visitorDetails }
            } else {
                Text("No visitor reports yet.").font(.subheadline).foregroundStyle(AppStyle.supportingText)
            }
            if !store.visitorReportItems(for: spot).isEmpty { readAllReports }
            TimelineView(.periodic(from: .now, by: 15)) { context in reportEntry(at: context.date) }
        }
    }

    var readAllReports: some View {
        NavigationLink { VisitorReportsView(store: store, spot: spot) } label: {
            HStack {
                Text("Read all reports")
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold))
            }
            .font(.subheadline.weight(.semibold)).frame(minHeight: 44).contentShape(Rectangle())
        }.accessibilityLabel("Read all visitor reports")
    }

    private func reportEntry(at now: Date) -> some View {
        let history = store.ownReports(for: spot.id)
        return VStack(alignment: .leading, spacing: LayoutSpacing.related) {
            Text("Your reports").font(.headline).accessibilityAddTraits(.isHeader)
            if store.hasUnfinishedReport(for: spot.id), let draft = store.reportDrafts[spot.id] {
                Label("Draft" + (draft.experience.map { " · " + $0.rawValue } ?? ""), systemImage: "square.and.pencil")
                    .font(.subheadline.weight(.semibold))
                visitTime(draft.visitedAt)
                Button { openVisitReport() } label: {
                    Text("Continue report").frame(maxWidth: .infinity)
                }.buttonStyle(SecondaryButtonStyle()).accessibilityIdentifier("independentVisitReport")
            } else if let latest = history.first {
                Label("Published · \(latest.experience.rawValue)", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                visitTime(latest.visitedAt)
                NavigationLink { PublishedVisitReportView(store: store, report: latest) } label: {
                    Text("View your report").frame(maxWidth: .infinity)
                }.buttonStyle(SecondaryButtonStyle())
                if spot.isNearby, store.publishedReport(for: spot.id) != nil {
                    Button("Report another visit") {
                        if store.beginNewVisitReport(for: spot) { openVisitReport() }
                    }.font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                }
            } else if store.canReportVisit(for: spot, at: now) {
                Text("How did it feel compared with outside?").font(.subheadline.weight(.semibold))
                QuickExperienceChoices { openVisitReport(initialExperience: $0) }
                Text("Choose an answer to review your report.")
                    .font(.caption).foregroundStyle(AppStyle.supportingText)
            } else {
                Button { openVisitReport() } label: {
                    Text("Share how it felt").frame(maxWidth: .infinity)
                }.buttonStyle(SecondaryButtonStyle()).disabled(true)
                    .accessibilityIdentifier("independentVisitReport")
                HStack {
                    Text("Start a report while you’re nearby").font(.caption)
                        .foregroundStyle(AppStyle.supportingText)
                    Spacer(minLength: LayoutSpacing.text)
                    Button("Why?") { showReportingHelp = true }
                        .font(.subheadline.weight(.semibold)).frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel("Why can’t I share?")
                }
            }
            if history.count > 1 || (store.hasUnfinishedReport(for: spot.id) && !history.isEmpty) {
                Divider()
                NavigationLink { PlaceOwnReportsView(store: store, spot: spot) } label: {
                    HStack {
                        Text("Your report history · \(history.count)")
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                    }.font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                }
            }
        }
        .padding(LayoutSpacing.group)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppStyle.controlSurface, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("placeOwnReports")
    }

    private func visitTime(_ date: Date) -> some View {
        Text("Visited \(date.formatted(date: .abbreviated, time: .shortened))")
            .font(.caption).foregroundStyle(AppStyle.supportingText)
            .fixedSize(horizontal: false, vertical: true)
    }

    var visitorDetails: some View {
        DisclosureGroup(isExpanded: $expandStays) {
            StayDistribution(reports: store.stays(for: spot)).padding(.top, LayoutSpacing.text)
        } label: {
            Text("How long people stayed").font(.subheadline.weight(.semibold)).frame(minHeight: 44)
        }
    }

    var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark").font(.body.weight(.semibold)).frame(minWidth: 44, minHeight: 44)
        }.accessibilityLabel("Close")
    }
}

struct CurrentUseSummary: View {
    let count: Int
    var body: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
            Text(count == 0 ? "No one has shared recently"
                 : "\(count) \(count == 1 ? "person is" : "people are") cooling off here")
                .font(.subheadline.weight(.semibold))
            Text("In the last 10 minutes").font(.caption).foregroundStyle(AppStyle.supportingText)
        }.accessibilityElement(children: .combine)
    }
}

struct LivePresenceActions: View {
    let isCheckedIn: Bool
    let isNearby: Bool
    let presenceDeadline: Date?
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.text) {
            if isCheckedIn {
                Label("You’re sharing that you’re here", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text("Your name isn’t shown · Ends at \(presenceDeadline?.formatted(date: .omitted, time: .shortened) ?? "—")")
                    .font(.caption).foregroundStyle(AppStyle.supportingText)
                Button("Stop sharing", action: action)
                    .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
            } else {
                Button(action: action) {
                    Text("I’m cooling off here").frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle()).disabled(!isNearby)
                .accessibilityHint("Adds one anonymous person for 10 minutes after checking that you’re nearby")
                Text(isNearby ? "Anonymous · Automatically ends after 10 minutes" : "Available when you’re nearby · Anonymous for 10 minutes")
                    .font(.caption).foregroundStyle(AppStyle.supportingText)
            }
        }
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
        .tint(AppStyle.actionForeground)
    }
}

struct QuickExperienceChoices: View {
    let action: (CoolingExperience) -> Void
    var body: some View {
        VStack(spacing: LayoutSpacing.text) {
            ForEach(CoolingExperience.allCases) { experience in
                ReportChoice(title: experience.rawValue, symbol: experience.symbol, selected: false,
                             showsSelection: false) { action(experience) }
            }
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
                        .foregroundStyle(AppStyle.supportingText)
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
                .foregroundStyle(AppStyle.informationAccent)
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
            ForEach(CoolingExperience.allCases) { experience in
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
            Capsule().fill(AppStyle.controlSurface)
                .overlay(alignment: .leading) {
                    Capsule().fill(AppStyle.dataFill)
                        .frame(width: proxy.size.width * CGFloat(reports[experience, default: 0]) / CGFloat(maxCount))
                }
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
                        Capsule().fill(AppStyle.dataFill)
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
                VStack(alignment: .leading, spacing: LayoutSpacing.group) {
                    VStack(alignment: .leading, spacing: LayoutSpacing.group) {
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
                    }
                    Divider()
                    Button { showContribution = true } label: {
                        Text("Add cooling information").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    if let saved = store.savedLocations.first(where: { $0.kind == .recognisedPlace(place.id) }),
                       !saved.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Divider()
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
                .padding(.horizontal, LayoutSpacing.page).padding(.top, LayoutSpacing.related).padding(.bottom, LayoutSpacing.text)
                .background(.bar)
            }
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").frame(width: 44, height: 44)
                }.accessibilityLabel("Close")
            } }
        }
        .tint(AppStyle.actionForeground)
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
        VStack(alignment: .leading, spacing: 0) {
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
                .buttonStyle(.plain).foregroundStyle(AppStyle.actionForeground)
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
                    Label("View nearby streets", systemImage: "binoculars")
                        .labelStyle(PlaceActionLabelStyle())
                        .foregroundStyle(AppStyle.actionForeground)
                        .frame(minHeight: 44)
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
    private enum PublicationFailure {
        case futureVisit, unavailable
        var message: String {
            switch self {
            case .futureVisit: "Choose a visit time that isn’t in the future. Your answers are kept."
            case .unavailable: "Couldn’t publish your report. Your answers are kept."
            }
        }
        var buttonTitle: String { self == .unavailable ? "Try again" : "Publish report" }
    }
    @ObservedObject var store: PrototypeStore
    let spot: CoolSpot
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var draft: VisitReportDraft
    @State private var submitted = false
    @State private var optionalExpanded = false
    @State private var publishFailure: PublicationFailure?
    @State private var showDiscardConfirmation = false
    #if DEBUG
    @State private var failsNextPreviewPublication = ProcessInfo.processInfo.arguments.contains("--shape-preview")
        && ProcessInfo.processInfo.arguments.contains("--preview-report-failure")
    #endif

    init(store: PrototypeStore, spot: CoolSpot, initialExperience: CoolingExperience? = nil) {
        self.store = store
        self.spot = spot
        var saved = store.reportDrafts[spot.id] ?? VisitReportDraft(visitedAt: store.visitConfirmedAt[spot.id] ?? .now)
        if saved.experience == nil { saved.experience = initialExperience }
        _draft = State(initialValue: saved)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if submitted {
                    confirmation
                } else {
                    VStack(alignment: .leading, spacing: LayoutSpacing.section) {
                        ReportPlaceContext(spot: spot)
                        Divider()
                        experienceQuestion
                        visitTimeQuestion
                        Divider()
                        optionalQuestions
                        Button("Discard answers", role: .destructive) { showDiscardConfirmation = true }
                            .font(.subheadline).foregroundStyle(AppStyle.errorText).frame(minHeight: 44)
                        if dynamicTypeSize.isAccessibilitySize { publishBar }
                    }
                    .padding(LayoutSpacing.page)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Your report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !submitted {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Finish later") { store.saveReportDraft(draft, for: spot.id); dismiss() }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !dynamicTypeSize.isAccessibilitySize {
                    if submitted { doneBar } else { publishBar }
                }
            }
        }
        .tint(AppStyle.actionForeground)
        .onAppear { store.saveReportDraft(draft, for: spot.id) }
        .onChange(of: draft) { _, value in
            store.saveReportDraft(value, for: spot.id)
            publishFailure = nil
        }
        .confirmationDialog("Discard your private answers?", isPresented: $showDiscardConfirmation,
                            titleVisibility: .visible) {
            Button("Discard answers", role: .destructive) { store.discardReportAnswers(spot.id); dismiss() }
        } message: {
            Text("Your answers will be cleared. Nothing will be published. You can start this confirmed visit’s report again later.")
        }
    }

    private var experienceQuestion: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.related) {
            Text("How did it feel compared with outside?").font(.headline).accessibilityAddTraits(.isHeader)
            VStack(spacing: LayoutSpacing.text) {
                ForEach(CoolingExperience.allCases) { option in
                    ReportChoice(title: option.rawValue, symbol: option.symbol, selected: draft.experience == option) {
                        draft.experience = option
                    }
                }
            }
        }
    }

    private var visitTimeQuestion: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.text) {
            DatePicker("Visit time", selection: $draft.visitedAt, in: ...Date.now,
                       displayedComponents: [.date, .hourAndMinute])
                .font(.subheadline)
            Text("When you visited, rather than when you publish.")
                .font(.caption).foregroundStyle(AppStyle.supportingText)
        }
    }

    private var optionalQuestions: some View {
        DisclosureGroup(isExpanded: $optionalExpanded) {
            VStack(alignment: .leading, spacing: LayoutSpacing.section) {
                VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                    Text("What helped").font(.subheadline.weight(.semibold))
                    CoolingFeatureChoices(selection: $draft.helpedFeatures)
                }
                HStack {
                    Text("Time here").accessibilityHidden(true)
                    Spacer(minLength: LayoutSpacing.text)
                    Picker("Time here", selection: $draft.stay) {
                        Text("Not added").tag(nil as StayLength?)
                        ForEach(StayLength.allCases) { Text($0.rawValue).tag(Optional($0)) }
                    }.pickerStyle(.menu).labelsHidden()
                }.font(.subheadline).frame(minHeight: 44)
                VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                    Text("Comment").font(.subheadline.weight(.semibold))
                    Text("Describe how it felt, where you stayed, or anything others should know.")
                        .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                        .fixedSize(horizontal: false, vertical: true)
                    TextField("", text: $draft.comment,
                              prompt: Text("Share more about your visit").foregroundStyle(AppStyle.supportingText),
                              axis: .vertical)
                        .lineLimit(3...8).font(.body)
                        .padding(LayoutSpacing.related)
                        .background(AppStyle.controlSurface, in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Comment, optional")
                }
            }.padding(.top, LayoutSpacing.related)
        } label: {
            VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                Text("More about your visit · Optional").font(.headline)
                let summary = [draft.helpedFeatures.isEmpty ? nil : "\(draft.helpedFeatures.count) helping \(draft.helpedFeatures.count == 1 ? "feature" : "features")",
                               draft.stay?.rawValue,
                               draft.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "Comment added"]
                    .compactMap { $0 }.joined(separator: " · ")
                if !summary.isEmpty {
                    Text(summary).font(.caption).foregroundStyle(AppStyle.supportingText)
                }
            }.foregroundStyle(.primary).frame(minHeight: 44)
        }
    }

    private var confirmation: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.section) {
            Image(systemName: "checkmark.circle.fill").font(.largeTitle).foregroundStyle(AppStyle.actionForeground)
                .accessibilityHidden(true)
            Text("Thanks for sharing your visit").font(.title2.bold()).accessibilityAddTraits(.isHeader)
            ReportPlaceContext(spot: spot)
            if let report = store.publishedReport(for: spot.id) {
                VisitorReportContent(item: .init(id: report.id.uuidString, comment: report.comment,
                                                 report: report, provenance: .own), showsProvenance: false)
            }
            Text("Report saved on this device.").font(.caption).foregroundStyle(AppStyle.supportingText)
            if dynamicTypeSize.isAccessibilitySize { doneBar }
        }.padding(LayoutSpacing.page)
    }

    private var doneBar: some View {
        Button { dismiss() } label: { Text("Done").frame(maxWidth: .infinity) }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, LayoutSpacing.page).padding(.vertical, LayoutSpacing.related)
            .background(.bar)
    }

    private var publishBar: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.text) {
            if let publishFailure {
                Text(publishFailure.message).font(.subheadline).foregroundStyle(AppStyle.errorText)
                    .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("reportPublishFailure")
            }
            Text("Your draft is saved until you publish.")
                .font(.caption).foregroundStyle(AppStyle.supportingText)
                .frame(maxWidth: .infinity, alignment: .center)
            Button(action: publish) {
                Text(publishFailure?.buttonTitle ?? "Publish report").frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(draft.experience == nil || !store.hasUnfinishedReport(for: spot.id))
            .accessibilityIdentifier("publishVisitReport")
        }
        .padding(.horizontal, LayoutSpacing.page)
        .padding(.vertical, LayoutSpacing.related)
        .frame(maxWidth: .infinity).background(.bar)
    }

    private func publish() {
        guard let experience = draft.experience, store.hasUnfinishedReport(for: spot.id) else { return }
        guard draft.visitedAt <= .now else {
            publishFailure = .futureVisit
            return
        }
        #if DEBUG
        if failsNextPreviewPublication {
            failsNextPreviewPublication = false
            publishFailure = .unavailable
            return
        }
        #endif
        if store.submitReport(spot: store.spot(spot.id) ?? spot, experience: experience,
                              helpedFeatures: draft.helpedFeatures, stay: draft.stay,
                              comment: draft.comment, visitedAt: draft.visitedAt) {
            submitted = true
        } else {
            publishFailure = .unavailable
        }
    }
}

struct ReportChoice: View {
    let title: String, symbol: String
    let selected: Bool
    var showsSelection = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LayoutSpacing.related) {
                Image(systemName: symbol).frame(width: 24).accessibilityHidden(true)
                Text(title).layoutPriority(1).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: LayoutSpacing.text)
                if showsSelection {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .accessibilityHidden(true)
                }
            }
            .font(.body.weight(selected ? .semibold : .regular))
            .foregroundStyle(selected ? AppStyle.actionForeground : Color.primary)
            .padding(.horizontal, LayoutSpacing.related)
            .padding(.vertical, LayoutSpacing.text)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(selected ? AppStyle.mint : Color(uiColor: .systemBackground),
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12).stroke(selected ? AppStyle.actionForeground : AppStyle.subtleBorder, lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct ReportPlaceContext: View {
    let spot: CoolSpot
    var body: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.text) {
            Text(spot.name).font(.headline).accessibilityAddTraits(.isHeader)
            if !spot.address.isEmpty { Text(spot.address).font(.subheadline).foregroundStyle(AppStyle.supportingText) }
            if let area = spot.information.areaDescription,
               !area.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Cooling area: \(area)").font(.caption).foregroundStyle(AppStyle.supportingText)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("reportPlaceContext")
    }
}

private struct PlaceIdentityHeader: View {
    let name: String
    let address: String
    let category: String?
    var source: PlaceInformation.Source? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                Text(name).font(.title.bold()).accessibilityAddTraits(.isHeader)
                if !address.isEmpty { Text(address).font(.subheadline).foregroundStyle(AppStyle.supportingText) }
            }
            if category != nil || source != nil {
                HStack(spacing: LayoutSpacing.text) {
                    if let category { Text(category).foregroundStyle(AppStyle.supportingText) }
                    if let source {
                        if let url = source.url {
                            Link(destination: url) {
                                Label(source.label, systemImage: "info.circle")
                                    .frame(minHeight: 44)
                            }.foregroundStyle(AppStyle.supportingText)
                                .accessibilityLabel("Place information source: \(source.label)")
                        } else {
                            Text(source.isExample ? "Example" : source.label).foregroundStyle(AppStyle.supportingText)
                        }
                    }
                }
                .font(.caption)
                .padding(.top, source?.url == nil ? LayoutSpacing.text : 0)
            }
        }.fixedSize(horizontal: false, vertical: true)
    }
}
