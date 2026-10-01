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
