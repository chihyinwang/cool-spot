import XCTest
@testable import cool_spot

@MainActor
final class CoolSpotsCatalogueViewModelTests: XCTestCase {
    func testInitIsIdleWithoutLoadingOrInsertingFixtures() {
        let (sut, loader) = makeSUT()

        assertIdle(sut)
        XCTAssertEqual(loader.loadCount, 0)
    }

    func testLoadShowsLoadingUntilTheRequestedCatalogueArrives() async throws {
        let (sut, loader) = makeSUT()
        let started = expectation(description: "Catalogue load started")
        loader.onStart = { _ in started.fulfill() }
        let task = Task { await sut.load() }
        defer { loader.cancelPendingLoads(); task.cancel() }
        await fulfillment(of: [started], timeout: 1)

        assertLoading(sut)
        XCTAssertEqual(loader.loadCount, 1)

        loader.completePendingLoads(with: .success(try makeResponse(id: "test-loaded-spot")))
        await task.value
        XCTAssertEqual(try loadedSpots(sut).map(\.id), ["test-loaded-spot"])
    }

    func testSuccessProjectsCurrentAPIItemsAndKeepsTheirPublicContext() async throws {
        let (sut, loader) = makeSUT()
        let response = try makeResponse(id: "test-current-spot")
        loader.immediateResult = .success(response)

        await sut.load()

        XCTAssertEqual(loader.loadCount, 1)
        let spot = try XCTUnwrap(loadedSpots(sut).first)
        XCTAssertEqual(spot.id, "test-current-spot")
        XCTAssertEqual(spot.placeID, UUID(uuidString: "00000000-0000-4000-8000-000000000001"))
        XCTAssertEqual(spot.name, "Test Current Library")
        XCTAssertEqual(spot.sourceLabel, "GLA · 2025")
        XCTAssertEqual(spot.apiRecord?.datasetID, "test-catalogue")
        XCTAssertEqual(spot.apiRecord?.item, response.items.first)
        XCTAssertTrue(spot.experienceReports.isEmpty)
        XCTAssertNil(spot.publishedRecord)
    }

    func testEmptySuccessRemainsLoadedWithoutUsingBundledOrExamplePlaces() async throws {
        let (sut, loader) = makeSUT()
        loader.immediateResult = .success(try makeResponse())

        await sut.load()

        XCTAssertTrue(try loadedSpots(sut).isEmpty)
        XCTAssertEqual(loader.loadCount, 1)
    }

    func testConnectivityAndInvalidResponsesFailWithoutAutomaticRetry() async {
        for error in [CoolSpotsAPILoader.Error.connectivity, .invalidResponse] {
            let (sut, loader) = makeSUT()
            loader.immediateResult = .failure(error)

            await sut.load()

            assertFailed(sut)
            XCTAssertEqual(loader.loadCount, 1, String(describing: error))
        }
    }

    func testExplicitRetryClearsFailureThenLoadsTheNewResponse() async throws {
        let (sut, loader) = makeSUT()
        loader.immediateResult = .failure(CoolSpotsAPILoader.Error.connectivity)
        await sut.load()
        assertFailed(sut)

        loader.immediateResult = nil
        let retryStarted = expectation(description: "Explicit retry started")
        loader.onStart = { _ in retryStarted.fulfill() }
        let retry = Task { await sut.load() }
        defer { loader.cancelPendingLoads(); retry.cancel() }
        await fulfillment(of: [retryStarted], timeout: 1)

        assertLoading(sut)
        XCTAssertEqual(loader.loadCount, 2)
        loader.completePendingLoads(with: .success(try makeResponse(id: "test-retry-spot")))
        await retry.value
        XCTAssertEqual(try loadedSpots(sut).map(\.id), ["test-retry-spot"])
    }

    func testRepeatedLoadWhileLoadingDoesNotStartAnotherRequest() async throws {
        let (sut, loader) = makeSUT()
        let started = expectation(description: "First load started")
        loader.onStart = { count in if count == 1 { started.fulfill() } }
        let first = Task { await sut.load() }
        defer { loader.cancelPendingLoads(); first.cancel() }
        await fulfillment(of: [started], timeout: 1)

        let duplicateFinished = expectation(description: "Duplicate load returned")
        let duplicate = Task {
            await sut.load()
            duplicateFinished.fulfill()
        }
        defer { duplicate.cancel() }
        await fulfillment(of: [duplicateFinished], timeout: 1)

        assertLoading(sut)
        XCTAssertEqual(loader.loadCount, 1)
        loader.completePendingLoads(with: .success(try makeResponse(id: "test-single-request")))
        await first.value
        await duplicate.value
        XCTAssertEqual(try loadedSpots(sut).map(\.id), ["test-single-request"])
    }

    func testLoaderCancellationReturnsToIdleAndAllowsAnExplicitRetry() async throws {
        let (sut, loader) = makeSUT()
        loader.immediateResult = .failure(CancellationError())

        await sut.load()

        assertIdle(sut)
        XCTAssertEqual(loader.loadCount, 1)
        loader.immediateResult = .success(try makeResponse(id: "test-after-cancellation"))
        await sut.load()
        XCTAssertEqual(loader.loadCount, 2)
        XCTAssertEqual(try loadedSpots(sut).map(\.id), ["test-after-cancellation"])
    }

    func testCancelledTaskDiscardsLateSuccessOrFailureInsteadOfShowingAResultOrError() async throws {
        let results: [Result<CoolSpotsAPIResponse, Swift.Error>] = [
            .success(try makeResponse(id: "test-cancelled-result")),
            .failure(CoolSpotsAPILoader.Error.invalidResponse)
        ]
        for result in results {
            let (sut, loader) = makeSUT()
            let started = expectation(description: "Load started before cancellation")
            loader.onStart = { _ in started.fulfill() }
            let task = Task { await sut.load() }
            defer { loader.cancelPendingLoads(); task.cancel() }
            await fulfillment(of: [started], timeout: 1)
            XCTAssertEqual(loader.loadCount, 1)

            task.cancel()
            loader.completePendingLoads(with: result)
            await task.value

            assertIdle(sut)
        }
    }

    func testAlreadyCancelledTaskDoesNotStartLoadingOrRequestData() async {
        let (sut, loader) = makeSUT()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            await sut.load()
        }

        await task.value

        assertIdle(sut)
        XCTAssertEqual(loader.loadCount, 0)
    }

    private func makeSUT() -> (CoolSpotsCatalogueViewModel, LoaderSpy) {
        let loader = LoaderSpy()
        return (CoolSpotsCatalogueViewModel(load: loader.load), loader)
    }

    private func loadedSpots(_ sut: CoolSpotsCatalogueViewModel,
                             file: StaticString = #filePath, line: UInt = #line) throws -> [CoolSpot] {
        let spots: [CoolSpot]?
        if case let .loaded(value) = sut.state { spots = value }
        else { spots = nil }
        return try XCTUnwrap(spots, "Expected loaded state", file: file, line: line)
    }

    private func assertIdle(_ sut: CoolSpotsCatalogueViewModel,
                            file: StaticString = #filePath, line: UInt = #line) {
        if case .idle = sut.state { return }
        XCTFail("Expected idle state", file: file, line: line)
    }

    private func assertLoading(_ sut: CoolSpotsCatalogueViewModel,
                               file: StaticString = #filePath, line: UInt = #line) {
        if case .loading = sut.state { return }
        XCTFail("Expected loading state", file: file, line: line)
    }

    private func assertFailed(_ sut: CoolSpotsCatalogueViewModel,
                              file: StaticString = #filePath, line: UInt = #line) {
        if case .failed = sut.state { return }
        XCTFail("Expected failed state", file: file, line: line)
    }

    private func makeResponse(id: String? = nil) throws -> CoolSpotsAPIResponse {
        let items: [[String: Any]] = id.map { value in
            [["id": value, "placeID": "00000000-0000-4000-8000-000000000001",
              "name": "Test Current Library", "location": ["latitude": 51.5, "longitude": -0.1],
              "address": ["formatted": "1 Test Street"], "placeType": "library", "setting": "indoors",
              "coolingFeatures": ["air_conditioning"], "coolingDetails": NSNull(),
              "additionalInformation": NSNull(), "hours": NSNull(),
              "access": ["cost": "free", "eligibility": "unknown", "seating": "yes",
                         "toilets": "unknown", "drinkingWater": "unknown", "wheelchairAccess": "unknown",
                         "staffedWhenOpen": "unknown", "tables": "unknown", "areaDescription": NSNull(),
                         "postedStayLimit": ["status": "unknown", "minutes": NSNull()]],
              "sourceReferences": [["sourceID": "test-gla", "recordID": "18"]],
              "provenance": [], "mapReferences": [], "photos": []]]
        } ?? []
        let payload: [String: Any] = [
            "schemaVersion": 5, "datasetID": "test-catalogue", "generatedAt": "2026-10-01T12:00:00.000Z",
            "sources": [["id": "test-gla", "provider": "gla", "label": "GLA · 2025", "isExample": false]],
            "items": items
        ]
        return try CoolSpotsAPIResponse.decode(JSONSerialization.data(withJSONObject: payload))
    }

    @MainActor
    private final class LoaderSpy {
        var loadCount = 0
        var onStart: ((Int) -> Void)?
        var immediateResult: Result<CoolSpotsAPIResponse, Swift.Error>?
        private var pending: [CheckedContinuation<CoolSpotsAPIResponse, Swift.Error>] = []

        func load() async throws -> CoolSpotsAPIResponse {
            loadCount += 1
            onStart?(loadCount)
            if let immediateResult { return try immediateResult.get() }
            return try await withCheckedThrowingContinuation { pending.append($0) }
        }

        func completePendingLoads(with result: Result<CoolSpotsAPIResponse, Swift.Error>) {
            let completions = pending
            pending = []
            for continuation in completions { continuation.resume(with: result) }
        }

        func cancelPendingLoads() {
            completePendingLoads(with: .failure(CancellationError()))
            onStart = nil
        }
    }
}
