import XCTest
@testable import cool_spot

final class CoolSpotsAPILocalIntegrationTests: XCTestCase {
    @MainActor
    func testRealAPIReachesTheStoreAndSavedNotesSurviveRelaunchWithoutCatalogueFallback() async throws {
        try requireLocalIntegration()
        let suite = "CoolSpotsAppIntegrationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PrototypeStore(reportDefaults: defaults, catalogueMode: .api)
        let loader = makeSUT()
        let catalogue = CoolSpotsCatalogueViewModel(load: loader.load, didLoad: store.replaceAPICatalogue)
        XCTAssertTrue(store.spots.isEmpty)

        await catalogue.loadIfNeeded()

        XCTAssertEqual(store.spots.count, 253)
        let library = try XCTUnwrap(store.spot("5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab"))
        XCTAssertEqual(library.name, "Canning Town Library")
        XCTAssertEqual(library.apiRecord?.datasetID, "cool-spot-prototype")
        XCTAssertNotNil(library.placeID)
        XCTAssertNil(library.publishedRecord)
        XCTAssertTrue(store.toggleSaved(library))
        let saved = try XCTUnwrap(store.savedLocations.first)
        store.updateSaved(saved.id, title: "Test Private Bookmark", note: "Test Private Note")
        let reopened = PrototypeStore(reportDefaults: defaults, catalogueMode: .api)
        XCTAssertTrue(reopened.spots.isEmpty)
        XCTAssertNil(reopened.spot(library.id))
        XCTAssertEqual(reopened.savedLocations.first?.id, saved.id)
        XCTAssertEqual(reopened.savedLocations.first?.note, "Test Private Note")
        let reloaded = CoolSpotsCatalogueViewModel(load: loader.load, didLoad: reopened.replaceAPICatalogue)

        await reloaded.loadIfNeeded()

        XCTAssertEqual(reopened.spots.count, 253)
        XCTAssertEqual(reopened.spot(library.id)?.name, "Canning Town Library")
        XCTAssertEqual(reopened.savedLocations.first?.title, "Test Private Bookmark")
        XCTAssertEqual(reopened.savedLocations.first?.note, "Test Private Note")
    }

    func testAnonymousLocalGETLoadsTheCompleteImportedV5Catalogue() async throws {
        try requireLocalIntegration()
        let sut = makeSUT()
        let started = Date()

        let response = try await sut.load()
        let finished = Date()

        XCTAssertEqual(response.schemaVersion, 5)
        XCTAssertEqual(response.datasetID, "cool-spot-prototype")
        XCTAssertEqual(response.items.count, 253)
        XCTAssertEqual(Set(response.items.map(\.id)).count, 253)
        XCTAssertEqual(Set(response.items.map(\.placeID)).count, 253)
        XCTAssertEqual(response.sources.map(\.id), [
            "gla-cool-spaces-2025", "prototype-community-examples"
        ])
        let gla = try XCTUnwrap(response.sources.first)
        XCTAssertEqual(gla.label, "GLA · 2025")
        XCTAssertFalse(gla.isExample)
        XCTAssertNil(gla.retrievedAt)
        XCTAssertNil(gla.sourceUpdatedAt)
        let examples = try XCTUnwrap(response.sources.last)
        XCTAssertEqual(examples.label, "Example cooling info")
        XCTAssertTrue(examples.isExample)
        XCTAssertNil(examples.retrievedAt)
        XCTAssertNil(examples.sourceUpdatedAt)
        XCTAssertEqual(response.items.filter {
            $0.sourceReferences.contains { $0.sourceID == "gla-cool-spaces-2025" }
        }.count, 250)
        XCTAssertEqual(response.items.filter {
            $0.sourceReferences.contains { $0.sourceID == "prototype-community-examples" }
        }.count, 3)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let generated = try XCTUnwrap(formatter.date(from: response.generatedAt))
        XCTAssertGreaterThanOrEqual(generated, started)
        XCTAssertLessThanOrEqual(generated, finished)

        XCTAssertEqual(response.items.flatMap(\.provenance).flatMap(\.fields).count, 5297)
        XCTAssertEqual(response.items.flatMap(\.mapReferences).count, 145)
        let photos = response.items.flatMap(\.photos)
        XCTAssertEqual(photos.count, 3)
        XCTAssertTrue(photos.allSatisfy {
            $0.source == "illustration" && $0.imageURL.scheme == "bundle" &&
            $0.capturedAt == nil && $0.publishedAt == nil && $0.contributionID == nil
        })

        let library = try XCTUnwrap(response.items.first {
            $0.id == "5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab"
        })
        XCTAssertNotEqual(library.id, library.placeID.uuidString.lowercased())
        XCTAssertEqual(library.name, "Canning Town Library")
        XCTAssertEqual(library.location.latitude, 51.516829995)
        XCTAssertEqual(library.location.longitude, 0.010439996)
        XCTAssertEqual(library.sourceReferences, [
            .init(sourceID: "gla-cool-spaces-2025", recordID: "18")
        ])
        XCTAssertTrue(library.photos.isEmpty)
        XCTAssertTrue(library.provenance.contains {
            $0.method == "inferred_from_context" && $0.fields.contains("/hours/timeZone")
        })
        let lobby = try XCTUnwrap(response.items.first {
            $0.id == "27eb2d12-9bcc-5d23-bb25-add95d367f01"
        })
        XCTAssertEqual(lobby.mapReferences.first?.relationship, "within_place")
    }

    func testLocalLoaderRejectsAnUnknownRoute() async throws {
        try requireLocalIntegration()
        let sut = makeSUT(path: "/functions/v1/cool-spots/does-not-exist")

        do {
            _ = try await sut.load()
            XCTFail("Expected an invalid response for the unknown local route")
        } catch {
            XCTAssertEqual(error as? CoolSpotsAPILoader.Error, .invalidResponse)
        }
    }

    // MARK: - Helpers

    private func requireLocalIntegration() throws {
        guard ProcessInfo.processInfo.environment["COOL_SPOTS_LOCAL_API_TESTS"] == "1" else {
            throw XCTSkip("Enable COOL_SPOTS_LOCAL_API_TESTS=1 and start the dedicated local API")
        }
    }

    private func makeSUT(path: String = "/functions/v1/cool-spots") -> CoolSpotsAPILoader {
        let url = URL(string: "http://127.0.0.1:8000" + path)!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCredentialStorage = nil
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 10
        let session = URLSession(configuration: configuration)
        addTeardownBlock { session.invalidateAndCancel() }
        return CoolSpotsAPILoader(url: url, session: session)
    }
}
