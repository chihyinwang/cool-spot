import XCTest
@testable import cool_spot

final class CoolSpotsAPIResponseTests: XCTestCase {
    func testDecodePreservesV5EnvelopeSourcesAndIndependentIdentities() throws {
        let item = makeItem(name: " Test Library ")
        let response = try decode(makePayload(items: [item]))

        XCTAssertEqual(response.schemaVersion, 5)
        XCTAssertEqual(response.datasetID, "test-catalogue")
        XCTAssertEqual(response.generatedAt, "2026-10-01T12:00:00.000Z")
        XCTAssertEqual(response.sources.count, 2)
        let source = try XCTUnwrap(response.sources.first)
        XCTAssertEqual(source.id, "test-source-2025")
        XCTAssertEqual(source.provider, "test-provider")
        XCTAssertEqual(source.label, "Test source · 2025")
        XCTAssertEqual(source.dataset, "Test dataset 2025")
        XCTAssertEqual(source.url, URL(string: "https://example.com/catalogue"))
        XCTAssertEqual(source.downloadURL, URL(string: "https://example.com/catalogue.csv"))
        XCTAssertEqual(source.retrievedAt, "2026-09-01T00:00:00.000Z")
        XCTAssertEqual(source.sourceUpdatedAt, "2025-06-01T00:00:00.000Z")
        XCTAssertEqual(source.sha256, String(repeating: "a", count: 64))
        XCTAssertFalse(source.isExample)
        let example = try XCTUnwrap(response.sources.last)
        XCTAssertEqual(example.id, "test-examples")
        XCTAssertTrue(example.isExample)
        XCTAssertNil(example.dataset)
        XCTAssertNil(example.url)
        XCTAssertNil(example.downloadURL)
        XCTAssertNil(example.retrievedAt)
        XCTAssertNil(example.sourceUpdatedAt)
        XCTAssertNil(example.sha256)

        XCTAssertEqual(response.items.count, 1)
        let decodedItem = try XCTUnwrap(response.items.first)
        XCTAssertEqual(decodedItem.id, "test-cool-spot")
        XCTAssertEqual(decodedItem.placeID, UUID(uuidString: "00000000-0000-4000-8000-000000000001"))
        XCTAssertEqual(decodedItem.name, " Test Library ")
        XCTAssertEqual(decodedItem.location.latitude, 51.5)
        XCTAssertEqual(decodedItem.location.longitude, -0.1)
    }

    func testDecodeAcceptsAnEmptyV5Catalogue() throws {
        var payload = makePayload(items: [])
        payload["sources"] = []

        let response = try decode(payload)

        XCTAssertTrue(response.items.isEmpty)
        XCTAssertTrue(response.sources.isEmpty)
    }

    func testDecodeRejectsUnsupportedVersions() throws {
        for version in [1, 2, 3, 4, 6] {
            var payload = makePayload(items: [])
            payload["schemaVersion"] = version
            XCTAssertThrowsError(try decode(payload), "version \(version)") {
                XCTAssertEqual($0 as? CoolSpotsAPIResponse.LoadError, .unsupportedVersion)
            }
        }
    }

    func testDecodeRejectsMalformedJSONMissingRequiredFieldsAndWrongTypes() throws {
        var malformedPayloads = [Data("invalid-json".utf8)]
        for key in ["schemaVersion", "datasetID", "generatedAt", "sources", "items"] {
            var payload = makePayload(items: [makeItem()])
            payload.removeValue(forKey: key)
            malformedPayloads.append(try jsonData(payload))
        }
        for key in ["id", "placeID", "name", "location"] {
            var item = makeItem()
            item.removeValue(forKey: key)
            malformedPayloads.append(try jsonData(makePayload(items: [item])))
        }
        var invalidUUID = makeItem()
        invalidUUID["placeID"] = "not-a-uuid"
        malformedPayloads.append(try jsonData(makePayload(items: [invalidUUID])))
        var wrongType = makeItem()
        wrongType["location"] = ["latitude": "51.5", "longitude": -0.1]
        malformedPayloads.append(try jsonData(makePayload(items: [wrongType])))

        for (index, data) in malformedPayloads.enumerated() {
            XCTAssertThrowsError(try CoolSpotsAPIResponse.decode(data), "payload \(index)") {
                XCTAssertTrue($0 is DecodingError, "Expected a decoding error, received \($0)")
            }
        }
    }

    func testDecodeRejectsBlankTextAndDuplicateCoolSpotOrPlaceIdentities() throws {
        var invalidLists: [[Dictionary<String, Any>]] = []
        for value in ["", " \n\t", "\u{00a0}\u{200b}"] {
            invalidLists.append([makeItem(id: value)])
            invalidLists.append([makeItem(name: value)])
        }
        invalidLists.append([
            makeItem(),
            makeItem(placeID: "00000000-0000-4000-8000-000000000002")
        ])
        invalidLists.append([
            makeItem(),
            makeItem(id: "another-cool-spot")
        ])

        for (index, items) in invalidLists.enumerated() {
            XCTAssertThrowsError(try decode(makePayload(items: items)), "items \(index)") {
                XCTAssertEqual($0 as? CoolSpotsAPIResponse.LoadError, .invalidItems)
            }
        }
    }

    func testDecodeRejectsOutOfRangeCoordinatesAndPreservesValidBoundaries() throws {
        for (latitude, longitude) in [(90.1, 0.0), (-90.1, 0.0), (0.0, 180.1), (0.0, -180.1)] {
            XCTAssertThrowsError(try decode(makePayload(items: [
                makeItem(latitude: latitude, longitude: longitude)
            ]))) {
                XCTAssertEqual($0 as? CoolSpotsAPIResponse.LoadError, .invalidItems)
            }
        }
        for (latitude, longitude) in [(0.0, 0.0), (90.0, 180.0), (-90.0, -180.0)] {
            let response = try decode(makePayload(items: [
                makeItem(latitude: latitude, longitude: longitude)
            ]))
            let location = try XCTUnwrap(response.items.first?.location)
            XCTAssertEqual(location.latitude, latitude)
            XCTAssertEqual(location.longitude, longitude)
        }
    }

    private func makeItem(id: String = "test-cool-spot",
                          placeID: String = "00000000-0000-4000-8000-000000000001",
                          name: String = "Test Library",
                          latitude: Double = 51.5,
                          longitude: Double = -0.1) -> [String: Any] {
        ["id": id, "placeID": placeID, "name": name,
         "location": ["latitude": latitude, "longitude": longitude]]
    }

    private func makePayload(items: [[String: Any]]) -> [String: Any] {
        ["schemaVersion": 5, "datasetID": "test-catalogue",
         "generatedAt": "2026-10-01T12:00:00.000Z",
         "sources": [
            ["id": "test-source-2025", "provider": "test-provider",
             "label": "Test source · 2025", "dataset": "Test dataset 2025",
             "url": "https://example.com/catalogue",
             "downloadURL": "https://example.com/catalogue.csv",
             "retrievedAt": "2026-09-01T00:00:00.000Z",
             "sourceUpdatedAt": "2025-06-01T00:00:00.000Z",
             "sha256": String(repeating: "a", count: 64), "isExample": false],
            ["id": "test-examples", "provider": "community", "label": "Test examples",
             "dataset": NSNull(), "url": NSNull(), "downloadURL": NSNull(),
             "retrievedAt": NSNull(), "sourceUpdatedAt": NSNull(),
             "sha256": NSNull(), "isExample": true]
         ], "items": items]
    }

    private func jsonData(_ payload: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: payload)
    }

    private func decode(_ payload: [String: Any]) throws -> CoolSpotsAPIResponse {
        try CoolSpotsAPIResponse.decode(jsonData(payload))
    }
}
