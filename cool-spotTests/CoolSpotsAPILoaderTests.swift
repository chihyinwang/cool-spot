import XCTest
@testable import cool_spot

final class CoolSpotsAPILoaderTests: XCTestCase {
    func testInitDoesNotRequestData() {
        let (_, stub) = makeSUT()

        XCTAssertTrue(stub.requests.isEmpty)
    }

    func testLoadRequestsProvidedURLUsingAnonymousGETOnEveryLoad() async throws {
        let (sut, stub) = makeSUT()
        let data = try makeData()
        stub.onStart = { protocolStub, _ in protocolStub.succeed(data: data) }

        _ = await result(for: sut)
        _ = await result(for: sut)

        XCTAssertEqual(stub.requests.count, 2)
        for request in stub.requests {
            XCTAssertEqual(request.url, stub.url)
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            XCTAssertNil(request.value(forHTTPHeaderField: "apikey"))
            XCTAssertNil(request.httpBody)
        }
    }

    func testLoadReturnsDecodedV5CatalogueOnHTTP200() async throws {
        let (sut, stub) = makeSUT()
        let data = try makeData(items: [makeItem()])
        stub.onStart = { protocolStub, _ in protocolStub.succeed(data: data) }

        let response = try await sut.load()

        XCTAssertEqual(response.schemaVersion, 5)
        XCTAssertEqual(response.datasetID, "test-catalogue")
        XCTAssertEqual(response.generatedAt, "2026-10-01T12:00:00.000Z")
        XCTAssertEqual(response.sources.map(\.id), ["test-source-2025"])
        XCTAssertEqual(response.sources.first?.sourceUpdatedAt, "2025-06-01T00:00:00.000Z")
        XCTAssertEqual(response.items.count, 1)
        let item = try XCTUnwrap(response.items.first)
        XCTAssertEqual(item.id, "test-cool-spot")
        XCTAssertEqual(item.placeID, UUID(uuidString: "00000000-0000-4000-8000-000000000001"))
        XCTAssertEqual(item.name, "Test Library")
        XCTAssertEqual(item.location.latitude, 51.5)
        XCTAssertEqual(item.location.longitude, -0.1)
        XCTAssertEqual(item.address.formatted, "1 Test Street")
        XCTAssertEqual(item.coolingFeatures, [.airConditioning])
        XCTAssertEqual(item.access.cost, .free)
        XCTAssertEqual(item.sourceReferences.map(\.recordID), ["18"])
        XCTAssertEqual(item.provenance.first?.fields, ["/name"])
        XCTAssertEqual(item.mapReferences.first?.placeID, "test-external-place")
        XCTAssertTrue(item.photos.isEmpty)
    }

    func testLoadReturnsAnEmptyCatalogueOnHTTP200() async throws {
        let (sut, stub) = makeSUT()
        let data = try makeData()
        stub.onStart = { protocolStub, _ in protocolStub.succeed(data: data) }

        let response = try await sut.load()

        XCTAssertEqual(response.datasetID, "test-catalogue")
        XCTAssertTrue(response.items.isEmpty)
        XCTAssertTrue(response.sources.isEmpty)
    }

    func testLoadRejectsNon200HTTPResponsesEvenWithValidJSON() async throws {
        let data = try makeData()
        for status in [201, 204, 301, 400, 401, 403, 404, 500] {
            let (sut, stub) = makeSUT()
            stub.onStart = { protocolStub, _ in
                protocolStub.succeed(data: data, status: status)
            }

            assertFailure(await result(for: sut), equals: .invalidResponse, context: "HTTP \(status)")
        }
    }

    func testLoadRejectsNonHTTPResponses() async throws {
        let (sut, stub) = makeSUT()
        let data = try makeData()
        let url = stub.url
        stub.onStart = { protocolStub, _ in
            protocolStub.succeed(data: data, response: URLResponse(
                url: url, mimeType: "application/json",
                expectedContentLength: data.count, textEncodingName: "utf-8"
            ))
        }

        assertFailure(await result(for: sut), equals: .invalidResponse)
    }

    func testLoadRejectsMalformedUnsupportedAndInvalidV5PayloadsOnHTTP200() async throws {
        var blankName = makeItem()
        blankName["name"] = " \n\t"
        let invalidData = [Data(), Data("invalid-json".utf8),
                           try makeData(version: 4), try makeData(items: [blankName])]
        for (index, data) in invalidData.enumerated() {
            let (sut, stub) = makeSUT()
            stub.onStart = { protocolStub, _ in protocolStub.succeed(data: data) }

            assertFailure(await result(for: sut), equals: .invalidResponse, context: "payload \(index)")
        }
    }

    func testLoadMapsTransportFailuresToConnectivity() async {
        for code in [URLError.timedOut, .cannotConnectToHost, .networkConnectionLost] {
            let (sut, stub) = makeSUT()
            stub.onStart = { protocolStub, _ in protocolStub.fail(URLError(code)) }

            assertFailure(await result(for: sut), equals: .connectivity, context: "code \(code.rawValue)")
        }
    }

    func testLoadPreservesTransportCancellationAsCancellationError() async {
        let (sut, stub) = makeSUT()
        stub.onStart = { protocolStub, _ in protocolStub.fail(URLError(.cancelled)) }

        assertCancellation(await result(for: sut))
    }

    func testCancellingAnInFlightLoadPreservesCancellation() async {
        let (sut, stub) = makeSUT()
        let started = expectation(description: "Request started")
        stub.onStart = { _, _ in started.fulfill() }
        let task = Task { await result(for: sut) }
        defer { task.cancel() }
        await fulfillment(of: [started], timeout: 1)

        task.cancel()

        assertCancellation(await task.value)
    }

    func testLoadDoesNotRequestDataWhenItsTaskIsAlreadyCancelled() async {
        let (sut, stub) = makeSUT()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await result(for: sut)
        }

        assertCancellation(await task.value)
        XCTAssertTrue(stub.requests.isEmpty)
    }

    func testConcurrentLoadsKeepTheirOwnResponsesWhenCompletedInReverseOrder() async throws {
        let (sut, stub) = makeSUT()
        let firstStarted = expectation(description: "First request started")
        let secondStarted = expectation(description: "Second request started")
        stub.onStart = { _, index in
            if index == 0 { firstStarted.fulfill() }
            if index == 1 { secondStarted.fulfill() }
        }
        let first = Task { await result(for: sut) }
        defer { first.cancel() }
        await fulfillment(of: [firstStarted], timeout: 1)
        let second = Task { await result(for: sut) }
        defer { second.cancel() }
        await fulfillment(of: [secondStarted], timeout: 1)

        let secondRequest = stub.request(at: 1)
        XCTAssertNotNil(secondRequest)
        secondRequest?.succeed(data: try makeData(items: [makeItem(id: "second-spot")]))
        let secondResponse = try await second.value.get()
        XCTAssertEqual(secondResponse.items.map(\.id), ["second-spot"])

        let firstRequest = stub.request(at: 0)
        XCTAssertNotNil(firstRequest)
        firstRequest?.succeed(data: try makeData(items: [makeItem(id: "first-spot")]))
        let firstResponse = try await first.value.get()
        XCTAssertEqual(firstResponse.items.map(\.id), ["first-spot"])
        XCTAssertEqual(stub.requests.count, 2)
    }

    // MARK: - Helpers

    private func makeSUT() -> (CoolSpotsAPILoader, SessionStub) {
        let url = URL(string: "https://example.com/test-catalogue/\(UUID().uuidString)")!
        let stub = SessionStub(url: url)
        URLProtocolStub.register(stub)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        addTeardownBlock {
            session.invalidateAndCancel()
            URLProtocolStub.removeStub(for: url)
        }
        return (CoolSpotsAPILoader(url: url, session: session), stub)
    }

    private func result(for sut: CoolSpotsAPILoader) async -> Result<CoolSpotsAPIResponse, Swift.Error> {
        do { return .success(try await sut.load()) }
        catch { return .failure(error) }
    }

    private func assertFailure(_ result: Result<CoolSpotsAPIResponse, Swift.Error>,
                               equals expected: CoolSpotsAPILoader.Error, context: String = "",
                               file: StaticString = #filePath, line: UInt = #line) {
        switch result {
        case .success:
            XCTFail("Expected \(expected), received success. \(context)", file: file, line: line)
        case let .failure(error):
            XCTAssertEqual(error as? CoolSpotsAPILoader.Error, expected, context, file: file, line: line)
        }
    }

    private func assertCancellation(_ result: Result<CoolSpotsAPIResponse, Swift.Error>,
                                    file: StaticString = #filePath, line: UInt = #line) {
        switch result {
        case .success:
            XCTFail("Expected cancellation, received success", file: file, line: line)
        case let .failure(error):
            XCTAssertTrue(error is CancellationError, "Expected CancellationError, received \(error)",
                          file: file, line: line)
        }
    }

    private func makeData(items: [[String: Any]] = [], version: Int = 5) throws -> Data {
        let sources: [[String: Any]] = items.isEmpty ? [] : [
            ["id": "test-source-2025", "provider": "test-provider", "label": "Test source · 2025",
             "isExample": false, "sourceUpdatedAt": "2025-06-01T00:00:00.000Z"]
        ]
        return try JSONSerialization.data(withJSONObject: [
            "schemaVersion": version, "datasetID": "test-catalogue",
            "generatedAt": "2026-10-01T12:00:00.000Z", "sources": sources, "items": items
        ])
    }

    private func makeItem(id: String = "test-cool-spot") -> [String: Any] {
        ["id": id, "placeID": "00000000-0000-4000-8000-000000000001", "name": "Test Library",
         "location": ["latitude": 51.5, "longitude": -0.1],
         "address": ["formatted": "1 Test Street", "line1": NSNull(), "line2": NSNull(),
                     "locality": NSNull(), "borough": NSNull(), "postalCode": NSNull(),
                     "countryCode": NSNull()],
         "placeType": "library", "setting": "indoors", "coolingFeatures": ["air_conditioning"],
         "coolingDetails": NSNull(), "additionalInformation": NSNull(), "hours": NSNull(),
         "access": ["cost": "free", "eligibility": "everyone", "seating": "unknown",
                    "toilets": "unknown", "drinkingWater": "unknown", "wheelchairAccess": "unknown",
                    "staffedWhenOpen": "unknown", "tables": "unknown", "areaDescription": NSNull(),
                    "postedStayLimit": ["status": "unknown", "minutes": NSNull()]],
         "sourceReferences": [["sourceID": "test-source-2025", "recordID": "18"]],
         "provenance": [["sourceID": "test-source-2025", "recordID": "18", "method": "imported",
                         "recordedAt": NSNull(), "fields": ["/name"]]],
         "mapReferences": [["provider": "apple_maps", "placeID": "test-external-place",
                            "relationship": "same_place", "verification": "test-verification",
                            "checkedAt": NSNull()]], "photos": []]
    }

    private final class SessionStub {
        let url: URL
        private let lock = NSLock()
        private var recordedProtocols: [URLProtocolStub] = []
        private var handler: ((URLProtocolStub, Int) -> Void)?

        init(url: URL) { self.url = url }

        var requests: [URLRequest] {
            lock.withLock { recordedProtocols.map(\.request) }
        }

        var onStart: ((URLProtocolStub, Int) -> Void)? {
            get { lock.withLock { handler } }
            set { lock.withLock { handler = newValue } }
        }

        func request(at index: Int) -> URLProtocolStub? {
            lock.withLock {
                recordedProtocols.indices.contains(index) ? recordedProtocols[index] : nil
            }
        }

        func start(_ protocolStub: URLProtocolStub) {
            let (index, onStart) = lock.withLock {
                let index = recordedProtocols.count
                recordedProtocols.append(protocolStub)
                return (index, handler)
            }
            if let onStart { onStart(protocolStub, index) }
            else { protocolStub.fail(URLError(.cannotConnectToHost)) }
        }
    }

    private final class URLProtocolStub: URLProtocol {
        private static let registryLock = NSLock()
        private static var registry: [URL: SessionStub] = [:]

        static func register(_ stub: SessionStub) {
            registryLock.withLock { registry[stub.url] = stub }
        }

        static func removeStub(for url: URL) {
            _ = registryLock.withLock { registry.removeValue(forKey: url) }
        }

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            guard let url = request.url,
                  let stub = Self.registryLock.withLock({ Self.registry[url] }) else {
                fail(URLError(.badURL))
                return
            }
            stub.start(self)
        }

        override func stopLoading() {}

        func succeed(data: Data, status: Int = 200) {
            succeed(data: data, response: HTTPURLResponse(
                url: request.url!, statusCode: status, httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!)
        }

        func succeed(data: Data, response: URLResponse) {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }

        func fail(_ error: Swift.Error) {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
}
