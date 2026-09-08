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

    func testIndividualExamplesDoNotInventVisitMetadataFromAggregateCounts() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let items = store.visitorReportItems(for: spot)
        XCTAssertEqual(items.map(\.comment), spot.comments)
        XCTAssertTrue(items.allSatisfy { $0.report == nil && !$0.isOwn })
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

    func testPresenceConfirmationSurvivesStoppingButExpiresWithoutExtension() throws {
        let store = PrototypeStore()
        var spot = try XCTUnwrap(store.spot("library"))
        let startedAt = Date(timeIntervalSince1970: 1_000_000)
        store.checkIn(spot, at: startedAt)
        store.activePresenceSpotID = nil
        spot.isNearby = false

        XCTAssertTrue(store.canReportVisit(for: spot, at: startedAt.addingTimeInterval(23 * 60 * 60)))
        XCTAssertEqual(store.visitConfirmedAt[spot.id], startedAt)
        XCTAssertFalse(store.canReportVisit(for: spot, at: startedAt.addingTimeInterval(24 * 60 * 60)))
        XCTAssertFalse(store.submitReport(spot: spot, experience: .muchCooler,
                                         helpedFeatures: [], stay: nil, comment: "",
                                         at: startedAt.addingTimeInterval(24 * 60 * 60)))
        XCTAssertTrue(store.visitReports.isEmpty)
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
        XCTAssertNil(store.reportingDeadline(for: spot.id))
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
        store.removePrivateVisit(spot.id)
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
