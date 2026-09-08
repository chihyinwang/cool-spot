import XCTest
import SwiftUI
@testable import cool_spot

@MainActor
final class CoolSpotTests: XCTestCase {
    func testPopsicleIsUniqueUndoableAndNeverChangesCoolingEvidence() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let example = try XCTUnwrap(store.visitorReportItems(for: spot).first)
        let evidence = store.coolingEvidence(for: spot)
        let people = store.presence(for: spot)
        XCTAssertTrue(store.sendPopsicle(to: example.id))
        XCTAssertFalse(store.sendPopsicle(to: example.id))
        XCTAssertFalse(store.sendPopsicle(to: "nonexistent"))
        XCTAssertTrue(store.hasSeenPopsicleExplanation)
        XCTAssertEqual(store.coolingEvidence(for: spot), evidence)
        XCTAssertEqual(store.presence(for: spot), people)
        store.undoPopsicle(to: example.id)
        XCTAssertFalse(store.hasSentPopsicle(to: example.id))
    }

    func testPopsiclesPersistAndOwnReportsCannotThankThemselves() throws {
        let suite = "Popsicles.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PrototypeStore(reportDefaults: defaults)
        let spot = try XCTUnwrap(store.spot("library"))
        let example = try XCTUnwrap(store.visitorReportItems(for: spot).first)
        XCTAssertTrue(store.sendPopsicle(to: example.id))
        XCTAssertTrue(store.submitReport(spot: spot, experience: .notCooler,
                                         helpedFeatures: [], stay: nil, comment: ""))
        let own = try XCTUnwrap(store.visitReports.first)
        XCTAssertFalse(store.sendPopsicle(to: own.id.uuidString))
        store.simulateReceivedPopsicle(for: own.id)
        let restored = PrototypeStore(reportDefaults: defaults)
        XCTAssertTrue(restored.hasSentPopsicle(to: example.id))
        XCTAssertTrue(restored.hasReceivedExamplePopsicle(for: own.id))
        XCTAssertTrue(restored.hasSeenPopsicleExplanation)
        XCTAssertEqual(restored.visitorReportItems(for: spot).count, spot.comments.count + 1)
    }

    func testCompleteExamplesHaveExplicitProvenanceAndStableMetadata() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let items = store.visitorReportItems(for: spot)
        XCTAssertEqual(items.map(\.comment), spot.comments)
        XCTAssertTrue(items.allSatisfy { $0.report != nil && $0.isExample && !$0.isOwn })
        XCTAssertEqual(items.first?.report?.visitedAt, ISO8601DateFormatter().date(from: "2026-09-05T14:00:00Z"))
        XCTAssertNotEqual(items.first?.report?.visitedAt, spot.latestReportAt)
    }

    func testLatestReportDoesNotPrioritizeItsAuthor() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let example = try XCTUnwrap(store.visitorReportItems(for: spot).first)
        let date = try XCTUnwrap(example.report?.visitedAt)
        func personal(at date: Date) -> VisitReport {
            .init(id: UUID(), spotID: spot.id, experience: .notCooler, helpedFeatures: [],
                  stayLength: nil, comment: "My visit", visitedAt: date, confirmationAt: date, submittedAt: date)
        }
        store.visitReports = [personal(at: date.addingTimeInterval(-3600))]
        XCTAssertTrue(try XCTUnwrap(store.visitorReportItems(for: spot).first).isExample)
        store.visitReports.append(personal(at: date.addingTimeInterval(3600)))
        XCTAssertTrue(try XCTUnwrap(store.visitorReportItems(for: spot).first).isOwn)
        XCTAssertEqual(store.visitorReportItems(for: spot).compactMap { $0.report?.visitedAt },
                       [date.addingTimeInterval(3600), date, date.addingTimeInterval(-3600)])
    }

    func testUnknownDateNeverWinsNewestPreview() throws {
        let dated = try XCTUnwrap(Fixtures.visitorReports.first)
        let undated = VisitorReportItem(id: "unknown", comment: "Undated", report: nil, provenance: .visitor)
        XCTAssertEqual(VisitorReportItem.newestFirst([undated, dated]).first?.id, dated.id)
        XCTAssertFalse(undated.isOwn)
    }

    func testAppearanceMapsToSystemLightAndDark() {
        XCTAssertNil(AppAppearance.system.colorScheme)
        XCTAssertEqual(AppAppearance.light.colorScheme, .light)
        XCTAssertEqual(AppAppearance.dark.colorScheme, .dark)
        XCTAssertEqual(AppAppearance.allCases.map(\.title), ["Match System", "Light", "Dark"])
    }

    func testAppearanceDefaultsToLightAndPersistsSelection() throws {
        let suiteName = "CoolSpotAppearanceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preference = AppStorage(wrappedValue: AppAppearance.light,
                                    AppAppearance.storageKey, store: defaults)
        XCTAssertEqual(preference.wrappedValue, .light)

        preference.wrappedValue = .dark
        let restored = AppStorage(wrappedValue: AppAppearance.light,
                                  AppAppearance.storageKey, store: defaults)
        XCTAssertEqual(restored.wrappedValue, .dark)

        preference.wrappedValue = .light
        XCTAssertEqual(defaults.string(forKey: AppAppearance.storageKey), "light")
        preference.wrappedValue = .system
        XCTAssertEqual(defaults.string(forKey: AppAppearance.storageKey), "system")
    }

    func testPresenceOnlyStartsForNearbySpot() throws {
        let store = PrototypeStore()
        let nearby = try XCTUnwrap(store.spot("library"))
        let away = try XCTUnwrap(store.spot("shade"))

        store.checkIn(away)
        XCTAssertNil(store.activePresenceSpotID)

        store.checkIn(nearby)
        XCTAssertEqual(store.activePresenceSpotID, nearby.id)
        XCTAssertEqual(store.presence(for: nearby), nearby.presenceCount + 1)
    }

    func testLeadingExperienceUsesThreeLevelReports() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))

        XCTAssertEqual(store.leadingExperience(for: spot), .muchCooler)
        XCTAssertEqual(store.experienceReportTotal(for: spot), 8)
    }

    func testSubmittingExperienceUpdatesTheMatchingBucket() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let before = store.experienceCounts(for: spot)[.notCooler, default: 0]

        store.submitReport(spot: spot, experience: .notCooler,
                           helpedFeatures: [.drinkingWater], stay: nil, comment: "")

        XCTAssertEqual(store.experienceCounts(for: spot)[.notCooler, default: 0], before + 1)
        XCTAssertEqual(store.visitReports.first?.helpedFeatures, [.drinkingWater])
    }

    func testIndependentReportDoesNotStartPresenceOrPublishUntilSubmitted() throws {
        let store = PrototypeStore()
        var spot = try XCTUnwrap(store.spot("library"))
        let startedAt = Date(timeIntervalSince1970: 1_000_000)

        XCTAssertTrue(store.beginVisitReport(for: spot, at: startedAt))
        XCTAssertNil(store.activePresenceSpotID)
        XCTAssertEqual(store.presence(for: spot), spot.presenceCount)
        XCTAssertTrue(store.visitReports.isEmpty)

        // A report started nearby can be finished after leaving, without sharing presence.
        spot.isNearby = false
        XCTAssertTrue(store.submitReport(spot: spot, experience: .notCooler,
                                        helpedFeatures: [], stay: nil, comment: "",
                                        at: startedAt.addingTimeInterval(23 * 60 * 60)))
        XCTAssertNil(store.activePresenceSpotID)
        XCTAssertEqual(store.presence(for: spot), spot.presenceCount)
        XCTAssertEqual(store.visitReports.count, 1)
        XCTAssertEqual(store.visitConfirmedAt[spot.id], startedAt)
    }

    func testRemoteReportRequiresConfirmationForThatPlace() throws {
        let store = PrototypeStore()
        let nearby = try XCTUnwrap(store.spot("library"))
        let away = try XCTUnwrap(store.spot("shade"))
        store.checkIn(nearby)
        let contributionCount = store.contributions.count

        XCTAssertFalse(store.beginVisitReport(for: away))
        XCTAssertFalse(store.submitReport(spot: away, experience: .muchCooler,
                                         helpedFeatures: [], stay: nil, comment: ""))
        XCTAssertTrue(store.visitReports.isEmpty)
        XCTAssertEqual(store.contributions.count, contributionCount)
        XCTAssertEqual(store.activePresenceSpotID, nearby.id)
    }

    func testConfirmedVisitCanBeStartedAfterSevenDaysAway() throws {
        let suite = "NoVisitDeadline.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PrototypeStore(reportDefaults: defaults)
        let start = Date.now.addingTimeInterval(-7 * 86_400)
        let spot = try XCTUnwrap(store.spot("library"))
        store.checkIn(spot, at: start)
        store.activePresenceSpotID = nil
        store.simulateNearbySpot(nil)
        let restored = PrototypeStore(reportDefaults: defaults)
        let away = try XCTUnwrap(restored.spot(spot.id))
        XCTAssertTrue(restored.canReportVisit(for: away))
        XCTAssertEqual(restored.visitsWithoutReports().map(\.id), [spot.id])
        XCTAssertTrue(restored.beginVisitReport(for: away))
        XCTAssertEqual(restored.reportDrafts[spot.id]?.visitedAt, start)
        XCTAssertTrue(restored.submitReport(spot: away, experience: .muchCooler,
                                            helpedFeatures: [], stay: nil, comment: "A week later"))
        XCTAssertEqual(restored.visitReports.first?.visitedAt, start)
        XCTAssertFalse(restored.canReportVisit(for: away))
    }

    func testSavingDoesNotGrantReportEligibility() throws {
        let store = PrototypeStore()
        let away = try XCTUnwrap(store.spot("shade"))
        _ = store.toggleSaved(away)
        _ = store.saveCurrentLocation()

        XCTAssertFalse(store.canReportVisit(for: away))
        XCTAssertTrue(store.visitConfirmedAt.isEmpty)
    }

    func testPluralityUsesExactCountInsteadOfClaimingAMajority() {
        let evidence = CoolingEvidence(counts: [.notCooler: 5, .aLittleCooler: 6, .muchCooler: 3])
        XCTAssertEqual(evidence.total, 14)
        XCTAssertEqual(evidence.leadingExperience, .aLittleCooler)
        XCTAssertEqual(evidence.attribution, "6 of 14 reports said")
    }

    func testTiesNeverSelectAnArbitraryExperience() {
        for counts: [CoolingExperience: Int] in [
            [.notCooler: 2, .aLittleCooler: 2, .muchCooler: 2],
            [.notCooler: 0, .aLittleCooler: 3, .muchCooler: 3]
        ] {
            let evidence = CoolingEvidence(counts: counts)
            XCTAssertNil(evidence.leadingExperience)
            XCTAssertEqual(evidence.headline, "Visitors had different experiences")
            XCTAssertEqual(evidence.attribution, "6 visitor reports")
        }
    }

    func testEmptyEvidenceDoesNotClaimAnyCoolingExperience() {
        for counts: [CoolingExperience: Int] in [[:], [.notCooler: 0, .aLittleCooler: 0, .muchCooler: 0]] {
            let evidence = CoolingEvidence(counts: counts)
            XCTAssertEqual(evidence.total, 0)
            XCTAssertNil(evidence.leadingExperience)
            XCTAssertEqual(evidence.headline, "No visitor reports yet")
        }
    }

    func testOneReportShowsAnExactSampleNotGeneralConsensus() {
        let evidence = CoolingEvidence(counts: [.notCooler: 1])
        XCTAssertEqual(evidence.attribution, "1 visitor reported")
        XCTAssertEqual(evidence.headline, "Not cooler than outside")
    }

    func testNewReportUpdatesLatestForOnlyItsPlace() throws {
        let store = PrototypeStore()
        let library = try XCTUnwrap(store.spot("library"))
        let park = try XCTUnwrap(store.spot("shade"))
        let submittedAt = Date.now
        XCTAssertEqual(store.latestReportDate(for: library), library.latestReportAt)
        XCTAssertTrue(store.submitReport(spot: library, experience: .notCooler,
                                        helpedFeatures: [], stay: nil, comment: "", at: submittedAt))
        XCTAssertEqual(store.visitReports.first?.submittedAt, submittedAt)
        XCTAssertEqual(store.latestReportDate(for: library), submittedAt)
        XCTAssertEqual(store.latestReportDate(for: park), park.latestReportAt)
        XCTAssertEqual(store.coolingEvidence(for: library).total, 9)
        XCTAssertEqual(store.presence(for: library), library.presenceCount)
    }

    func testFinishLaterRestoresAllAnswersAfterLeavingAndRelaunching() throws {
        let suiteName = "ReportJourneyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PrototypeStore(reportDefaults: defaults)
        let spot = try XCTUnwrap(store.spot("library"))
        let startedAt = Date.now.addingTimeInterval(-3_600)
        XCTAssertTrue(store.beginVisitReport(for: spot, at: startedAt))
        let answers = VisitReportDraft(experience: .notCooler, helpedFeatures: [.drinkingWater],
                                       stay: .under30, comment: "Water helped, but the room was warm.",
                                       visitedAt: startedAt.addingTimeInterval(-300))
        store.saveReportDraft(answers, for: spot.id)
        _ = store.toggleSaved(spot)
        store.simulateNearbySpot(nil)

        let restored = PrototypeStore(reportDefaults: defaults)
        let awaySpot = try XCTUnwrap(restored.spot(spot.id))
        XCTAssertFalse(awaySpot.isNearby)
        XCTAssertTrue(restored.isSaved(spotID: spot.id))
        XCTAssertEqual(restored.reportDrafts[spot.id], answers)
        XCTAssertTrue(restored.visitsToShare.contains { $0.id == spot.id })
        XCTAssertNil(restored.activePresenceSpotID)
        XCTAssertTrue(restored.beginVisitReport(for: awaySpot))
        XCTAssertEqual(restored.visitConfirmedAt[spot.id], startedAt)
        XCTAssertTrue(restored.submitReport(spot: awaySpot, experience: .notCooler,
                                            helpedFeatures: answers.helpedFeatures, stay: answers.stay,
                                            comment: answers.comment, visitedAt: answers.visitedAt))
        XCTAssertNil(restored.reportDrafts[spot.id])
        XCTAssertTrue(restored.visitsToShare.isEmpty)

        let relaunchedAfterPublishing = PrototypeStore(reportDefaults: defaults)
        XCTAssertEqual(relaunchedAfterPublishing.visitReports.count, 1)
        XCTAssertEqual(relaunchedAfterPublishing.visitReports.first?.visitedAt, answers.visitedAt)
        XCTAssertFalse(relaunchedAfterPublishing.canReportVisit(for: awaySpot))
        XCTAssertNil(relaunchedAfterPublishing.activePresenceSpotID)
        XCTAssertFalse(try XCTUnwrap(PrototypeStore(reportDefaults: defaults).spot(spot.id)).isNearby)
    }

    func testRepeatedOpeningAndPresenceDoNotMoveTheDeadlineOrEraseAnswers() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let start = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertTrue(store.beginVisitReport(for: spot, at: start))
        let answers = VisitReportDraft(experience: .aLittleCooler, visitedAt: start)
        store.saveReportDraft(answers, for: spot.id)
        store.checkIn(spot, at: start.addingTimeInterval(600))
        XCTAssertTrue(store.beginVisitReport(for: spot, at: start.addingTimeInterval(1_200)))
        XCTAssertEqual(store.visitConfirmedAt[spot.id], start)
        XCTAssertEqual(store.reportDrafts[spot.id], answers)
        XCTAssertTrue(store.hasCurrentConfirmation(for: spot, at: start.addingTimeInterval(7 * 86_400)))
    }

    func testOldDraftCanResumeAndPublishAfterLeavingAndRelaunch() throws {
        let suiteName = "ExpiredJourneyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PrototypeStore(reportDefaults: defaults)
        let spot = try XCTUnwrap(store.spot("library"))
        let start = Date.now.addingTimeInterval(-7 * 86_400)
        XCTAssertTrue(store.beginVisitReport(for: spot, at: start))
        store.saveReportDraft(.init(experience: .notCooler, comment: "Keep my answer", visitedAt: start), for: spot.id)
        store.simulateNearbySpot(nil)
        let restored = PrototypeStore(reportDefaults: defaults)
        let away = try XCTUnwrap(restored.spot(spot.id))
        XCTAssertTrue(restored.canReportVisit(for: away))
        XCTAssertEqual(restored.reportDrafts[spot.id]?.comment, "Keep my answer")
        XCTAssertTrue(restored.visitReports.isEmpty)
        XCTAssertTrue(restored.beginVisitReport(for: away))
        XCTAssertEqual(restored.reportDrafts[spot.id]?.visitedAt, start)
        XCTAssertTrue(restored.submitReport(spot: away, experience: .notCooler,
                                            helpedFeatures: [], stay: nil, comment: "Keep my answer"))
        XCTAssertEqual(restored.visitReports.first?.visitedAt, start)
        XCTAssertFalse(restored.submitReport(spot: away, experience: .muchCooler,
                                             helpedFeatures: [], stay: nil, comment: ""))
        XCTAssertTrue(restored.unfinishedReportSpots.isEmpty)
        XCTAssertTrue(PrototypeStore(reportDefaults: defaults).visitsToShare.isEmpty)
    }

    func testSavingAndBrowsingNeverCreateReportEligibilityAcrossRelaunch() throws {
        let suiteName = "PrivateSaveTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PrototypeStore(reportDefaults: defaults)
        let spot = try XCTUnwrap(store.spot("library"))
        _ = store.toggleSaved(spot)
        let coordinate = store.saveCurrentLocation()
        store.simulateNearbySpot(nil)
        let restored = PrototypeStore(reportDefaults: defaults)
        XCTAssertTrue(restored.savedLocations.contains { $0.id == coordinate.id })
        XCTAssertTrue(restored.visitConfirmedAt.isEmpty)
        XCTAssertFalse(restored.canReportVisit(for: try XCTUnwrap(restored.spot(spot.id))))
    }

    func testLateSubmissionUsesVisitTimeAndDuplicateDoesNotChangeEvidence() throws {
        let store = PrototypeStore()
        var spot = try XCTUnwrap(store.spot("library"))
        let visitTime = Date.now.addingTimeInterval(-1_800)
        XCTAssertTrue(store.beginVisitReport(for: spot, at: visitTime))
        spot.isNearby = false
        let now = Date.now
        XCTAssertTrue(store.submitReport(spot: spot, experience: .notCooler,
                                         helpedFeatures: [], stay: nil, comment: "", at: now))
        XCTAssertEqual(store.latestReportDate(for: spot), visitTime)
        XCTAssertEqual(store.visitReports.first?.submittedAt, now)
        XCTAssertFalse(store.submitReport(spot: spot, experience: .muchCooler,
                                          helpedFeatures: [], stay: nil, comment: "", at: now))
        XCTAssertEqual(store.visitReports.count, 1)
        XCTAssertEqual(store.experienceReportTotal(for: spot), 9)
    }

    func testCannotPublishFutureVisitTimeOrSilentlyChangeAnotherPlacesDraft() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let now = Date.now
        XCTAssertTrue(store.beginVisitReport(for: spot, at: now))
        XCTAssertFalse(store.submitReport(spot: spot, experience: .muchCooler,
                                          helpedFeatures: [], stay: nil, comment: "",
                                          visitedAt: now.addingTimeInterval(60), at: now))
        store.saveReportDraft(.init(experience: .muchCooler, visitedAt: now), for: "museum")
        XCTAssertNil(store.reportDrafts["museum"])
        XCTAssertTrue(store.visitReports.isEmpty)
    }

    func testPresenceExpiresAfterTenMinutesWithoutRemovingReportEligibility() throws {
        let store = PrototypeStore()
        var spot = try XCTUnwrap(store.spot("library"))
        let start = Date.now
        store.checkIn(spot, at: start)
        XCTAssertEqual(store.presence(for: spot, at: start.addingTimeInterval(599)), spot.presenceCount + 1)
        store.endExpiredPresence(at: start.addingTimeInterval(600))
        XCTAssertEqual(store.presence(for: spot, at: start.addingTimeInterval(600)), spot.presenceCount)
        XCTAssertNil(store.activePresenceSpotID)
        spot.isNearby = false
        XCTAssertTrue(store.canReportVisit(for: spot, at: start.addingTimeInterval(601)))
    }

    func testReturningNearbyNeverReplacesAnUnfinishedReportsOriginalVisit() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let oldVisit = Date.now.addingTimeInterval(-90_000)
        XCTAssertTrue(store.beginVisitReport(for: spot, at: oldVisit))
        store.saveReportDraft(.init(experience: .notCooler, visitedAt: oldVisit), for: spot.id)
        let newVisit = Date.now
        store.checkIn(spot, at: newVisit)
        XCTAssertTrue(store.beginVisitReport(for: spot, at: newVisit))
        XCTAssertEqual(store.visitConfirmedAt[spot.id], oldVisit)
        XCTAssertEqual(store.reportDrafts[spot.id]?.experience, .notCooler)
        XCTAssertEqual(store.reportDrafts[spot.id]?.visitedAt, oldVisit)
        XCTAssertTrue(store.submitReport(spot: spot, experience: .notCooler,
                                         helpedFeatures: [], stay: nil, comment: "", visitedAt: oldVisit))
        XCTAssertEqual(store.visitReports.first?.visitedAt, oldVisit)
    }

    func testThreeUnfinishedReportsAreSeparateFromPresenceSavingAndPublishedReports() throws {
        let store = PrototypeStore()
        let now = Date.now
        for (index, fixture) in store.spots.enumerated() {
            var spot = fixture
            spot.isNearby = true
            XCTAssertTrue(store.beginVisitReport(for: spot, at: now.addingTimeInterval(Double(-index) * 86_400)))
        }
        store.simulateNearbySpot(nil)
        XCTAssertEqual(store.unfinishedReportSpots.count, 3)
        XCTAssertTrue(store.visitsWithoutReports().isEmpty)
        let chosen = try XCTUnwrap(store.spot("museum"))
        XCTAssertTrue(store.submitReport(spot: chosen, experience: .aLittleCooler,
                                         helpedFeatures: [], stay: nil, comment: ""))
        XCTAssertEqual(store.unfinishedReportSpots.count, 2)
        XCTAssertFalse(store.unfinishedReportSpots.contains { $0.id == chosen.id })
        XCTAssertEqual(store.visitReports.map(\.spotID), [chosen.id])
        XCTAssertFalse(store.isSaved(spotID: chosen.id))
    }

    func testPresenceWithoutAnswersDoesNotCountAsAnUnfinishedReport() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        store.checkIn(spot)
        XCTAssertTrue(store.unfinishedReportSpots.isEmpty)
        XCTAssertEqual(store.visitsWithoutReports().map(\.id), [spot.id])
        XCTAssertTrue(store.beginVisitReport(for: spot))
        XCTAssertEqual(store.unfinishedReportSpots.map(\.id), [spot.id])
        XCTAssertTrue(store.visitsWithoutReports().isEmpty)
        store.discardReportAnswers(spot.id)
        XCTAssertTrue(store.unfinishedReportSpots.isEmpty)
        XCTAssertTrue(store.visitReports.isEmpty)
    }

    func testRelaunchKeepsPresenceDeadlineAndStopSharingStaysStopped() throws {
        let suiteName = "PresenceJourneyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PrototypeStore(reportDefaults: defaults)
        let spot = try XCTUnwrap(store.spot("library"))
        let start = Date.now
        store.checkIn(spot, at: start)
        let restored = PrototypeStore(reportDefaults: defaults)
        XCTAssertEqual(restored.presenceEndsAt, start.addingTimeInterval(600))
        XCTAssertEqual(restored.presence(for: spot), spot.presenceCount + 1)
        restored.activePresenceSpotID = nil
        let stopped = PrototypeStore(reportDefaults: defaults)
        XCTAssertNil(stopped.activePresenceSpotID)
        XCTAssertTrue(stopped.hasCurrentConfirmation(for: spot))
    }
}

@MainActor
final class ApprovedContributionTests: XCTestCase {
    func testSavedAnchorIsIndependentOfCurrentLocationAndPrivateText() {
        let saved = SavedLocation(id: UUID(), title: "Private name", subtitle: "", savedAt: .now,
                                  latitude: 51.6, longitude: -0.2, kind: .coordinate, note: "Private note")
        let source = ContributionSource.savedCoordinate(saved)
        let anchor = source.anchor(current: .init(latitude: 50, longitude: 0))
        XCTAssertEqual(anchor.latitude, 51.6); XCTAssertEqual(anchor.longitude, -0.2)
        let draft = PlaceContributionDraft(kind: .exact, anchor: anchor)
        XCTAssertTrue(draft.values.name.isEmpty); XCTAssertTrue(draft.values.note.isEmpty)
        XCTAssertNil(draft.values.type); XCTAssertEqual(draft.values.setting, .outdoors)
    }
    func testRecognisedPlaceNeedsUnknownSettingButNoOptionalAnswers() throws {
        let place = try XCTUnwrap(Fixtures.places.first)
        var draft = PlaceContributionDraft(kind: .recognised, anchor: place.coordinate, place: place)
        XCTAssertNil(draft.values.setting)
        draft.values.features = [.drinkingWater]
        XCTAssertFalse(draft.canSend)
        draft.values.setting = .both
        XCTAssertTrue(draft.canSend)
        XCTAssertNil(draft.values.photo)
        XCTAssertEqual(draft.values.laptop, .unknown)
    }
    func testUnknownTypeCanBeLeftUnansweredRatherThanGuessed() throws {
        var place = try XCTUnwrap(Fixtures.places.first)
        place.hasTrustedType = false
        var draft = PlaceContributionDraft(kind: .recognised, anchor: place.coordinate, place: place)
        draft.values.setting = .indoors; draft.values.features = [.airConditioning]
        XCTAssertTrue(draft.canSend); XCTAssertNil(draft.values.type)
        draft.values.type = .food
        XCTAssertTrue(draft.canSend)
    }
    private func placePhoto() -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).pngData { context in
            UIColor.green.setFill(); context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }

    func testUnlistedPlacesAlwaysNeedBothNameAndPhotoWithOptionalType() {
        for kind in [PlaceContributionKind.unlisted, .missing, .exact] {
            for setting in PlaceEnvironment.allCases {
                var draft = PlaceContributionDraft(kind: kind, anchor: .init(latitude: 51.6, longitude: -0.2))
                draft.values.locationConfirmed = true
                draft.values.setting = setting
                draft.values.features = [.treeShade]
                draft.values.name = "Shade beside the playground"
                XCTAssertFalse(draft.canSend, "A name must not waive the photo requirement")
                XCTAssertEqual(draft.validationIssues.map(\.field), [.photo])
                draft.values.photo = Data([1, 2, 3])
                XCTAssertFalse(draft.canSend)
                draft.values.photo = placePhoto()
                XCTAssertTrue(draft.canSend)
                XCTAssertNil(draft.values.type, "Place type is still optional")
                for blank in ["", " \n "] {
                    draft.values.name = blank
                    XCTAssertFalse(draft.canSend, "A photo must not substitute for a descriptive name")
                    XCTAssertEqual(draft.validationIssues.map(\.field), [.name])
                }
                draft.values.name = "Shade beside the playground"
                for answer in PlaceEntryEligibility.allCases {
                    draft.values.entryEligibility = answer
                    XCTAssertTrue(draft.canSend, "All entry eligibility answers permit review")
                }
            }
        }
    }

    func testValidationReportsAllMissingAnswersAndRecoversWithoutLosingOtherAnswers() {
        var draft = PlaceContributionDraft(kind: .unlisted, anchor: .init(latitude: 51.6, longitude: -0.2))
        draft.values.locationConfirmed = true
        draft.values.locationDetails = "By the east gate"
        draft.values.tables = .yes
        XCTAssertEqual(draft.validationIssues.map(\.field), [.setting, .name, .features, .photo])
        draft.values.setting = .outdoors
        draft.values.name = "Shade by the east gate"
        draft.values.features = [.treeShade]
        draft.values.photo = placePhoto()
        XCTAssertTrue(draft.validationIssues.isEmpty)
        XCTAssertTrue(draft.canSend)
        XCTAssertEqual(draft.values.locationDetails, "By the east gate")
        XCTAssertEqual(draft.values.tables, .yes)
        draft.values.photo = nil
        XCTAssertEqual(draft.validationIssues.map(\.field), [.photo])
        XCTAssertFalse(draft.canSend)
    }

    func testStoreRejectsIncompleteIdentificationAndAcceptsCompleteUnlistedProposalOnce() {
        let store = PrototypeStore()
        var draft = PlaceContributionDraft(kind: .unlisted, anchor: .init(latitude: 51.6, longitude: -0.2))
        draft.values.locationConfirmed = true
        draft.values.setting = .outdoors
        draft.values.features = [.treeShade]
        draft.values.name = "Shade beside the playground"
        let initialCount = store.contributions.count
        XCTAssertFalse(store.submitPlaceContribution(draft))
        draft.values.photo = placePhoto()
        draft.values.name = " "
        XCTAssertFalse(store.submitPlaceContribution(draft))
        XCTAssertEqual(store.contributions.count, initialCount)
        draft.values.name = "Shade beside the playground"
        XCTAssertTrue(store.submitPlaceContribution(draft))
        XCTAssertEqual(store.contributions.first?.placeDraft?.values, draft.values)
        XCTAssertFalse(store.submitPlaceContribution(draft))
        XCTAssertEqual(store.contributions.count, initialCount + 1)
    }

    func testUpdateOnlyNeedsARealChangeAndCanRevertToNoChanges() throws {
        let spot = try XCTUnwrap(Fixtures.spots.first)
        var draft = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        XCTAssertFalse(draft.canSend)
        draft.values.tables = .yes
        XCTAssertTrue(draft.canSend)
        XCTAssertEqual(draft.values.features, Set(spot.features))
        XCTAssertEqual(draft.values.laptop, .unknown)
        draft.values.tables = .unknown
        XCTAssertFalse(draft.canSend)
        draft.values.features = []
        XCTAssertFalse(draft.canSend)
        draft.values.removalReason = "The shaded structure was removed."
        XCTAssertTrue(draft.canSend)
    }
    func testUpdateRejectsBlankChangesBookkeepingAndInvalidChangedFields() throws {
        let spot = try XCTUnwrap(Fixtures.spots.first)
        let baseline = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        var draft = baseline
        draft.values.note = " "; draft.values.accessibility = "\n"; draft.values.stayLimit = "  "
        draft.values.sourceCorrection = " "; draft.values.removalReason = "Reason alone"
        XCTAssertTrue(draft.changes.isEmpty)
        XCTAssertFalse(draft.canSend)
        draft = baseline; draft.values.setting = nil
        XCTAssertFalse(draft.canSend)
        draft = baseline; draft.values.type = nil
        XCTAssertFalse(draft.canSend)
        draft = baseline; draft.values.photo = Data([1, 2, 3])
        XCTAssertFalse(draft.canSend)
        draft = baseline; draft.values.note = " A useful correction "
        XCTAssertTrue(draft.canSend)
        XCTAssertEqual(draft.changes, ["Note: A useful correction"])
    }
    func testDuplicateRebasesOnlyProposedFieldsAndPreservesExplicitType() throws {
        let spot = try XCTUnwrap(Fixtures.spots.first)
        var draft = PlaceContributionDraft(kind: .missing, anchor: spot.coordinate)
        draft.values.name = spot.name; draft.values.locationConfirmed = true
        draft.values.setting = .both; draft.values.type = .square
        draft.values.features = [.drinkingWater]; draft.values.note = " Check entry "
        let update = draft.reconciled(with: spot)
        XCTAssertEqual(update.values.access, spot.access)
        XCTAssertEqual(update.values.seating, spot.seating)
        XCTAssertEqual(update.values.type, .square)
        XCTAssertEqual(update.values.note, "Check entry")
        XCTAssertEqual(update.original.type, spot.type)
        XCTAssertTrue(update.changes.contains { $0.hasPrefix("Type:") })
        XCTAssertFalse(update.changes.contains { $0.hasPrefix("Cost to use:") || $0.hasPrefix("Seating:") })
        draft.values.access = .entryFee
        XCTAssertEqual(draft.reconciled(with: spot).values.access, .entryFee)
    }

    func testStudentOnlyEntryIsIndependentOfCostAndSurvivesReviewSubmission() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spots.first)
        var proposal = PlaceContributionDraft(kind: .missing, anchor: spot.coordinate)
        proposal.values.name = spot.name
        proposal.values.locationConfirmed = true
        proposal.values.setting = .indoors
        proposal.values.features = [.airConditioning]
        proposal.values.entryEligibility = .limited
        proposal.values.entryRequirement = " Students with a valid student card "
        proposal.values.access = .free

        let update = proposal.reconciled(with: spot)
        XCTAssertEqual(update.values.entryEligibility, .limited)
        XCTAssertEqual(update.values.entryRequirement, "Students with a valid student card")
        XCTAssertEqual(update.values.access, .free)
        XCTAssertTrue(update.changes.contains("Who can use it: Limited access"))
        XCTAssertTrue(store.submitPlaceContribution(update))
        let submitted = try XCTUnwrap(store.contributions.first?.placeDraft)
        XCTAssertEqual(submitted.values.entryEligibility, .limited)
        XCTAssertEqual(submitted.values.entryRequirement, "Students with a valid student card")
        XCTAssertEqual(submitted.values.access, .free)
    }

    func testEligibilityCorrectionCountsAsAnEditAndDoesNotSubmitHiddenRestrictions() throws {
        let spot = try XCTUnwrap(Fixtures.spots.first)
        var draft = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        XCTAssertFalse(draft.canSend)
        draft.values.entryEligibility = .limited
        XCTAssertTrue(draft.canSend)
        draft.values.entryRequirement = "Residents only"
        draft.values.entryEligibility = .everyone
        XCTAssertEqual(draft.values.entryRequirement, "")
        XCTAssertEqual(draft.changes, ["Who can use it: Everyone"])
        draft.values.entryEligibility = .unknown
        XCTAssertTrue(draft.changes.isEmpty)
        XCTAssertFalse(draft.canSend)
    }

    func testFreeTicketBookingSurvivesEligibilityChangesAndReview() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spots.first)
        var draft = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        draft.values.access = .free
        draft.values.entryEligibility = .limited
        draft.values.entryRequirement = "Students only"
        draft.values.accessibility = " Book a free ticket before visiting "
        draft.values.entryEligibility = .everyone
        XCTAssertEqual(draft.values.entryRequirement, "")
        let update = draft.reconciled(with: spot)
        XCTAssertEqual(update.values.access, .free)
        XCTAssertEqual(update.values.entryEligibility, .everyone)
        XCTAssertEqual(update.values.accessibility, "Book a free ticket before visiting")
        XCTAssertTrue(store.submitPlaceContribution(update))
        let submitted = try XCTUnwrap(store.contributions.first?.placeDraft)
        XCTAssertEqual(submitted.values.access, .free)
        XCTAssertEqual(submitted.values.accessibility, "Book a free ticket before visiting")
    }

    func testEditingReviewedPlacePreservesSpecificEntryConditions() throws {
        let store = PrototypeStore()
        var spot = try XCTUnwrap(store.spots.first)
        spot.entryEligibility = .limited
        spot.entryRequirement = "University students and staff only"
        spot.entryInformation = "Book a free ticket before visiting"
        XCTAssertEqual(spot.entrySummary, "University students and staff only")
        var edit = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        XCTAssertFalse(edit.canSend)
        XCTAssertEqual(edit.values.entryRequirement, spot.entryRequirement)
        XCTAssertEqual(edit.values.accessibility, spot.entryInformation)
        edit.values.seating = .limited
        let update = edit.reconciled(with: spot)
        XCTAssertEqual(update.values.entryEligibility, .limited)
        XCTAssertEqual(update.values.entryRequirement, spot.entryRequirement)
        XCTAssertEqual(update.values.accessibility, spot.entryInformation)
        XCTAssertTrue(store.submitPlaceContribution(update))
        XCTAssertEqual(store.contributions.first?.placeDraft?.values.entryRequirement, spot.entryRequirement)
        // Missing detail must stay visibly unknown, never invent which group can enter.
        spot.entryRequirement = "  "
        XCTAssertEqual(spot.entrySummary, "Limited access · Requirements not confirmed")
    }
    func testSubmissionKeepsAllPublicAnswersWithoutChangingPrivateDataOrEvidence() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spots.first)
        let saved = store.saveCurrentLocation()
        store.updateSaved(saved.id, title: "Private", note: "Personal")
        let before = try XCTUnwrap(store.savedLocations.first)
        let count = store.presence(for: spot)
        let evidence = store.coolingEvidence(for: spot)
        var draft = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        draft.values.tables = .yes; draft.values.power = .yes; draft.values.note = "Public note"
        XCTAssertTrue(store.submitPlaceContribution(draft))
        XCTAssertFalse(store.submitPlaceContribution(draft))
        XCTAssertEqual(store.contributions.first?.placeDraft?.values, draft.values)
        XCTAssertEqual(store.savedLocations.first?.title, before.title)
        XCTAssertEqual(store.savedLocations.first?.note, before.note)
        XCTAssertEqual(store.presence(for: spot), count)
        XCTAssertEqual(store.coolingEvidence(for: spot), evidence)
        XCTAssertTrue(store.reportDrafts.isEmpty)
    }
    func testDuplicateMustBecomeUpdateAndRetainsProposedDetailsForReview() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spots.first)
        var place = try XCTUnwrap(Fixtures.places.first)
        place.coolSpotID = spot.id
        XCTAssertEqual(store.existingSpot(for: place)?.id, spot.id)
        var draft = PlaceContributionDraft(kind: .missing, anchor: spot.coordinate)
        draft.values.name = spot.name; draft.values.locationConfirmed = true
        draft.values.setting = .both; draft.values.type = spot.type; draft.values.features = [.drinkingWater]
        draft.values.note = "Please check access"
        draft.values.photo = placePhoto()
        XCTAssertTrue(draft.canSend)
        XCTAssertFalse(store.submitPlaceContribution(draft))
        let update = draft.reconciled(with: spot)
        XCTAssertTrue(update.isUpdate)
        XCTAssertEqual(update.values.note, draft.values.note)
        XCTAssertEqual(update.values.features, draft.values.features)
        XCTAssertTrue(store.submitPlaceContribution(update))
        XCTAssertEqual(store.contributions.first?.kind, .placeUpdate)
    }
    func testDiscardKeepsConfirmedVisitAndAllowsRestartWhileAway() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        XCTAssertTrue(store.beginVisitReport(for: spot))
        store.saveReportDraft(.init(experience: .aLittleCooler, comment: "Discard only this", visitedAt: .now), for: spot.id)
        let confirmation = store.visitConfirmedAt[spot.id]
        store.simulateNearbySpot(nil)
        store.discardReportAnswers(spot.id)
        XCTAssertNil(store.reportDrafts[spot.id])
        XCTAssertEqual(store.visitConfirmedAt[spot.id], confirmation)
        XCTAssertTrue(store.beginVisitReport(for: try XCTUnwrap(store.spot(spot.id))))
        XCTAssertNil(store.reportDrafts[spot.id]?.experience)
        XCTAssertEqual(store.reportDrafts[spot.id]?.comment, "")
    }

    func testExplicitNewVisitPreservesPublishedReportAndDoesNotSharePresence() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let first = Date.now.addingTimeInterval(-86_400)
        XCTAssertTrue(store.beginVisitReport(for: spot, at: first))
        XCTAssertTrue(store.submitReport(spot: spot, experience: .muchCooler, helpedFeatures: [], stay: nil, comment: "First", at: first))
        XCTAssertFalse(store.beginVisitReport(for: spot))
        var away = spot; away.isNearby = false
        XCTAssertFalse(store.beginNewVisitReport(for: away))
        XCTAssertTrue(store.beginNewVisitReport(for: spot))
        XCTAssertNil(store.activePresenceSpotID)
        XCTAssertEqual(store.visitReports.count, 1)
        XCTAssertTrue(store.submitReport(spot: spot, experience: .notCooler, helpedFeatures: [], stay: nil, comment: "Second"))
        XCTAssertEqual(store.visitReports.count, 2)
        XCTAssertNotEqual(store.visitReports[0].confirmationAt, store.visitReports[1].confirmationAt)
    }

    func testPrivateNotesPersistForBothPlaceKindsAndUnsaveDoesNotRemoveReports() throws {
        let suite = "SavedKinds.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PrototypeStore(reportDefaults: defaults)
        let spot = try XCTUnwrap(store.spot("library"))
        let place = try XCTUnwrap(store.recognisedPlaces.first)
        _ = store.toggleSaved(spot); _ = store.toggleSaved(place)
        for item in store.savedLocations where item.kind != .coordinate {
            store.updateSaved(item.id, title: "Private \(item.title)", note: "My note")
        }
        let restored = PrototypeStore(reportDefaults: defaults)
        XCTAssertEqual(restored.savedLocations.filter { $0.kind != .coordinate && $0.note == "My note" }.count, 2)
        XCTAssertTrue(restored.beginVisitReport(for: spot))
        XCTAssertTrue(restored.submitReport(spot: spot, experience: .aLittleCooler, helpedFeatures: [], stay: nil, comment: "Keep me"))
        XCTAssertFalse(restored.toggleSaved(spot)); XCTAssertFalse(restored.toggleSaved(place))
        XCTAssertEqual(restored.visitReports.count, 1)
        XCTAssertFalse(restored.isSaved(spotID: spot.id)); XCTAssertFalse(restored.isSaved(placeID: place.id))
    }

}
