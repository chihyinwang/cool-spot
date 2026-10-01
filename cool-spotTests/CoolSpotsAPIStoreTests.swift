import XCTest
@testable import cool_spot

@MainActor
final class CoolSpotsAPIStoreTests: XCTestCase {
    func testAPIStoreStartsEmptyWithoutLegacyLookupFallback() {
        let sut = makeSUT()

        XCTAssertTrue(sut.spots.isEmpty)
        XCTAssertNil(sut.spot("library"))
        XCTAssertTrue(sut.savedLocations.isEmpty)
        XCTAssertTrue(sut.contributions.isEmpty)
        XCTAssertTrue(sut.recognisedPlaces.isEmpty)
    }

    func testAPIReplacementUsesCurrentValuesAndEmptyDoesNotRestoreFixtures() {
        let sut = makeSUT()
        let current = makeSpot(name: "Test Current API Name")

        sut.replaceAPICatalogue([current])

        XCTAssertEqual(sut.spots.map(\.id), [current.id])
        XCTAssertEqual(sut.spot(current.id)?.name, current.name)

        sut.replaceAPICatalogue([])

        XCTAssertTrue(sut.spots.isEmpty)
        XCTAssertNil(sut.spot(current.id))
    }

    func testArchivedPublicationsArePreservedButNeverRestoreOrOverrideAPIFacts() throws {
        let defaults = try isolatedDefaults()
        var archived = try XCTUnwrap(CoolSpotsResponse.bundled().items.first)
        archived.name = "Test Archived Name"
        let record = try JSONSerialization.jsonObject(with: JSONEncoder().encode(archived))
        let snapshot: [String: Any] = [
            "confirmations": [:], "drafts": [:], "reports": [],
            "savedLocations": [], "nearbySpotIDs": [], "publishedCatalogue": [record]
        ]
        let original = try JSONSerialization.data(withJSONObject: snapshot)
        defaults.set(original, forKey: journeyKey)

        let sut = makeSUT(defaults)
        XCTAssertTrue(sut.spots.isEmpty)
        XCTAssertNil(sut.spot(archived.id))
        XCTAssertEqual(defaults.data(forKey: journeyKey), original, "Reading must not rewrite device data.")
        let current = makeSpot(id: archived.id, name: "Test Current API Name")
        sut.replaceAPICatalogue([current])
        XCTAssertEqual(sut.spot(current.id)?.name, current.name)
        XCTAssertTrue(sut.toggleSaved(current))

        let persisted = try XCTUnwrap(defaults.data(forKey: journeyKey))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: persisted) as? [String: Any])
        let records = try XCTUnwrap(object["publishedCoolSpotRecords"] as? [[String: Any]])
        let preserved = try JSONDecoder().decode([CoolSpotsResponse.Item].self,
            from: JSONSerialization.data(withJSONObject: records))
        XCTAssertEqual(preserved, [archived])
        let reopened = makeSUT(defaults)
        XCTAssertTrue(reopened.spots.isEmpty)
        XCTAssertEqual(reopened.savedLocations.first?.kind, .coolSpot(current.id))
        XCTAssertNil(reopened.spot(current.id))
    }

    func testReplacingAndRelaunchingCataloguePreservesPersonalJourneysAndNearbySimulation() throws {
        let defaults = try isolatedDefaults()
        let sut = makeSUT(defaults)
        let first = Fixtures.spots[0]
        let second = Fixtures.spots[1]
        sut.replaceAPICatalogue([first, second])
        sut.simulateNearbySpot(first.id)
        let nearby = try XCTUnwrap(sut.spot(first.id))
        XCTAssertTrue(sut.toggleSaved(nearby))
        let saved = try XCTUnwrap(sut.savedLocations.first)
        sut.updateSaved(saved.id, title: "Test Private Title", note: "Test Private Note")
        let now = Date.now
        sut.checkIn(nearby, at: now)
        XCTAssertTrue(sut.beginVisitReport(for: nearby, at: now))
        sut.saveReportDraft(.init(experience: .muchCooler, comment: "Test Draft", visitedAt: now), for: first.id)
        var other = second
        other.isNearby = true
        XCTAssertTrue(sut.beginVisitReport(for: other, at: now))
        XCTAssertTrue(sut.submitReport(spot: other, experience: .aLittleCooler,
                                      helpedFeatures: [], stay: nil, comment: "Test Report", at: now))
        let reportID = try XCTUnwrap(sut.visitReports.first?.id)
        let deadline = sut.presenceEndsAt

        sut.replaceAPICatalogue([])
        // A private save during loading must not erase the remembered nearby IDs.
        _ = sut.saveCurrentLocation()
        let reopened = makeSUT(defaults)
        XCTAssertTrue(reopened.spots.isEmpty)
        XCTAssertNil(reopened.spot(first.id))
        XCTAssertEqual(reopened.savedLocations.first(where: { $0.id == saved.id })?.note, "Test Private Note")
        XCTAssertEqual(reopened.reportDrafts[first.id]?.comment, "Test Draft")
        XCTAssertEqual(reopened.visitReports.first?.id, reportID)
        XCTAssertEqual(reopened.activePresenceSpotID, first.id)
        XCTAssertEqual(reopened.presenceEndsAt, deadline)
        let updated = makeSpot(id: first.id, name: "Test Updated API Name")
        reopened.replaceAPICatalogue([updated, second])
        XCTAssertEqual(reopened.spot(first.id)?.name, updated.name)
        XCTAssertEqual(reopened.spot(first.id)?.isNearby, true)
        XCTAssertEqual(reopened.savedLocations.first(where: { $0.id == saved.id })?.title, "Test Private Title")
        XCTAssertEqual(reopened.visitConfirmedAt[first.id], now)
        XCTAssertEqual(reopened.presenceEndsAt, deadline)
    }

    func testAPIStoreRejectsLocalPublicationWithoutChangingProposalOrPublicList() throws {
        let sut = makeSUT()
        let current = Fixtures.spots[0]
        sut.replaceAPICatalogue([current])
        var draft = PlaceContributionDraft(kind: .update, anchor: current.coordinate, spot: current)
        draft.values.name = "Test Pending Name"
        XCTAssertTrue(sut.submitPlaceContribution(draft))

        XCTAssertFalse(sut.publishContribution(draft.id))
        XCTAssertEqual(sut.contributions.first?.status, .inReview)
        XCTAssertEqual(sut.spots.map(\.id), [current.id])
        XCTAssertNotNil(sut.contributionError)
    }

    func testAPIReplacementDoesNotChangeExplicitExampleStore() {
        let sut = PrototypeStore()
        let ids = sut.spots.map(\.id)

        sut.replaceAPICatalogue([])

        XCTAssertEqual(sut.spots.map(\.id), ids)
        XCTAssertNotNil(sut.spot("library"))
    }

    func testAPIStoreDoesNotAddFixturePeerReportsToTheCurrentCatalogue() {
        let sut = makeSUT()
        let spot = makeSpot(id: "library", name: "Test API Place")
        XCTAssertFalse(Fixtures.visitorReports.filter { $0.report?.spotID == spot.id }.isEmpty)
        sut.replaceAPICatalogue([spot])

        XCTAssertTrue(sut.visitorReportItems(for: spot).isEmpty)
        XCTAssertEqual(sut.experienceReportTotal(for: spot), 0)
        XCTAssertEqual(sut.presence(for: spot), 0)
    }

    private func makeSpot(id: String = "library", name: String) -> CoolSpot {
        CoolSpot(id: id, name: name, address: "Test Address", latitude: 51.5, longitude: -0.1,
                 source: .gla, environment: .indoors, type: .library, features: [.fans],
                 access: .free, seating: .limited, distance: "", presenceCount: 0,
                 experienceReports: [:], latestReportAt: .distantPast, stayReports: [:],
                 comments: [], isNearby: false)
    }

    private let journeyKey = "prototype.reportJourneys.v1"

    private func makeSUT(_ defaults: UserDefaults? = nil) -> PrototypeStore {
        PrototypeStore(reportDefaults: defaults, catalogueMode: .api)
    }

    private func isolatedDefaults() throws -> UserDefaults {
        let suite = "CoolSpotsAPIStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        return defaults
    }
}
