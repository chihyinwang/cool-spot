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
        let initialStore = PrototypeStore(reportDefaults: usesReportExamples ? nil : .standard)
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
