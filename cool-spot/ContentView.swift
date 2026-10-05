import MapKit
import SwiftUI

struct ContentView: View {
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .light
    @StateObject private var store: PrototypeStore
    @StateObject private var catalogue: CoolSpotsCatalogueViewModel
    #if DEBUG
    @State private var inspectionAppearance: AppAppearance = .light
    #endif
    @State private var catalogueLoadAttempt = 0
    @State private var selectedTab: Int
    @State private var nearbyPlaceRequest: RecognisedPlace?
    @State private var showDetailPreview: Bool
    @State private var showContributionPreview: Bool
    private let detailPreviewSpotID: String
    private let usesReportExamples: Bool

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        #if DEBUG
        usesReportExamples = arguments.contains("--reports-test-fixtures")
        let usesExploreLayoutPreview = arguments.contains("--explore-layout-preview")
        let usesContributionLayoutPreview = arguments.contains("--contribution-layout-preview")
            || Bundle.main.bundleIdentifier?.hasPrefix("com.chihyinwang.cool-spot.contribution-preview") == true
        #else
        usesReportExamples = false
        let usesExploreLayoutPreview = false
        let usesContributionLayoutPreview = false
        #endif
        // Preserve the previous launch argument for existing local QA shortcuts.
        let usesExamples = usesReportExamples || usesContributionLayoutPreview || arguments.contains("--shape-preview")
            || arguments.contains("--example-cool-spots") || arguments.contains("--example-catalog")
        let initialStore: PrototypeStore
        if usesExploreLayoutPreview {
            initialStore = PrototypeStore(reportDefaults: nil, catalogueMode: .api)
        } else {
            initialStore = usesExamples
                ? PrototypeStore(reportDefaults: nil)
                : PrototypeStore(reportDefaults: .standard, catalogueMode: .api)
        }
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
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 10
        let loader = CoolSpotsAPILoader(
            url: URL(string: "http://127.0.0.1:8000/functions/v1/cool-spots")!,
            session: URLSession(configuration: configuration)
        )
        _catalogue = StateObject(wrappedValue: CoolSpotsCatalogueViewModel(
            load: loader.load, didLoad: initialStore.replaceAPICatalogue
        ))
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
        if ProcessInfo.processInfo.arguments.contains("--contribution-layout-preview")
            || Bundle.main.bundleIdentifier?.hasPrefix("com.chihyinwang.cool-spot.contribution-preview") == true {
            ContributionLayoutInspectionView()
        } else if let index = ProcessInfo.processInfo.arguments.firstIndex(of: "--shape-preview"),
           ProcessInfo.processInfo.arguments.indices.contains(index + 1) {
            ShapeInspectionView(screen: ProcessInfo.processInfo.arguments[index + 1])
        } else { mainApp }
        #else
        mainApp
        #endif
    }

    #if DEBUG
    // Frozen rendering states for native UI checks, without requests or catalogue fallback.
    private var fixedCatalogueInspectionState: CoolSpotsCatalogueViewModel.State? {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--explore-layout-preview"),
              let index = arguments.firstIndex(of: "--preview-catalogue-state"),
              arguments.indices.contains(index + 1) else { return nil }
        switch arguments[index + 1] {
        case "idle": return .idle
        case "loading": return .loading
        case "failed": return .failed
        case "empty": return .loaded([])
        default: return nil
        }
    }
    #endif

    private var activeCatalogueState: CoolSpotsCatalogueViewModel.State? {
        guard store.usesAPICatalogue else { return nil }
        #if DEBUG
        return fixedCatalogueInspectionState ?? catalogue.state
        #else
        return catalogue.state
        #endif
    }

    private var appearanceSelection: Binding<AppAppearance> {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--explore-layout-preview") {
            return $inspectionAppearance
        }
        #endif
        return $appearance
    }

    var mainApp: some View {
        TabView(selection: $selectedTab) {
            ExploreView(store: store, nearbyPlaceRequest: $nearbyPlaceRequest,
                        catalogueState: activeCatalogueState,
                        retryCatalogue: {
                            if catalogue.requestRetry() { catalogueLoadAttempt += 1 }
                        })
                .tabItem { Label("Explore", systemImage: "map") }
                .tag(0)

            SavedView(store: store, findNearby: { place in
                nearbyPlaceRequest = place
                selectedTab = 0
            })
                .tabItem { Label("Saved", systemImage: "bookmark") }
                .tag(1)

            YouView(store: store, appearance: appearanceSelection)
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
        .preferredColorScheme(appearanceSelection.wrappedValue.colorScheme)
        .task(id: catalogueLoadAttempt) {
            guard store.usesAPICatalogue else { return }
            #if DEBUG
            guard case .none = fixedCatalogueInspectionState else { return }
            #endif
            await catalogue.loadIfNeeded()
        }
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
private struct ShapeInspectionView: View {
    let screen: String
    @StateObject private var store = PrototypeStore()
    private let args = ProcessInfo.processInfo.arguments
    @State private var presented = true
    @State private var detailDetent: PresentationDetent = .large
    init(screen: String) {
        self.screen = screen
        let memoryStore = PrototypeStore()
        if screen == "detail-report",
           var spot = PrototypeComparisonPlaces.communitySpots.first(where: { $0.name == "Example Community Room" }) {
            let arguments = ProcessInfo.processInfo.arguments
            func option(_ name: String, fallback: String) -> String {
                guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return fallback }
                return arguments[index + 1]
            }
            // Explicit, disposable examples exercise the normal views and store.
            // They never read or overwrite the owner's persisted journeys.
            let scenario = option("--preview-report-state", fallback: "first")
            let photoCount = Int(option("--preview-detail-photos", fallback: "0")) ?? 0
            spot.photos = Array(spot.photos.prefix(photoCount))
            spot.information.areaDescription = "Fourth-floor reading room"
            spot.information.wheelchairAccessible = false
            spot.experienceReports = [:]
            spot.stayReports = [:]
            spot.comments = []
            spot.presenceCount = 0
            let detailStore = PrototypeStore(reportDefaults: nil, catalogueMode: .api)
            detailStore.replaceAPICatalogue([spot])
            detailStore.simulateNearbySpot(spot.id)
            let now = Date.now
            if scenario == "history" {
                for offset in [4, 2, 0] {
                    let date = now.addingTimeInterval(-Double(offset) * 86_400 - 600)
                    let nearby = detailStore.spot(spot.id)!
                    if detailStore.publishedReport(for: spot.id) != nil {
                        _ = detailStore.beginNewVisitReport(for: nearby, at: date)
                    } else {
                        _ = detailStore.beginVisitReport(for: nearby, at: date)
                    }
                    _ = detailStore.submitReport(spot: nearby, experience: offset == 2 ? .notCooler : .aLittleCooler,
                        helpedFeatures: [.fans], stay: .under30, comment: "Example visit for layout review.",
                        visitedAt: date, at: date)
                }
            } else if scenario == "draft" {
                let date = now.addingTimeInterval(-2 * 86_400)
                _ = detailStore.beginVisitReport(for: detailStore.spot(spot.id)!, at: date)
                detailStore.saveReportDraft(.init(experience: .aLittleCooler, helpedFeatures: [.fans],
                    stay: .under30, comment: "Example saved draft for layout review.", visitedAt: date), for: spot.id)
                detailStore.simulateNearbySpot(nil)
            } else if scenario == "away" {
                detailStore.simulateNearbySpot(nil)
            }
            _store = StateObject(wrappedValue: detailStore)
            return
        }
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
                    .presentationDetents(screen == "detail-report" ? [.medium, .large] : [.large],
                                         selection: $detailDetent)
                    .presentationDragIndicator(screen == "detail-report" ? .visible : .automatic)
                    .environment(\.dynamicTypeSize, args.contains("--preview-large") ? .accessibility5 : .large)
                    .tint(AppStyle.brand)
            }
            .preferredColorScheme(args.contains("--preview-dark") ? .dark : .light)
            .environment(\.dynamicTypeSize, args.contains("--preview-large") ? .accessibility5 : .large)
            .tint(AppStyle.brand)
    }
    @ViewBuilder var content: some View {
        switch screen {
        case "detail-report":
            if let spot = store.spots.first { CoolSpotDetailView(store: store, spot: spot) }
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

#if DEBUG
// One real flow, one memory store, and a rendering switch: answers survive comparison.
private struct ContributionLayoutInspectionView: View {
    @StateObject private var store = PrototypeStore(reportDefaults: nil)
    @State private var presented = true
    @State private var proposal = true
    @State private var sessionID = UUID()
    var body: some View {
        VStack(spacing: 16) {
            Text("Update layout preview").font(.title2.bold())
            Text("Compare the same form in Current and Proposal.\nUses example data on this preview device.")
                .font(.body).multilineTextAlignment(.center).foregroundStyle(AppStyle.supportingText)
            Button("Open update form") {
                sessionID = UUID(); presented = true
            }.buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
        .sheet(isPresented: $presented) {
            VStack(spacing: 0) {
                Picker("Layout", selection: $proposal) {
                    Text("Current").tag(false)
                    Text("Proposal").tag(true)
                }
                .pickerStyle(.segmented).padding(.horizontal, 20).padding(.vertical, 12)
                .accessibilityHint("Switch layouts without clearing your answers")
                ContributionFlow(store: store, source: .existingCoolSpot(store.spots[0]))
                    .id(sessionID)
                    .environment(\.usesRefinedContributionLayout, proposal)
            }
            .presentationDetents([.large])
        }
        .tint(AppStyle.brand)
        .preferredColorScheme(.light)
        .environment(\.dynamicTypeSize, .large)
    }
}
#endif
