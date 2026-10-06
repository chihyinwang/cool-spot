import MapKit
import SwiftUI

struct PlaceOwnReportsView: View {
    @ObservedObject var store: PrototypeStore
    let spot: CoolSpot

    var body: some View {
        List {
            Section {
                ForEach(store.ownReports(for: spot.id)) { report in
                    NavigationLink {
                        PublishedVisitReportView(store: store, report: report)
                    } label: {
                        VStack(alignment: .leading, spacing: LayoutSpacing.text) {
                            Label(report.experience.rawValue, systemImage: report.experience.symbol)
                                .font(.headline)
                            Text("Visited \(report.visitedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption).foregroundStyle(AppStyle.supportingText)
                        }.padding(.vertical, LayoutSpacing.text)
                    }
                }
            } header: {
                Text(spot.name).textCase(nil).font(.subheadline.weight(.semibold))
            }
        }
        .listStyle(.plain)
        .navigationTitle("Your report history").navigationBarTitleDisplayMode(.inline)
        .tint(AppStyle.actionForeground)
    }
}

// Extend the existing native teal/mint system. Read first, thank second.
// Individual reports never inherit facts or dates from aggregate totals.
// Recognition is a local demo, not cooling evidence or a ranking signal.
struct VisitorReportsView: View {
    @ObservedObject var store: PrototypeStore
    let spot: CoolSpot

    var body: some View {
        List {
            Section {
                if store.visitorReportItems(for: spot).isEmpty {
                    ContentUnavailableView("No visitor reports yet", systemImage: "text.bubble")
                } else {
                    ForEach(store.visitorReportItems(for: spot)) { item in
                        VStack(alignment: .leading, spacing: 12) {
                            VisitorReportContent(item: item)
                            if !item.isOwn { PopsicleThanksButton(store: store, reportID: item.id) }
                        }
                        .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.name).font(.subheadline.weight(.semibold))
                    Text("Newest visits first").font(.caption)
                }
                .textCase(nil).foregroundStyle(AppStyle.supportingText).padding(.vertical, 8)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Visitor reports").navigationBarTitleDisplayMode(.inline)
        .tint(AppStyle.actionForeground)
    }
}

// Real and example reports share one reading hierarchy. Missing fixture facts
// remain absent; presentation never supplies an answer or date on their behalf.
struct VisitorReportContent: View {
    let item: VisitorReportItem
    var showsProvenance = true
    var body: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.related) {
            if let report = item.report {
                Label(report.experience.summary, systemImage: report.experience.symbol)
                    .font(.headline).foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !item.comment.isEmpty {
                Text(item.comment).font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let report = item.report {
                if !report.helpedFeatures.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What helped").font(.subheadline.weight(.semibold))
                        ForEach(CoolingFeature.allCases.filter { report.helpedFeatures.contains($0) }) { feature in
                            Label { Text(feature.rawValue).fixedSize(horizontal: false, vertical: true) }
                                icon: { Image(systemName: feature.symbol) }
                                .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                        }
                    }
                }
                if let stay = report.stayLength {
                    Label { Text("Stayed \(stay.rawValue)").fixedSize(horizontal: false, vertical: true) }
                        icon: { Image(systemName: "clock") }
                        .font(.subheadline).foregroundStyle(AppStyle.supportingText)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                if showsProvenance { Text(item.sourceLabel).font(.caption.weight(.semibold)) }
                if let report = item.report {
                    Text("Visited \(report.visitedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                } else {
                    Text("Visit date unavailable").font(.caption)
                }
            }.foregroundStyle(AppStyle.supportingText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct PopsicleMark: View {
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 5).fill(AppStyle.informationAccent).frame(width: 16, height: 23)
                .overlay { Capsule().fill(AppStyle.mint).frame(width: 3, height: 12) }
            Capsule().fill(.secondary).frame(width: 4, height: 7)
        }.frame(width: 24, height: 32).accessibilityHidden(true)
    }
}

struct PopsicleThanksButton: View {
    @ObservedObject var store: PrototypeStore
    let reportID: String
    @State private var showExplanation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if store.hasSentPopsicle(to: reportID) {
                Label { Text("Popsicle sent · Demo") } icon: { PopsicleMark() }
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Button("Undo") { store.undoPopsicle(to: reportID) }.frame(minHeight: 44)
            } else {
                Button {
                    if store.hasSeenPopsicleExplanation { store.sendPopsicle(to: reportID) }
                    else { showExplanation = true }
                } label: {
                    Label { Text("Send a popsicle") } icon: { PopsicleMark() }
                        .frame(minHeight: 44)
                }
                .buttonStyle(.borderless)
            }
        }
        .alert("Send a little thank-you?", isPresented: $showExplanation) {
            Button("Cancel", role: .cancel) {}
            Button("Send a popsicle") { store.sendPopsicle(to: reportID) }
        } message: {
            Text("A free, virtual thank-you. This demo stays on your device.")
        }
    }
}

struct ReceivedPopsicleExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: LayoutSpacing.text) {
            Label { Text("Popsicle received · Example") } icon: { PopsicleMark() }
                .font(.headline).foregroundStyle(.primary)
            Text("A little thank-you for sharing this report.").font(.subheadline)
        }.padding(.vertical, 4)
    }
}

struct PresenceMapExample: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .body) private var mapHeight = 190
    @State private var count = 2
    @State private var paused = false
    @State private var elapsed = 0
    private var arrivalPhase: Int { elapsed == 6 ? 1 : elapsed == 7 ? 2 : 0 }
    private var runs: Bool { !reduceMotion && !paused && scenePhase == .active }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("One more person on the map").font(.headline)
            Map(initialPosition: .region(.init(
                center: CLLocationCoordinate2D(latitude: 51.504, longitude: -0.078),
                span: .init(latitudeDelta: 0.004, longitudeDelta: 0.005))),
                interactionModes: []) {
                Annotation("Example Cool Spot", coordinate: .init(latitude: 51.504, longitude: -0.078), anchor: .bottom) {
                    CoolSpotPin(type: .library, count: reduceMotion ? 3 : count,
                                arrivalPhase: reduceMotion ? 0 : arrivalPhase)
                }
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
            .frame(height: mapHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Example: two people before sharing, three after. Only the number is public, not your name.")
            Text("When you share, others see 2 → 3 people. They don’t see your name.")
            if !reduceMotion {
                Button(paused ? "Resume example" : "Pause example") { paused.toggle() }
                    .frame(minHeight: 44)
            }
        }
        .task(id: runs) {
            guard runs else { return }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
                guard !Task.isCancelled else { return }
                elapsed = (elapsed + 1) % 17
                let next = elapsed < 6 ? 2 : 3
                if next != count { withAnimation(.easeOut(duration: 0.25)) { count = next } }
            }
        }
    }
}
