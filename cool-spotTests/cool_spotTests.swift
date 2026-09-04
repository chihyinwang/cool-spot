import XCTest
import SwiftUI
@testable import cool_spot

@MainActor
final class CoolSpotTests: XCTestCase {
    func testAppearanceMapsToSystemLightAndDark() {
        XCTAssertNil(AppAppearance.system.colorScheme)
        XCTAssertEqual(AppAppearance.light.colorScheme, .light)
        XCTAssertEqual(AppAppearance.dark.colorScheme, .dark)
        XCTAssertEqual(AppAppearance.allCases.map(\.title), ["Match System", "Light", "Dark"])
    }

    func testAppearanceDefaultsToSystemAndPersistsSelection() throws {
        let suiteName = "CoolSpotAppearanceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preference = AppStorage(wrappedValue: AppAppearance.system,
                                    AppAppearance.storageKey, store: defaults)
        XCTAssertEqual(preference.wrappedValue, .system)

        preference.wrappedValue = .dark
        let restored = AppStorage(wrappedValue: AppAppearance.system,
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

        XCTAssertTrue(store.beginVisitReport(for: spot, at: startedAt.addingTimeInterval(23 * 60 * 60)))
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
}
