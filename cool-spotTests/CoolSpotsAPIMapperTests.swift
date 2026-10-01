import XCTest
@testable import cool_spot

final class CoolSpotsAPIMapperTests: XCTestCase {
    func testMappingAnEmptyCatalogueDoesNotInsertFixtures() throws {
        let response = try makeResponse(items: [], sources: [])

        XCTAssertTrue(response.makeSpots().isEmpty)
    }

    func testMappingPreservesItemOrderIndependentIdentitiesAndCurrentPlaceFacts() throws {
        let first = makeItem(id: "test-second-cool-spot", name: " Test Current Library ")
        var second = makeItem(id: "test-first-cool-spot", name: "Test Current Garden")
        second["placeID"] = "00000000-0000-4000-8000-000000000002"
        second["location"] = ["latitude": 0.0, "longitude": 0.0]
        second["placeType"] = "park"
        second["setting"] = "outdoors"

        let spots = try makeResponse(items: [first, second]).makeSpots()

        XCTAssertEqual(spots.map(\.id), ["test-second-cool-spot", "test-first-cool-spot"])
        XCTAssertEqual(spots.map(\.placeID), [
            UUID(uuidString: "00000000-0000-4000-8000-000000000001"),
            UUID(uuidString: "00000000-0000-4000-8000-000000000002")
        ])
        let library = try XCTUnwrap(spots.first)
        XCTAssertEqual(library.name, " Test Current Library ")
        XCTAssertEqual(library.address, "Test formatted address")
        XCTAssertEqual(library.latitude, 51.5)
        XCTAssertEqual(library.longitude, -0.1)
        XCTAssertEqual(library.type, .library)
        XCTAssertEqual(library.environment, .indoors)
        let garden = try XCTUnwrap(spots.last)
        XCTAssertEqual(garden.name, "Test Current Garden")
        XCTAssertEqual(garden.latitude, 0)
        XCTAssertEqual(garden.longitude, 0)
        XCTAssertEqual(garden.type, .park)
        XCTAssertEqual(garden.environment, .outdoors)
    }

    func testMappingUsesAddressComponentsWhenFormattedAddressIsAbsentOrEmpty() throws {
        let formattedValues: [Any] = [NSNull(), ""]
        for formatted in formattedValues {
            var item = makeItem()
            item["address"] = [
                "formatted": formatted, "line1": "1 Test Street", "line2": "Test Floor",
                "locality": "Test City", "borough": "Test Borough",
                "postalCode": "TEST 1", "countryCode": "GB"
            ]
            let spot = try firstSpot(item)

            XCTAssertEqual(spot.address, "1 Test Street, Test Floor, Test City, TEST 1")
        }

        var sparse = makeItem()
        sparse["address"] = ["line1": "", "line2": NSNull(), "locality": "Test City"]
        XCTAssertEqual(try firstSpot(sparse).address, "Test City")

        var absent = makeItem()
        absent["address"] = [:]
        XCTAssertEqual(try firstSpot(absent).address, "")
    }

    func testMappingPreservesCoolingAccessAndSupplementalFacts() throws {
        let spot = try firstSpot(makeItem())

        XCTAssertEqual(spot.features, [.airConditioning, .fans, .drinkingWater])
        XCTAssertEqual(spot.access, .free)
        XCTAssertEqual(spot.seating, .limited)
        XCTAssertEqual(spot.entryEligibility, .limited)
        XCTAssertEqual(spot.information.coolingDetails, " Test cooling details ")
        XCTAssertEqual(spot.information.areaDescription, "Test reading area")
        XCTAssertEqual(spot.information.additionalInformation, "Test additional information")
        XCTAssertEqual(spot.information.hours, "Test source hours")
        XCTAssertEqual(spot.information.toilets, .nearby)
        XCTAssertEqual(spot.information.wheelchairAccessible, false)
        XCTAssertEqual(spot.information.staffedWhenOpen, true)
        XCTAssertEqual(spot.information.tables, false)
        XCTAssertEqual(spot.information.drinkingWater, true)
        XCTAssertEqual(spot.information.postedStayLimit, .init(status: .limited, minutes: 45))
        XCTAssertEqual(spot.entryRequirement, "")
        XCTAssertEqual(spot.entryInformation, "")
        XCTAssertNil(spot.publishedRecord)
    }

    func testMappingPreservesAvailabilityCostSeatingEligibilityAndStayLimitStates() throws {
        let answers: [(String, Bool?)] = [("yes", true), ("no", false), ("unknown", nil)]
        for (code, expected) in answers {
            var item = makeItem()
            var access = makeAccess()
            for key in ["wheelchairAccess", "staffedWhenOpen", "tables", "drinkingWater"] {
                access[key] = code
            }
            item["access"] = access
            let spot = try firstSpot(item)

            XCTAssertEqual(spot.information.wheelchairAccessible, expected, code)
            XCTAssertEqual(spot.information.staffedWhenOpen, expected, code)
            XCTAssertEqual(spot.information.tables, expected, code)
            XCTAssertEqual(spot.information.drinkingWater, expected, code)
            XCTAssertEqual(spot.features.contains(.drinkingWater), code == "yes", code)
        }

        let costs: [(String, AccessType)] = [
            ("free", .free), ("purchase_required", .purchase), ("entry_fee", .entryFee), ("unknown", .unsure)
        ]
        for (code, expected) in costs {
            var item = makeItem()
            var access = makeAccess()
            access["cost"] = code
            item["access"] = access
            XCTAssertEqual(try firstSpot(item).access, expected, code)
        }

        let seats: [(String, SeatingType)] = [
            ("yes", .available), ("limited", .limited), ("no", .none), ("unknown", .unsure)
        ]
        for (code, expected) in seats {
            var item = makeItem()
            var access = makeAccess()
            access["seating"] = code
            item["access"] = access
            XCTAssertEqual(try firstSpot(item).seating, expected, code)
        }

        let eligibility: [(String, PlaceEntryEligibility)] = [
            ("everyone", .everyone), ("limited", .limited), ("unknown", .unknown)
        ]
        for (code, expected) in eligibility {
            var item = makeItem()
            var access = makeAccess()
            access["eligibility"] = code
            item["access"] = access
            XCTAssertEqual(try firstSpot(item).entryEligibility, expected, code)
        }

        let limits: [(String, Any, CoolSpotStayLimit)] = [
            ("limited", 45, .init(status: .limited, minutes: 45)),
            ("no_stated_limit", NSNull(), .init(status: .noStatedLimit, minutes: nil)),
            ("unknown", NSNull(), .unknown)
        ]
        for (status, minutes, expected) in limits {
            var item = makeItem()
            var access = makeAccess()
            access["postedStayLimit"] = ["status": status, "minutes": minutes]
            item["access"] = access
            XCTAssertEqual(try firstSpot(item).information.postedStayLimit, expected, status)
        }
    }

    func testMappingLooksUpThePrimaryLinkedSourceWithoutReplacingItsYear() throws {
        var item = makeItem()
        item["sourceReferences"] = [
            ["sourceID": "test-gla", "recordID": "18"],
            ["sourceID": "test-other", "recordID": "18"]
        ]
        let sources = [
            makeSource(id: "test-other", provider: "community", label: "Test other source"),
            makeSource(id: "test-gla", provider: "gla", label: "GLA · 2025")
        ]
        let spot = try XCTUnwrap(makeResponse(items: [item], sources: sources).makeSpots().first)

        XCTAssertEqual(spot.source, .gla)
        XCTAssertEqual(spot.sourceLabel, "GLA · 2025")
        XCTAssertEqual(spot.information.source.url, URL(string: "https://example.com/test-source"))
        XCTAssertFalse(spot.isExample)
    }

    func testMappingPreservesExampleAttributionAndDoesNotClassifyUnknownProvidersAsGLA() throws {
        let cases: [(String, Bool, SpotSource)] = [
            ("community", true, .community), ("community", false, .community), ("future-provider", false, .unknown)
        ]
        for (provider, isExample, expectedSource) in cases {
            let source = makeSource(id: "test-gla", provider: provider,
                                    label: "Test supplied label", isExample: isExample)
            let spot = try XCTUnwrap(makeResponse(items: [makeItem()], sources: [source]).makeSpots().first)

            XCTAssertEqual(spot.source, expectedSource, provider)
            XCTAssertEqual(spot.sourceLabel, "Test supplied label", provider)
            XCTAssertEqual(spot.isExample, isExample, provider)
        }
    }

    func testMappingUnknownFactsDoesNotInventFacilitiesSourceOrVisitorEvidence() throws {
        var item = makeItem()
        item["address"] = [:]
        item["placeType"] = "unknown"
        item["setting"] = "unknown"
        item["coolingFeatures"] = ["unknown"]
        item["coolingDetails"] = NSNull()
        item["additionalInformation"] = NSNull()
        item["hours"] = NSNull()
        item["sourceReferences"] = []
        item["access"] = [
            "cost": "unknown", "eligibility": "unknown", "seating": "unknown", "toilets": "unknown",
            "drinkingWater": "unknown", "wheelchairAccess": "unknown",
            "staffedWhenOpen": "unknown", "tables": "unknown", "areaDescription": NSNull(),
            "postedStayLimit": ["status": "unknown", "minutes": NSNull()]
        ]
        let spot = try firstSpot(item)

        XCTAssertEqual(spot.type, .unknown)
        XCTAssertEqual(spot.environment, .unknown)
        XCTAssertTrue(spot.features.isEmpty)
        XCTAssertEqual(spot.access, .unsure)
        XCTAssertEqual(spot.seating, .unsure)
        XCTAssertEqual(spot.entryEligibility, .unknown)
        XCTAssertNil(spot.information.coolingDetails)
        XCTAssertNil(spot.information.areaDescription)
        XCTAssertNil(spot.information.additionalInformation)
        XCTAssertNil(spot.information.hours)
        XCTAssertEqual(spot.information.toilets, .unknown)
        XCTAssertNil(spot.information.wheelchairAccessible)
        XCTAssertNil(spot.information.staffedWhenOpen)
        XCTAssertNil(spot.information.tables)
        XCTAssertNil(spot.information.drinkingWater)
        XCTAssertEqual(spot.information.postedStayLimit, .unknown)
        XCTAssertEqual(spot.source, .unknown)
        XCTAssertEqual(spot.sourceLabel, "Source unknown")
        XCTAssertFalse(spot.isExample)
        XCTAssertEqual(spot.distance, "")
        XCTAssertEqual(spot.presenceCount, 0)
        XCTAssertTrue(spot.experienceReports.isEmpty)
        XCTAssertEqual(spot.latestReportAt, .distantPast)
        XCTAssertTrue(spot.stayReports.isEmpty)
        XCTAssertTrue(spot.comments.isEmpty)
        XCTAssertFalse(spot.isNearby)
    }

    @MainActor
    func testMappingAcceptedSamePlaceLinksUsesTheVenueIdentityBeforeItsContainingPlace() throws {
        for verification in ["automatic", "reviewed"] {
            var item = makeItem()
            item["mapReferences"] = [
                makeMap(placeID: "IB58D044B3FE1218C", relationship: "within_place"),
                makeMap(placeID: "I7E8561E6022ED614", verification: verification)
            ]
            let spot = try firstSpot(item)

            XCTAssertEqual(spot.applePlaceID, "I7E8561E6022ED614", verification)
            XCTAssertEqual(spot.detailsApplePlaceID, "I7E8561E6022ED614", verification)
            let place = makeRecognisedPlace(appleID: "I7E8561E6022ED614")
            XCTAssertNotNil(place.appleMapItemIdentifier)
            XCTAssertEqual(PrototypeStore(loadedCoolSpots: [spot]).existingSpot(for: place)?.id, spot.id)
        }

        var opaqueItem = makeItem()
        opaqueItem["mapReferences"] = [makeMap(placeID: " test-same-place ")]
        let opaqueSpot = try firstSpot(opaqueItem)
        XCTAssertEqual(opaqueSpot.applePlaceID, " test-same-place ")
        XCTAssertEqual(opaqueSpot.detailsApplePlaceID, " test-same-place ")
    }

    @MainActor
    func testMappingWithinPlaceLinksAllowsParentDiscoveryWithoutMergingIdentities() throws {
        var item = makeItem(name: "Test Cooling Lobby")
        item["mapReferences"] = [makeMap(placeID: "IB58D044B3FE1218C", relationship: "within_place")]
        let spot = try firstSpot(item)
        let store = PrototypeStore(loadedCoolSpots: [spot])
        let parent = makeRecognisedPlace(appleID: "IB58D044B3FE1218C")

        XCTAssertNotNil(parent.appleMapItemIdentifier)
        XCTAssertNil(spot.applePlaceID)
        XCTAssertEqual(spot.detailsApplePlaceID, "IB58D044B3FE1218C")
        XCTAssertNil(store.existingSpot(for: parent))
        XCTAssertEqual(store.searchCoolSpots(query: parent.name, including: [parent]).map(\.id), [spot.id])
        XCTAssertTrue(store.searchCoolSpots(query: parent.name, including: []).isEmpty)
    }

    func testMappingDoesNotUseUnacceptedUnsupportedOrBlankMapLinksButPreservesTheirMetadata() throws {
        let links = [
            makeMap(verification: "pending"), makeMap(verification: "rejected"),
            makeMap(verification: "future-verification"), makeMap(provider: "future-provider"),
            makeMap(relationship: "nearby"), makeMap(relationship: "future-relationship"),
            makeMap(placeID: ""), makeMap(placeID: " \n\t ")
        ]
        for link in links {
            var item = makeItem()
            item["mapReferences"] = [link]
            let response = try makeResponse(items: [item])
            let spot = try XCTUnwrap(response.makeSpots().first)

            XCTAssertNil(spot.applePlaceID, String(describing: link))
            XCTAssertNil(spot.detailsApplePlaceID, String(describing: link))
            let record = try XCTUnwrap(spot.apiRecord)
            XCTAssertEqual(record.item.mapReferences, response.items[0].mapReferences)
        }
    }

    func testMappingRetainsThePublicItemAndOnlyItsLinkedSourceContextWithoutReplacingDates() throws {
        var item = makeItem()
        item["address"] = ["line1": "Test Street", "borough": "Test Borough", "countryCode": "GB"]
        item["sourceReferences"] = [
            ["sourceID": "test-gla", "recordID": "18"],
            ["sourceID": "test-other", "recordID": "18"],
            ["sourceID": "test-gla", "recordID": "19"]
        ]
        item["provenance"] = [
            ["sourceID": "test-gla", "recordID": "18", "method": "mapped_from_source",
             "recordedAt": "2025-06-01T09:00:00Z", "fields": ["/name", "/access/drinkingWater"]],
            ["sourceID": "test-other", "recordID": "18", "method": "future-method",
             "recordedAt": NSNull(), "fields": ["/address/borough"]]
        ]
        var gla = makeSource(id: "test-gla", provider: "gla", label: "GLA · 2025")
        gla["dataset"] = "Test 2025 dataset"
        gla["downloadURL"] = "https://example.com/test-2025.csv"
        gla["retrievedAt"] = "2025-06-02T09:00:00Z"
        gla["sourceUpdatedAt"] = "2025-06-01T09:00:00Z"
        gla["sha256"] = String(repeating: "a", count: 64)
        let other = makeSource(id: "test-other", provider: "future-provider", label: "Test other source")
        let unrelated = makeSource(id: "test-unrelated", provider: "community", label: "Test unrelated source")
        let response = try makeResponse(items: [item], sources: [unrelated, other, gla])
        let spot = try XCTUnwrap(response.makeSpots().first)
        let record = try XCTUnwrap(spot.apiRecord)

        XCTAssertEqual(record.schemaVersion, 5)
        XCTAssertEqual(record.datasetID, "test-catalogue")
        XCTAssertEqual(record.generatedAt, "2026-10-01T12:00:00.000Z")
        XCTAssertEqual(record.sources, [response.sources[2], response.sources[1]])
        XCTAssertEqual(record.item, response.items[0])
        XCTAssertEqual(record.item.hours?.timeZone, "Europe/London")
        XCTAssertEqual(record.item.provenance[0].recordedAt, "2025-06-01T09:00:00Z")
        XCTAssertNil(record.item.provenance[1].recordedAt)
        XCTAssertNil(spot.publishedRecord)
    }

    func testMappingPublishedHTTPSPhotosPreservesOrderAndMetadataWithoutInventingAReport() throws {
        var item = makeItem()
        var second = makePhoto(id: "test-second-photo")
        second["caption"] = "Test source caption"
        second["capturedAt"] = "2025-06-01T09:00:00Z"
        second["publishedAt"] = "2025-06-02T09:00:00Z"
        second["contributionID"] = "test-contribution"
        item["photos"] = [second, makePhoto(id: "test-first-photo")]
        let response = try makeResponse(items: [item])
        let spot = try XCTUnwrap(response.makeSpots().first)

        XCTAssertEqual(spot.photos, response.items[0].photos)
        XCTAssertEqual(spot.photos.map(\.id), ["test-second-photo", "test-first-photo"])
        let photo = try XCTUnwrap(spot.photos.first)
        XCTAssertEqual(photo.caption, "Test source caption")
        XCTAssertEqual(photo.capturedAt, "2025-06-01T09:00:00Z")
        XCTAssertEqual(photo.publishedAt, "2025-06-02T09:00:00Z")
        XCTAssertEqual(photo.attribution, "Test public attribution")
        XCTAssertEqual(photo.source, "community")
        XCTAssertEqual(photo.contributionID, "test-contribution")
        let last = try XCTUnwrap(spot.photos.last)
        XCTAssertNil(last.caption)
        XCTAssertNil(last.capturedAt)
        XCTAssertNil(last.publishedAt)
        XCTAssertNil(last.contributionID)
        XCTAssertTrue(spot.comments.isEmpty)
        XCTAssertTrue(spot.experienceReports.isEmpty)
    }

    func testMappingFiltersUnusableAndDeviceLocalPhotosWhileKeepingPublicMetadata() throws {
        var item = makeItem()
        var emptyID = makePhoto(id: "")
        emptyID["caption"] = "Test rejected display metadata"
        var zeroWidth = makePhoto(id: "test-zero-width")
        zeroWidth["width"] = 0
        var negativeHeight = makePhoto(id: "test-negative-height")
        negativeHeight["height"] = -1
        var insecureThumbnail = makePhoto(id: "test-http-thumbnail")
        insecureThumbnail["thumbnailURL"] = "http://example.com/test-thumb.jpg"
        var localImage = makePhoto(id: "test-local-image")
        localImage["imageURL"] = "prototype-photo://00000000-0000-4000-8000-000000000003/image.jpg"
        var localThumbnail = makePhoto(id: "test-local-thumbnail")
        localThumbnail["thumbnailURL"] = "prototype-photo://00000000-0000-4000-8000-000000000003/thumb.jpg"
        var fileImage = makePhoto(id: "test-file-image")
        fileImage["imageURL"] = "file:///test-photo.jpg"
        item["photos"] = [emptyID, zeroWidth, makePhoto(id: "test-valid"), negativeHeight,
                          insecureThumbnail, localImage, localThumbnail, fileImage]
        let response = try makeResponse(items: [item])
        let spot = try XCTUnwrap(response.makeSpots().first)

        XCTAssertEqual(spot.photos.map(\.id), ["test-valid"])
        let record = try XCTUnwrap(spot.apiRecord)
        XCTAssertEqual(record.item.photos, response.items[0].photos)
    }

    func testMappingBundlePhotosRequiresBothAnExampleSourceAndIllustrationAttribution() throws {
        for (isExample, photoSource, expectedIDs) in [
            (true, "illustration", ["test-bundle"]),
            (false, "illustration", []),
            (true, "community", [])
        ] {
            var item = makeItem()
            var photo = makePhoto(id: "test-bundle")
            photo["thumbnailURL"] = "bundle://TestIllustration.png"
            photo["imageURL"] = "bundle://TestIllustration.png"
            photo["source"] = photoSource
            item["photos"] = [photo]
            let source = makeSource(id: "test-gla", provider: "community", label: "Test source", isExample: isExample)
            let spot = try XCTUnwrap(makeResponse(items: [item], sources: [source]).makeSpots().first)

            XCTAssertEqual(spot.photos.map(\.id), expectedIDs, "example=\(isExample), source=\(photoSource)")
            XCTAssertEqual(try XCTUnwrap(spot.apiRecord).item.photos.count, 1)
        }
    }

    func testMappingEmptyRelationsKeepsUnknownMetadataWithoutAddingFixturesOrLegacyRecords() throws {
        var item = makeItem()
        item["sourceReferences"] = []
        item["hours"] = NSNull()
        let response = try makeResponse(items: [item])
        let spot = try XCTUnwrap(response.makeSpots().first)
        let record = try XCTUnwrap(spot.apiRecord)

        XCTAssertTrue(record.sources.isEmpty)
        XCTAssertEqual(record.item, response.items[0])
        XCTAssertNil(record.item.hours)
        XCTAssertTrue(record.item.provenance.isEmpty)
        XCTAssertNil(spot.applePlaceID)
        XCTAssertNil(spot.detailsApplePlaceID)
        XCTAssertTrue(spot.photos.isEmpty)
        XCTAssertNil(spot.publishedRecord)
    }

    private func makeMap(placeID: String = "test-apple-place", provider: String = "apple_maps",
                         relationship: String = "same_place", verification: String = "reviewed") -> [String: Any] {
        ["provider": provider, "placeID": placeID, "relationship": relationship,
         "verification": verification, "checkedAt": "2025-06-01T09:00:00Z"]
    }

    private func makePhoto(id: String) -> [String: Any] {
        ["id": id, "thumbnailURL": "https://example.com/test-thumb.jpg",
         "imageURL": "https://example.com/test-image.jpg", "width": 640, "height": 480,
         "caption": NSNull(), "capturedAt": NSNull(), "publishedAt": NSNull(),
         "attribution": "Test public attribution", "source": "community", "contributionID": NSNull()]
    }

    private func makeRecognisedPlace(appleID: String) -> RecognisedPlace {
        .init(id: "apple-maps:\(appleID)", name: "Test Parent Venue", address: "",
              latitude: 51.5, longitude: -0.1, type: .library, distance: "")
    }

    private func firstSpot(_ item: [String: Any]) throws -> CoolSpot {
        try XCTUnwrap(makeResponse(items: [item]).makeSpots().first)
    }

    private func makeItem(id: String = "test-cool-spot", name: String = "Test Library") -> [String: Any] {
        ["id": id, "placeID": "00000000-0000-4000-8000-000000000001", "name": name,
         "location": ["latitude": 51.5, "longitude": -0.1],
         "address": ["formatted": "Test formatted address"], "placeType": "library", "setting": "indoors",
         "coolingFeatures": ["air_conditioning", "fans"], "coolingDetails": " Test cooling details ",
         "additionalInformation": "Test additional information", "access": makeAccess(),
         "hours": ["text": "Test source hours", "timeZone": "Europe/London"],
         "sourceReferences": [["sourceID": "test-gla", "recordID": "18"]],
         "provenance": [], "mapReferences": [], "photos": []]
    }

    private func makeAccess() -> [String: Any] {
        ["cost": "free", "eligibility": "limited", "seating": "limited", "toilets": "nearby",
         "drinkingWater": "yes", "wheelchairAccess": "no", "staffedWhenOpen": "yes", "tables": "no",
         "areaDescription": "Test reading area", "postedStayLimit": ["status": "limited", "minutes": 45]]
    }

    private func makeSource(id: String, provider: String, label: String,
                            isExample: Bool = false) -> [String: Any] {
        ["id": id, "provider": provider, "label": label,
         "url": "https://example.com/test-source", "isExample": isExample]
    }

    private func makeResponse(items: [[String: Any]], sources: [[String: Any]]? = nil) throws -> CoolSpotsAPIResponse {
        let payload: [String: Any] = [
            "schemaVersion": 5, "datasetID": "test-catalogue", "generatedAt": "2026-10-01T12:00:00.000Z",
            "sources": sources ?? [makeSource(id: "test-gla", provider: "gla", label: "GLA · 2025")],
            "items": items
        ]
        return try CoolSpotsAPIResponse.decode(JSONSerialization.data(withJSONObject: payload))
    }
}
