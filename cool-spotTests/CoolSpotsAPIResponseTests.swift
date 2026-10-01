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

    func testDecodePreservesSourceEvidenceMapRelationshipsAndOrderedPhotoMetadata() throws {
        let response = try decode(makePayload(items: [makeItemWithRelations()]))
        let item = try XCTUnwrap(response.items.first)

        XCTAssertEqual(item.sourceReferences, [
            .init(sourceID: "test-examples", recordID: "18"),
            .init(sourceID: "test-source-2025", recordID: "18")
        ])
        XCTAssertEqual(item.provenance, [
            .init(sourceID: "test-source-2025", recordID: "18", method: "mapped_from_source",
                  recordedAt: "2026-09-01T00:00:00.000Z", fields: ["/name", "/access/cost"]),
            .init(sourceID: "test-examples", recordID: "18", method: "example_data",
                  recordedAt: "2026-09-02T00:00:00.000Z", fields: ["/coolingDetails"]),
            .init(sourceID: "test-source-2025", recordID: "18", method: "inferred_from_context",
                  recordedAt: "2026-09-01T00:00:00.000Z", fields: ["/hours/timeZone"]),
            .init(sourceID: "test-source-2025", recordID: "18", method: "inferred_from_name",
                  recordedAt: "2026-09-01T00:00:00.000Z", fields: ["/placeType"])
        ])
        XCTAssertEqual(item.mapReferences, [
            .init(provider: "apple_maps", placeID: "test-containing-apple-id", relationship: "within_place",
                  verification: "reviewed", checkedAt: "2026-09-03T00:00:00.000Z"),
            .init(provider: "apple_maps", placeID: "test-same-apple-id", relationship: "same_place",
                  verification: "automatic", checkedAt: "2026-09-04T00:00:00.000Z")
        ])
        XCTAssertEqual(item.photos.count, 2)
        XCTAssertEqual(item.photos.map(\.id), ["test-second-photo", "test-first-photo"])
        let photo = try XCTUnwrap(item.photos.first)
        XCTAssertEqual(photo.thumbnailURL, URL(string: "https://example.com/test-thumbnail.jpg"))
        XCTAssertEqual(photo.imageURL, URL(string: "https://example.com/test-image.jpg"))
        XCTAssertEqual(photo.width, 800)
        XCTAssertEqual(photo.height, 600)
        XCTAssertEqual(photo.caption, "Test photo caption")
        XCTAssertEqual(photo.capturedAt, "2025-06-01T00:00:00.000Z")
        XCTAssertEqual(photo.publishedAt, "2026-09-02T00:00:00.000Z")
        XCTAssertEqual(photo.attribution, "Test illustration credit")
        XCTAssertEqual(photo.source, "illustration")
        XCTAssertEqual(photo.contributionID, "test-contribution")
        XCTAssertEqual(item.photos.last?.imageURL, URL(string: "bundle://TestIllustration.jpg"))
        XCTAssertEqual(item.placeID, UUID(uuidString: "00000000-0000-4000-8000-000000000001"))
    }

    func testDecodeAcceptsEmptyRelationArraysWithoutInventingEvidenceMapsOrPhotos() throws {
        let response = try decode(makePayload(items: [makeItem()]))
        let item = try XCTUnwrap(response.items.first)

        XCTAssertTrue(item.sourceReferences.isEmpty)
        XCTAssertTrue(item.provenance.isEmpty)
        XCTAssertTrue(item.mapReferences.isEmpty)
        XCTAssertTrue(item.photos.isEmpty)
        XCTAssertEqual(item.id, "test-cool-spot")
        XCTAssertEqual(item.name, "Test Library")
    }

    func testDecodePreservesUnknownRelationDatesAndOptionalPhotoValuesAsNil() throws {
        var payloadItem = makeItemWithRelations()
        payloadItem["provenance"] = [["sourceID": "test-source-2025", "recordID": "18",
                                      "method": "mapped_from_source", "recordedAt": NSNull(),
                                      "fields": ["/name"]]]
        payloadItem["mapReferences"] = [["provider": "apple_maps", "placeID": "test-apple-id",
                                         "relationship": "same_place", "verification": "reviewed",
                                         "checkedAt": NSNull()]]
        var photo = makePhoto(id: "test-photo")
        for key in ["caption", "capturedAt", "publishedAt", "contributionID"] {
            photo[key] = NSNull()
        }
        payloadItem["photos"] = [photo]

        let item = try XCTUnwrap(decode(makePayload(items: [payloadItem])).items.first)

        let provenance = try XCTUnwrap(item.provenance.first)
        let map = try XCTUnwrap(item.mapReferences.first)
        let decodedPhoto = try XCTUnwrap(item.photos.first)
        XCTAssertNil(provenance.recordedAt)
        XCTAssertNil(map.checkedAt)
        XCTAssertNil(decodedPhoto.caption)
        XCTAssertNil(decodedPhoto.capturedAt)
        XCTAssertNil(decodedPhoto.publishedAt)
        XCTAssertNil(decodedPhoto.contributionID)
        XCTAssertEqual(decodedPhoto.attribution, "Test illustration credit")
    }

    func testDecodeRejectsMissingRelationArraysAndMalformedRelationOrPhotoFields() throws {
        var invalidItems: [[String: Any]] = []
        for key in ["sourceReferences", "provenance", "mapReferences", "photos"] {
            var item = makeItemWithRelations()
            item.removeValue(forKey: key)
            invalidItems.append(item)
            item[key] = NSNull()
            invalidItems.append(item)
            item[key] = "not-an-array"
            invalidItems.append(item)
        }
        let requiredKeys: [String: [String]] = [
            "sourceReferences": ["sourceID", "recordID"],
            "provenance": ["sourceID", "recordID", "method", "fields"],
            "mapReferences": ["provider", "placeID", "relationship", "verification"],
            "photos": ["id", "thumbnailURL", "imageURL", "width", "height", "attribution", "source"]
        ]
        for group in ["sourceReferences", "provenance", "mapReferences", "photos"] {
            let validItem = makeItemWithRelations()
            let records = try XCTUnwrap(validItem[group] as? [[String: Any]])
            let first = try XCTUnwrap(records.first)
            for key in requiredKeys[group] ?? [] {
                var record = first
                record.removeValue(forKey: key)
                var item = validItem
                item[group] = [record]
                invalidItems.append(item)
                record[key] = NSNull()
                item[group] = [record]
                invalidItems.append(item)
            }
        }
        for (group, key, value) in [
            ("sourceReferences", "recordID", 18 as Any),
            ("provenance", "fields", "/name" as Any),
            ("provenance", "recordedAt", 1 as Any),
            ("mapReferences", "checkedAt", true as Any),
            ("photos", "width", "800" as Any),
            ("photos", "caption", 1 as Any),
            ("photos", "imageURL", false as Any)
        ] {
            var item = makeItemWithRelations()
            var records = try XCTUnwrap(item[group] as? [[String: Any]])
            records[0][key] = value
            item[group] = records
            invalidItems.append(item)
        }
        for (index, item) in invalidItems.enumerated() {
            XCTAssertThrowsError(try decode(makePayload(items: [item])), "item \(index)") {
                XCTAssertTrue($0 is DecodingError, "Expected a decoding error, received \($0)")
            }
        }
    }

    func testDecodeRejectsAmbiguousOrUnlinkedSourceIdentities() throws {
        var missingSource = makeItemWithRelations()
        missingSource["sourceReferences"] = [["sourceID": "missing-source", "recordID": "18"]]
        var wrongRecord = makeItemWithRelations()
        wrongRecord["provenance"] = [["sourceID": "test-source-2025", "recordID": "other-record",
                                      "method": "mapped_from_source", "recordedAt": NSNull(),
                                      "fields": ["/name"]]]
        var wrongSource = makeItemWithRelations()
        wrongSource["sourceReferences"] = [["sourceID": "test-examples", "recordID": "18"]]
        var invalidPayloads = [missingSource, wrongRecord, wrongSource].map { makePayload(items: [$0]) }

        var duplicateSource = makePayload(items: [makeItemWithRelations()])
        var sources = try XCTUnwrap(duplicateSource["sources"] as? [[String: Any]])
        sources.append(try XCTUnwrap(sources.first))
        duplicateSource["sources"] = sources
        invalidPayloads.append(duplicateSource)

        var blankSource = makePayload(items: [makeItem()])
        var blankSources = try XCTUnwrap(blankSource["sources"] as? [[String: Any]])
        blankSources[0]["id"] = " \n"
        blankSource["sources"] = blankSources
        invalidPayloads.append(blankSource)

        var blankRecord = makeItemWithRelations()
        blankRecord["sourceReferences"] = [["sourceID": "test-source-2025", "recordID": " \n"]]
        invalidPayloads.append(makePayload(items: [blankRecord]))

        var firstPlace = makeItemWithRelations()
        firstPlace["sourceReferences"] = [["sourceID": "test-source-2025", "recordID": "19"]]
        var secondPlace = makeItem(id: "another-cool-spot",
                                   placeID: "00000000-0000-4000-8000-000000000002")
        secondPlace["sourceReferences"] = [["sourceID": "test-source-2025", "recordID": "18"]]
        invalidPayloads.append(makePayload(items: [firstPlace, secondPlace]))

        for (index, payload) in invalidPayloads.enumerated() {
            XCTAssertThrowsError(try decode(payload), "payload \(index)") {
                XCTAssertEqual($0 as? CoolSpotsAPIResponse.LoadError, .invalidItems)
            }
        }
    }

    private func makeItemWithRelations() -> [String: Any] {
        var item = makeItem()
        item["sourceReferences"] = [["sourceID": "test-examples", "recordID": "18"],
                                     ["sourceID": "test-source-2025", "recordID": "18"]]
        item["provenance"] = [
            ["sourceID": "test-source-2025", "recordID": "18", "method": "mapped_from_source",
             "recordedAt": "2026-09-01T00:00:00.000Z", "fields": ["/name", "/access/cost"]],
            ["sourceID": "test-examples", "recordID": "18", "method": "example_data",
             "recordedAt": "2026-09-02T00:00:00.000Z", "fields": ["/coolingDetails"]],
            ["sourceID": "test-source-2025", "recordID": "18", "method": "inferred_from_context",
             "recordedAt": "2026-09-01T00:00:00.000Z", "fields": ["/hours/timeZone"]],
            ["sourceID": "test-source-2025", "recordID": "18", "method": "inferred_from_name",
             "recordedAt": "2026-09-01T00:00:00.000Z", "fields": ["/placeType"]]
        ]
        item["mapReferences"] = [
            ["provider": "apple_maps", "placeID": "test-containing-apple-id",
             "relationship": "within_place", "verification": "reviewed",
             "checkedAt": "2026-09-03T00:00:00.000Z"],
            ["provider": "apple_maps", "placeID": "test-same-apple-id",
             "relationship": "same_place", "verification": "automatic",
             "checkedAt": "2026-09-04T00:00:00.000Z"]
        ]
        var bundledPhoto = makePhoto(id: "test-first-photo")
        bundledPhoto["thumbnailURL"] = "bundle://TestThumbnail.jpg"
        bundledPhoto["imageURL"] = "bundle://TestIllustration.jpg"
        item["photos"] = [makePhoto(id: "test-second-photo"), bundledPhoto]
        return item
    }

    private func makePhoto(id: String) -> [String: Any] {
        ["id": id, "thumbnailURL": "https://example.com/test-thumbnail.jpg",
         "imageURL": "https://example.com/test-image.jpg", "width": 800, "height": 600,
         "caption": "Test photo caption", "capturedAt": "2025-06-01T00:00:00.000Z",
         "publishedAt": "2026-09-02T00:00:00.000Z", "attribution": "Test illustration credit",
         "source": "illustration", "contributionID": "test-contribution"]
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
         "access": makeAccess(), "hours": ["text": "Test hours", "timeZone": "Europe/London"],
         "sourceReferences": [], "provenance": [], "mapReferences": [], "photos": []]
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
