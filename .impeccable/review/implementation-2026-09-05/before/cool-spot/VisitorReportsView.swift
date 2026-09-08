import SwiftUI

// Extend the existing native teal/mint system. Read first, thank second.
// Individual reports never inherit facts or dates from aggregate totals.
// Recognition is a local demo, not cooling evidence or a ranking signal.
struct VisitorReportsView: View {
    @ObservedObject var store: PrototypeStore
    let spot: CoolSpot

    var body: some View {
        List {
            Section {
                Text(spot.name).font(.headline)
            }
            if store.visitorReportItems(for: spot).isEmpty {
                ContentUnavailableView("No individual reports to read yet", systemImage: "text.bubble")
            } else {
                Section {
                    ForEach(store.visitorReportItems(for: spot)) { item in
                        VStack(alignment: .leading, spacing: 12) {
                            if let report = item.report {
                                Text("Your report").font(.subheadline.weight(.semibold))
                                Text(report.experience.summary).font(.headline)
                                Text("Visit: \(report.visitedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption).foregroundStyle(.secondary)
                                if !report.helpedFeatures.isEmpty {
                                    Text("What helped: \(CoolingFeature.allCases.filter { report.helpedFeatures.contains($0) }.map(\.rawValue).joined(separator: ", "))")
                                        .font(.subheadline)
                                }
                                if let stay = report.stayLength {
                                    Text("Time here: \(stay.rawValue)").font(.subheadline)
                                }
                            } else {
                                Text("Example visitor report").font(.subheadline.weight(.semibold))
                                Text("Visit date and response details unavailable")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            if !item.comment.isEmpty { Text(item.comment).font(.body) }
                            if !item.isOwn { PopsicleThanksButton(store: store, reportID: item.id) }
                        }.padding(.vertical, 8)
                    }
                } footer: {
                    Text("All available reports are shown. Individual details are missing for some prototype totals.")
                }
            }
        }
        .navigationTitle("Visitor reports").navigationBarTitleDisplayMode(.inline)
        .tint(AppStyle.brand)
    }
}

struct PopsicleMark: View {
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 5).fill(AppStyle.brand).frame(width: 16, height: 23)
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
                    .font(.subheadline.weight(.semibold)).foregroundStyle(AppStyle.brand)
                Button("Undo") { store.undoPopsicle(to: reportID) }.frame(minHeight: 44)
                Text("Saved on this device only. No one has been notified.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Button {
                    if store.hasSeenPopsicleExplanation { store.sendPopsicle(to: reportID) }
                    else { showExplanation = true }
                } label: {
                    Label { Text("Send a popsicle") } icon: { PopsicleMark() }
                        .frame(minHeight: 44)
                }
                .buttonStyle(.borderless)
                Text("A little thank-you for this report · Demo")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .alert("Send a little thank-you?", isPresented: $showExplanation) {
            Button("Cancel", role: .cancel) {}
            Button("Send a popsicle") { store.sendPopsicle(to: reportID) }
        } message: {
            Text("A popsicle is a free, virtual thank-you—not a rating of how cool this place is. You can undo it. In this prototype, it stays on your device and isn’t delivered to anyone.")
        }
    }
}

struct ReceivedPopsicleExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label { Text("You received a popsicle!") } icon: { PopsicleMark() }
                .font(.headline).foregroundStyle(AppStyle.brand)
            Text("A little thank-you for sharing this report.").font(.subheadline)
            Text("Example only — no real person sent this.").font(.caption).foregroundStyle(.secondary)
        }.padding(.vertical, 4)
    }
}

struct PresenceMapExample: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .subheadline) private var mapHeight = 190
    @State private var shared = false
    @State private var replay = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("One more person on the map").font(.headline)
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(AppStyle.mint)
                // A schematic, not a map of the user's actual location.
                HStack { Spacer(); Rectangle().fill(.background).frame(width: 18); Spacer() }
                VStack { Spacer(); Rectangle().fill(.background).frame(height: 18); Spacer() }
                VStack(spacing: 5) {
                    Label("\(shared ? 3 : 2)", systemImage: "person.2.fill")
                        .font(.title2.bold().monospacedDigit())
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .foregroundStyle(.white).background(AppStyle.ink, in: Capsule())
                        .contentTransition(.numericText())
                    Image(systemName: "mappin").font(.title2).foregroundStyle(AppStyle.brand)
                    Text("Example Cool Spot").font(.subheadline.weight(.semibold))
                        .padding(6).background(.background, in: RoundedRectangle(cornerRadius: 6))
                }
            }
            .frame(height: mapHeight).clipShape(RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(shared ? "Example: three people after you share, up from two" : "Example: two people before you share")
            Text("When you share, others see 2 → 3 people. They don’t see your name.")
                .font(.subheadline)
            Button("Replay example") { replay += 1 }
                .frame(minHeight: 44)
            Text("Illustration only. This does not share your location or change the real count.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .task(id: replay) {
            if reduceMotion { shared = true; return }
            shared = false
            do { try await Task.sleep(for: .milliseconds(900)) } catch { return }
            withAnimation(.easeOut(duration: 0.8)) { shared = true }
        }
    }
}
