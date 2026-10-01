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

    func testDecodePreservesCurrentPlaceFactsAccessAndHours() throws {
        let response = try decode(makePayload(items: [makeItem()]))
        let item = try XCTUnwrap(response.items.first)

        XCTAssertEqual(item.address.formatted, "Test full address")
        XCTAssertEqual(item.address.line1, "1 Test Street")
        XCTAssertEqual(item.address.line2, "Test Floor")
        XCTAssertEqual(item.address.locality, "Test City")
        XCTAssertEqual(item.address.borough, "Test District")
        XCTAssertEqual(item.address.postalCode, "TEST 1")
        XCTAssertEqual(item.address.countryCode, "GB")
        XCTAssertEqual(item.placeType, .library)
        XCTAssertEqual(item.setting, .indoors)
        XCTAssertEqual(item.coolingFeatures, [.airConditioning, .fans])
        XCTAssertEqual(item.coolingDetails, " Test cooling details ")
        XCTAssertEqual(item.additionalInformation, "Test additional information")
        XCTAssertEqual(item.access.cost, .free)
        XCTAssertEqual(item.access.eligibility, .limited)
        XCTAssertEqual(item.access.seating, .limited)
        XCTAssertEqual(item.access.toilets, .nearby)
        XCTAssertEqual(item.access.drinkingWater, .yes)
        XCTAssertEqual(item.access.wheelchairAccess, .no)
        XCTAssertEqual(item.access.staffedWhenOpen, .yes)
        XCTAssertEqual(item.access.tables, .no)
        XCTAssertEqual(item.access.areaDescription, "Test reading area")
        XCTAssertEqual(item.access.postedStayLimit, .init(status: .limited, minutes: 45))
        XCTAssertEqual(item.hours?.text, "Test hours")
        XCTAssertEqual(item.hours?.timeZone, "Europe/London")
    }

    func testDecodePreservesUnknownFactsAndNullOptionalDetailsWithoutInventingValues() throws {
        var payloadItem = makeItem()
        payloadItem["address"] = Dictionary(uniqueKeysWithValues:
            ["formatted", "line1", "line2", "locality", "borough", "postalCode", "countryCode"]
                .map { ($0, NSNull()) })
        payloadItem["placeType"] = "unknown"
        payloadItem["setting"] = "unknown"
        payloadItem["coolingFeatures"] = []
        payloadItem["coolingDetails"] = NSNull()
        payloadItem["additionalInformation"] = NSNull()
        payloadItem["hours"] = NSNull()
        var access = makeAccess()
        for key in ["cost", "eligibility", "seating", "toilets", "drinkingWater",
                    "wheelchairAccess", "staffedWhenOpen", "tables"] {
            access[key] = "unknown"
        }
        access["areaDescription"] = NSNull()
        access["postedStayLimit"] = ["status": "unknown", "minutes": NSNull()]
        payloadItem["access"] = access

        let item = try XCTUnwrap(decode(makePayload(items: [payloadItem])).items.first)

        XCTAssertNil(item.address.formatted)
        XCTAssertNil(item.address.line1)
        XCTAssertNil(item.address.line2)
        XCTAssertNil(item.address.locality)
        XCTAssertNil(item.address.borough)
        XCTAssertNil(item.address.postalCode)
        XCTAssertNil(item.address.countryCode)
        XCTAssertEqual(item.placeType, .unknown)
        XCTAssertEqual(item.setting, .unknown)
        XCTAssertTrue(item.coolingFeatures.isEmpty)
        XCTAssertNil(item.coolingDetails)
        XCTAssertNil(item.additionalInformation)
        XCTAssertNil(item.hours)
        XCTAssertEqual(item.access.cost, .unknown)
        XCTAssertEqual(item.access.eligibility, .unknown)
        XCTAssertEqual(item.access.seating, .unknown)
        XCTAssertEqual(item.access.toilets, .unknown)
        XCTAssertEqual(item.access.drinkingWater, .unknown)
        XCTAssertEqual(item.access.wheelchairAccess, .unknown)
        XCTAssertEqual(item.access.staffedWhenOpen, .unknown)
        XCTAssertEqual(item.access.tables, .unknown)
        XCTAssertNil(item.access.areaDescription)
        XCTAssertEqual(item.access.postedStayLimit, .unknown)
    }

    func testDecodeMapsUnrecognizedClassificationCodesToUnknownAndPreservesKnownFeatures() throws {
        var payloadItem = makeItem()
        payloadItem["placeType"] = "future_place_type"
        payloadItem["setting"] = "future_setting"
        payloadItem["coolingFeatures"] = ["air_conditioning", "future_feature"]
        var access = makeAccess()
        for key in ["cost", "eligibility", "seating", "toilets", "drinkingWater",
                    "wheelchairAccess", "staffedWhenOpen", "tables"] {
            access[key] = "future_code"
        }
        payloadItem["access"] = access

        let item = try XCTUnwrap(decode(makePayload(items: [payloadItem])).items.first)

        XCTAssertEqual(item.placeType, .unknown)
        XCTAssertEqual(item.setting, .unknown)
        XCTAssertEqual(item.coolingFeatures, [.airConditioning, .unknown])
        XCTAssertEqual(item.access.cost, .unknown)
        XCTAssertEqual(item.access.eligibility, .unknown)
        XCTAssertEqual(item.access.seating, .unknown)
        XCTAssertEqual(item.access.toilets, .unknown)
        XCTAssertEqual(item.access.drinkingWater, .unknown)
        XCTAssertEqual(item.access.wheelchairAccess, .unknown)
        XCTAssertEqual(item.access.staffedWhenOpen, .unknown)
        XCTAssertEqual(item.access.tables, .unknown)
    }

    func testDecodePreservesEachValidPostedStayLimit() throws {
        for expected in [CoolSpotStayLimit.unknown,
                         .init(status: .noStatedLimit, minutes: nil),
                         .init(status: .limited, minutes: 1),
                         .init(status: .limited, minutes: 45)] {
            var payloadItem = makeItem()
            var access = makeAccess()
            access["postedStayLimit"] = ["status": expected.status.rawValue,
                                         "minutes": expected.minutes.map { $0 as Any } ?? NSNull()]
            payloadItem["access"] = access

            let item = try XCTUnwrap(decode(makePayload(items: [payloadItem])).items.first)

            XCTAssertEqual(item.access.postedStayLimit, expected)
        }
    }

    func testDecodeRejectsInconsistentPostedStayLimits() throws {
        let invalidLimits: [[String: Any]] = [
            ["status": "limited", "minutes": NSNull()],
            ["status": "limited", "minutes": 0],
            ["status": "limited", "minutes": -1],
            ["status": "unknown", "minutes": 45],
            ["status": "no_stated_limit", "minutes": 45]
        ]
        for (index, limit) in invalidLimits.enumerated() {
            var payloadItem = makeItem()
            var access = makeAccess()
            access["postedStayLimit"] = limit
            payloadItem["access"] = access

            XCTAssertThrowsError(try decode(makePayload(items: [payloadItem])), "limit \(index)") {
                XCTAssertEqual($0 as? CoolSpotsAPIResponse.LoadError, .invalidItems)
            }
        }
    }

    func testDecodeRejectsMissingRequiredFactsAndMalformedNestedValues() throws {
        var invalidItems: [[String: Any]] = []
        for key in ["address", "placeType", "setting", "coolingFeatures", "access"] {
            var item = makeItem()
            item.removeValue(forKey: key)
            invalidItems.append(item)
            item[key] = NSNull()
            invalidItems.append(item)
        }
        for key in ["cost", "eligibility", "seating", "toilets", "drinkingWater",
                    "wheelchairAccess", "staffedWhenOpen", "tables", "postedStayLimit"] {
            var item = makeItem()
            var access = makeAccess()
            access.removeValue(forKey: key)
            item["access"] = access
            invalidItems.append(item)
            access[key] = NSNull()
            item["access"] = access
            invalidItems.append(item)
        }
        for (key, value) in [("placeType", 1 as Any), ("setting", false as Any),
                             ("coolingFeatures", "air_conditioning" as Any),
                             ("coolingDetails", [] as [String]),
                             ("additionalInformation", false as Any)] {
            var item = makeItem()
            item[key] = value
            invalidItems.append(item)
        }
        var wrongAddress = makeItem()
        wrongAddress["address"] = ["line1": 1]
        invalidItems.append(wrongAddress)
        for hours in [["text": "Test hours"], ["timeZone": "Europe/London"],
                      ["text": "Test hours", "timeZone": NSNull()]] as [[String: Any]] {
            var item = makeItem()
            item["hours"] = hours
            invalidItems.append(item)
        }
        for limit in [["minutes": 45], ["status": "future_status", "minutes": NSNull()],
                      ["status": "limited", "minutes": "45"]] as [[String: Any]] {
            var item = makeItem()
            var access = makeAccess()
            access["postedStayLimit"] = limit
            item["access"] = access
            invalidItems.append(item)
        }
        for (index, item) in invalidItems.enumerated() {
            XCTAssertThrowsError(try decode(makePayload(items: [item])), "item \(index)") {
                XCTAssertTrue($0 is DecodingError, "Expected a decoding error, received \($0)")
            }
        }
    }

    private func makeItem(id: String = "test-cool-spot",
                          placeID: String = "00000000-0000-4000-8000-000000000001",
                          name: String = "Test Library",
                          latitude: Double = 51.5,
                          longitude: Double = -0.1) -> [String: Any] {
        ["id": id, "placeID": placeID, "name": name,
         "location": ["latitude": latitude, "longitude": longitude],
         "address": ["formatted": "Test full address", "line1": "1 Test Street",
                     "line2": "Test Floor", "locality": "Test City", "borough": "Test District",
                     "postalCode": "TEST 1", "countryCode": "GB"],
         "placeType": "library", "setting": "indoors",
         "coolingFeatures": ["air_conditioning", "fans"],
         "coolingDetails": " Test cooling details ",
         "additionalInformation": "Test additional information",
         "access": makeAccess(), "hours": ["text": "Test hours", "timeZone": "Europe/London"]]
    }

    private func makeAccess() -> [String: Any] {
        ["cost": "free", "eligibility": "limited", "seating": "limited", "toilets": "nearby",
         "drinkingWater": "yes", "wheelchairAccess": "no", "staffedWhenOpen": "yes",
         "tables": "no", "areaDescription": "Test reading area",
         "postedStayLimit": ["status": "limited", "minutes": 45]]
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
