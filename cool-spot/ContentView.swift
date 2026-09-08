import SwiftUI

struct ContentView: View {
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .light
    @StateObject private var store: PrototypeStore
    @State private var selectedTab: Int
    @State private var showDetailPreview: Bool
    @State private var showContributionPreview: Bool
    private let detailPreviewSpotID: String
    private let usesReportExamples: Bool

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        #if DEBUG
        usesReportExamples = arguments.contains("--reports-test-fixtures")
        #else
        usesReportExamples = false
        #endif
        let initialStore = PrototypeStore(reportDefaults: usesReportExamples || arguments.contains("--shape-preview") ? nil : .standard)
        if usesReportExamples {
            // Isolated, memory-only examples: never overwrite saved places or real local reports.
            for (index, fixture) in initialStore.spots.enumerated() {
                var spot = fixture
                spot.isNearby = true
                let visit = Date.now.addingTimeInterval(-Double(index + 2) * 86_400)
                if initialStore.beginVisitReport(for: spot, at: visit) {
                    initialStore.saveReportDraft(.init(experience: .aLittleCooler,
                                                       comment: "Example answer for layout testing.", visitedAt: visit),
                                                 for: spot.id)
                }
            }
            initialStore.simulateNearbySpot(nil)
        }
        _store = StateObject(wrappedValue: initialStore)
        if let index = arguments.firstIndex(of: "--detail-spot"), arguments.indices.contains(index + 1) {
            detailPreviewSpotID = arguments[index + 1]
        } else {
            detailPreviewSpotID = "library"
        }
        let requestedTab: Int
        if arguments.contains("--saved-tab") {
            requestedTab = 1
        } else if arguments.contains("--you-tab") {
            requestedTab = 2
        } else {
            requestedTab = 0
        }
        _selectedTab = State(initialValue: requestedTab)
        _showDetailPreview = State(initialValue: arguments.contains("--detail-preview"))
        _showContributionPreview = State(initialValue: arguments.contains("--contribution-preview"))
    }

    var body: some View {
        #if DEBUG
        if let index = ProcessInfo.processInfo.arguments.firstIndex(of: "--shape-preview"),
           ProcessInfo.processInfo.arguments.indices.contains(index + 1) {
            ShapeInspectionView(screen: ProcessInfo.processInfo.arguments[index + 1])
        } else { mainApp }
        #else
        mainApp
        #endif
    }

    var mainApp: some View {
        TabView(selection: $selectedTab) {
            ExploreView(store: store)
                .tabItem { Label("Explore", systemImage: "map") }
                .tag(0)

            SavedView(store: store)
                .tabItem { Label("Saved", systemImage: "bookmark") }
                .tag(1)

            YouView(store: store, appearance: $appearance)
                .tabItem { Label("You", systemImage: "person.crop.circle") }
                .tag(2)
        }
        .tint(AppStyle.brand)
        .sheet(isPresented: $showDetailPreview) {
            if let spot = store.spot(detailPreviewSpotID) {
                CoolSpotDetailView(store: store, spot: spot)
            }
        }
        .sheet(isPresented: $showContributionPreview) {
            ContributionFlow(store: store, source: .currentLocation)
        }
        .preferredColorScheme(appearance.colorScheme)
        .task {
            while !Task.isCancelled {
                store.endExpiredPresence()
                do { try await Task.sleep(for: .seconds(1)) } catch { break }
            }
        }
    }
}

#Preview {
    ContentView()
}

#if DEBUG
// Developer inspection only: real production views, memory-only data and local
// accessibility overrides. Does not read/write the user's stored journeys.
private struct ShapeInspectionView: View {
    let screen: String
    @StateObject private var store = PrototypeStore()
    private let args = ProcessInfo.processInfo.arguments
    @State private var presented = true
    init(screen: String) {
        self.screen = screen
        let memoryStore = PrototypeStore()
        if ProcessInfo.processInfo.arguments.contains("--preview-entry-requirements") {
            memoryStore.spots[0].entryEligibility = .limited
            memoryStore.spots[0].entryRequirement = "Example: university students and staff only"
            memoryStore.spots[0].entryInformation = "Example: book a free ticket before visiting"
        }
        if screen == "visitor-reports" || screen == "place" {
            // Read existing local reports for layout inspection, but never write
            // preview actions to the user's persisted store.
            memoryStore.visitReports = PrototypeStore(reportDefaults: .standard).visitReports
        }
        if screen == "visitor-reports-peer" {
            let date = ISO8601DateFormatter().date(from: "2026-09-03T10:00:00Z")!
            memoryStore.visitReports = [.init(id: UUID(), spotID: "library", experience: .aLittleCooler,
                helpedFeatures: [], stayLength: nil, comment: "Layout test: an older personal report.",
                visitedAt: date, confirmationAt: date, submittedAt: date)]
        }
        _store = StateObject(wrappedValue: memoryStore)
    }
    var body: some View {
        Color(.systemBackground)
            .sheet(isPresented: $presented) {
                content
                    .environment(\.dynamicTypeSize, args.contains("--preview-large") ? .accessibility5 : .large)
                    .tint(AppStyle.brand)
            }
            .preferredColorScheme(args.contains("--preview-dark") ? .dark : .light)
            .environment(\.dynamicTypeSize, args.contains("--preview-large") ? .accessibility5 : .large)
            .tint(AppStyle.brand)
    }
    @ViewBuilder var content: some View {
        switch screen {
        case "report", "report-required":
            if let spot = store.spot("library") {
                VisitReportFlow(store: store, spot: spot, initialExperience: screen == "report" ? .muchCooler : nil)
                    .onAppear { _ = store.beginVisitReport(for: spot) }
            }
        case "visitor-reports", "visitor-reports-peer":
            NavigationStack { VisitorReportsView(store: store, spot: store.spots[0]) }
        case "new-place": ContributionFlow(store: store, source: .recognisedPlace(store.recognisedPlaces[0]))
        case "update": ContributionFlow(store: store, source: .existingCoolSpot(store.spots[0]))
        case "contribution": ContributionFlow(store: store, source: .currentLocation)
        case "contribution-pin": ContributionFlow(store: store, source: .savedCoordinate(store.savedLocations[0]))
        case "pin":
            if let saved = store.savedLocations.first(where: { $0.kind == .coordinate }) { SavedDetail(store: store, savedID: saved.id) }
        case "place": CoolSpotDetailView(store: store, spot: store.spots[0])
        case "markers":
            NavigationStack {
                ScrollView { VStack(spacing: 60) {
                    ForEach(args.contains("--preview-bottom") ? [100, 10, 3, 2, 0] : [0, 2, 3, 10, 100], id: \.self) { count in
                        HStack(spacing: 24) { CoolSpotPin(type: .library, count: count); Text("\(count) shared presences") }.padding(.top, 32)
                    }
                }.padding(24) }.navigationTitle("Marker inspection")
            }
        default: PresenceExplanationSheet()
        }
    }
}
#endif
