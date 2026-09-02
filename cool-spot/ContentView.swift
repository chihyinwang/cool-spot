import SwiftUI

struct ContentView: View {
    @StateObject private var store = PrototypeStore()
    @State private var selectedTab: Int
    @State private var showDetailPreview: Bool
    @State private var showContributionPreview: Bool

    init() {
        let arguments = ProcessInfo.processInfo.arguments
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

            YouView(store: store)
                .tabItem { Label("You", systemImage: "person.crop.circle") }
                .tag(2)
        }
        .tint(AppStyle.brand)
        .sheet(isPresented: $showDetailPreview) {
            if let spot = store.spot("library") {
                CoolSpotDetailView(store: store, spot: spot)
            }
        }
        .sheet(isPresented: $showContributionPreview) {
            ContributionFlow(store: store, source: .currentLocation)
        }
    }
}

#Preview {
    ContentView()
}
