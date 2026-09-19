import XCTest
import SwiftUI
import MapKit
@testable import cool_spot

@MainActor
final class CoolSpotTests: XCTestCase {

    func testReviewedCommunityContributionPreservesAnswersPhotosAndIdentityAcrossRelaunch() throws {
        let suite = "publication-test-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var store = PrototypeStore.catalogStore(reportDefaults: defaults)
        var draft = PlaceContributionDraft(kind: .unlisted, anchor: .init(latitude: 51.48, longitude: -0.15))
        draft.values.name = "TEST Cooling room"
        draft.values.locationConfirmed = true
        draft.values.setting = .indoors
        draft.values.type = .other
        draft.values.features = [.fans, .waterFeature, .drinkingWater]
        draft.values.seating = .limited
        draft.values.toilets = .nearby
        draft.values.staffedWhenOpen = .no
        draft.values.wheelchairAccess = .no
        draft.values.tables = .yes
        draft.values.access = .purchase
        draft.values.entryEligibility = .limited
        draft.values.locationDetails = "Room beside reception"
        draft.values.stayLimit = "No stated limit"
        draft.values.note = "Ask staff for a drinking glass."
        draft.values.sourceCorrection = "Private review reason"
        draft.values.photo = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).pngData { context in
            UIColor.green.setFill(); context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
        let originalCount = store.spots.count
        XCTAssertTrue(store.submitPlaceContribution(draft))
        let photoID = try XCTUnwrap(store.contributions.first?.photoID)
        defer { try? FileManager.default.removeItem(at: PrototypePhotoStorage.directory.appendingPathComponent(photoID)) }
        XCTAssertEqual(store.spots.count, originalCount, "Pending facts and photos must not become public.")
        store = PrototypeStore.catalogStore(reportDefaults: defaults)
        XCTAssertEqual(store.contributions.first?.id, draft.id)
        XCTAssertEqual(store.contributions.first?.status, .inReview)
        XCTAssertNotNil(store.contributions.first?.placeDraft?.values.photo)
        XCTAssertTrue(store.publishContribution(draft.id), store.contributionError ?? "")
        XCTAssertTrue(store.publishContribution(draft.id), "Publishing twice must be idempotent.")
        store = PrototypeStore.catalogStore(reportDefaults: defaults)
        let spot = try XCTUnwrap(store.spot(draft.id.uuidString))
        XCTAssertEqual(store.spots.count, originalCount + 1)
        XCTAssertEqual(spot.features, [.fans, .waterFeature, .drinkingWater])
        XCTAssertEqual(spot.seating, .limited)
        XCTAssertEqual(spot.type, .other)
        XCTAssertEqual(spot.information.toilets, .nearby)
        XCTAssertEqual(spot.information.staffedWhenOpen, false)
        XCTAssertEqual(spot.information.wheelchairAccessible, false)
        XCTAssertEqual(spot.information.tables, true)
        XCTAssertEqual(spot.information.postedStayLimit.status, .noStatedLimit)
        XCTAssertEqual(spot.information.additionalInformation, draft.values.note)
        XCTAssertEqual(spot.photos.count, 1)
        XCTAssertEqual(spot.photos.first?.contributionID, draft.id.uuidString)
        XCTAssertNotNil(UIImage(contentsOfFile: try XCTUnwrap(PrototypePhotoStorage.fileURL(for: spot.photos[0].imageURL)).path))
        XCTAssertEqual(store.contributions.first?.status, .published)
        XCTAssertTrue(store.visitReports.isEmpty)
        XCTAssertTrue(store.visitConfirmedAt.isEmpty)
        XCTAssertNil(store.activePresenceSpotID)
        let item = try XCTUnwrap(spot.catalogueItem)
        let data = try JSONEncoder().encode(item)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("Private review reason"))
        XCTAssertTrue(json["hours"] is NSNull)
        let address = try XCTUnwrap(json["address"] as? [String: Any])
        XCTAssertTrue(address["countryCode"] is NSNull, "An unmatched coordinate must not invent a London address.")
        let access = try XCTUnwrap(json["access"] as? [String: Any])
        XCTAssertNil(access["instructions"])
        XCTAssertNil(access["postedStayLimitMinutes"])
        let reopened = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        XCTAssertEqual(reopened.values.stayLimit, "No stated limit")
        XCTAssertEqual(reopened.values.note, draft.values.note)
        XCTAssertEqual(reopened.values.toilets, .nearby)
        XCTAssertFalse(reopened.isDirty)
        // Export the actual Swift-produced record so the independent JSON Schema validator can inspect it.
        try data.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("coolspot-publication-contract.json"))
    }

    func testReviewedEditsPatchOnlyChangedGLAFactsAndKeepFieldLevelEvidence() throws {
        let store = PrototypeStore.catalogStore(reportDefaults: nil)
        let spot = try XCTUnwrap(store.spots.first { $0.name == "Canning Town Library" })
        let original = try XCTUnwrap(spot.catalogueItem)
        var first = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        first.values.tables = .yes
        var second = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        second.values.staffedWhenOpen = .no
        XCTAssertTrue(store.submitPlaceContribution(first))
        XCTAssertTrue(store.submitPlaceContribution(second))
        XCTAssertTrue(store.publishContribution(first.id))
        XCTAssertTrue(store.publishContribution(second.id), store.contributionError ?? "")
        let updated = try XCTUnwrap(store.spot(spot.id)?.catalogueItem)
        XCTAssertEqual(store.spot(spot.id)?.sourceLabel, "GLA · 2025 · Local edits")
        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.hours, original.hours)
        XCTAssertEqual(updated.address, original.address)
        XCTAssertEqual(updated.mapReferences, original.mapReferences)
        XCTAssertEqual(updated.access.tables, .yes)
        XCTAssertEqual(updated.access.staffedWhenOpen, .no)
        XCTAssertEqual(updated.access.drinkingWater, original.access.drinkingWater)
        let evidence = try XCTUnwrap(updated.provenance)
        XCTAssertEqual(evidence.first { $0.recordID == first.id.uuidString }?.fields, ["/access/tables"])
        XCTAssertEqual(evidence.first { $0.recordID == second.id.uuidString }?.fields, ["/access/staffedWhenOpen"])
        XCTAssertFalse(evidence.filter { $0.sourceID == "gla-cool-spaces-2025" }.flatMap(\.fields).contains("/access/staffedWhenOpen"))
    }

    func testConflictingReviewedEditsDoNotSilentlyOverwritePublishedFacts() throws {
        let store = PrototypeStore.catalogStore(reportDefaults: nil)
        let spot = try XCTUnwrap(store.spots.first)
        var first = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        var second = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        first.values.access = .purchase
        second.values.access = .entryFee
        XCTAssertTrue(store.submitPlaceContribution(first))
        XCTAssertTrue(store.submitPlaceContribution(second))
        XCTAssertTrue(store.publishContribution(first.id))
        XCTAssertFalse(store.publishContribution(second.id))
        XCTAssertEqual(store.spot(spot.id)?.access, .purchase)
        XCTAssertNotNil(store.contributionError)
        guard case .actionNeeded = store.contributions.first(where: { $0.id == second.id })?.status else {
            return XCTFail("A conflict must remain visible for review.")
        }
    }

    func testUnchangedNegativeWaterFactSurvivesOtherFeatureEdits() throws {
        var item = try XCTUnwrap(PrototypeCatalog.bundled().items.first)
        item.access.drinkingWater = .no
        let spot = item.makeSpot()
        let store = PrototypeStore(catalogSpots: [spot])
        var draft = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        draft.values.features.insert(.waterFeature)
        XCTAssertTrue(store.submitPlaceContribution(draft))
        XCTAssertTrue(store.publishContribution(draft.id))
        XCTAssertEqual(store.spot(spot.id)?.information.drinkingWater, false)
        XCTAssertEqual(store.spot(spot.id)?.catalogueItem?.access.drinkingWater, .no)
    }

    func testAreaDescriptionDoesNotSplitTheSelectedVenueIdentity() throws {
        let place = RecognisedPlace(id: "apple-maps:I7E8561E6022ED614", name: "Example building", address: "Example address",
                                    latitude: 51.48, longitude: -0.15, type: .unknown, distance: "", hasTrustedType: false)
        let store = PrototypeStore(catalogSpots: [])
        var draft = PlaceContributionDraft(kind: .recognised, anchor: place.coordinate, place: place)
        draft.values.setting = .indoors
        draft.values.features = [.fans]
        draft.values.locationDetails = "Room on the upper floor"
        XCTAssertTrue(store.submitPlaceContribution(draft))
        XCTAssertTrue(store.publishContribution(draft.id), store.contributionError ?? "")
        let spot = try XCTUnwrap(store.spot(draft.id.uuidString))
        XCTAssertEqual(spot.applePlaceID, "I7E8561E6022ED614")
        XCTAssertEqual(spot.detailsApplePlaceID, "I7E8561E6022ED614")
        XCTAssertEqual(spot.catalogueItem?.location.scope, .venue)
        XCTAssertEqual(spot.type, .unknown)
        XCTAssertEqual(store.existingSpot(for: place)?.id, spot.id, "Area text must not cause duplicate search results for the selected venue.")
    }

    func testExplicitAreaRelationshipUsesParentDetailsWithoutAliasingItsIdentity() throws {
        var item = try XCTUnwrap(PrototypeCatalog.bundled().items.first { $0.matchedAppleID != nil })
        let parentID = try XCTUnwrap(item.matchedAppleID)
        item.location.scope = .specificArea
        item.mapReferences?[0].relationship = "within_place"
        let spot = item.makeSpot()
        XCTAssertNil(spot.applePlaceID)
        XCTAssertEqual(spot.detailsApplePlaceID, parentID)
        let parent = RecognisedPlace(id: "apple-maps:\(parentID)", name: item.name, address: item.address.display,
                                     latitude: item.location.latitude, longitude: item.location.longitude, type: .library, distance: "")
        XCTAssertNil(PrototypeStore(catalogSpots: [spot]).existingSpot(for: parent))
    }

    func testStayLimitPreservesNoStatedLimitAndCustomDurationWithoutInventingUnknownValues() throws {
        for minutes in [1, 30, 60, 95, 120, 1499] {
            let value = CatalogStayLimit(status: .limited, minutes: minutes)
            XCTAssertEqual(try CatalogStayLimit.fromForm(value.formValue), value)
        }
        XCTAssertEqual(try CatalogStayLimit.fromForm("No stated limit").status, .noStatedLimit)
        XCTAssertEqual(try CatalogStayLimit.fromForm("Not sure"), .unknown)
        XCTAssertEqual(try CatalogStayLimit.fromForm(""), .unknown)
        XCTAssertThrowsError(try CatalogStayLimit.fromForm("0 hr 0 min"))
        XCTAssertThrowsError(try CatalogStayLimit.fromForm("invalid"))
    }

    func testLegacyCatalogueAccessAliasesStillReadButEncodeOnlyCurrentNames() throws {
        let item = try XCTUnwrap(PrototypeCatalog.bundled().items.first)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(item)) as? [String: Any])
        var access = try XCTUnwrap(json["access"] as? [String: Any])
        access.removeValue(forKey: "postedStayLimit")
        access.removeValue(forKey: "areaDescription")
        access["postedStayLimitMinutes"] = 60
        access["instructions"] = "Reading room"
        json["access"] = access
        let decoded = try JSONDecoder().decode(PrototypeCatalog.Item.self, from: JSONSerialization.data(withJSONObject: json))
        let spot = decoded.makeSpot()
        XCTAssertEqual(spot.information.areaDescription, "Reading room")
        XCTAssertEqual(spot.information.postedStayLimit.minutes, 60)
        XCTAssertEqual(PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot).values.stayLimit, "1 hour")
        let encoded = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(decoded)) as? [String: Any])
        let newAccess = try XCTUnwrap(encoded["access"] as? [String: Any])
        XCTAssertEqual(newAccess["areaDescription"] as? String, "Reading room")
        XCTAssertNil(newAccess["instructions"])
        XCTAssertNil(newAccess["postedStayLimitMinutes"])
    }


    func testCatalogueSourceAdaptsCommunityWithoutRequiringGLADatasetMetadata() throws {
        let source = try JSONDecoder().decode(PrototypeCatalog.CatalogueSource.self,
            from: Data(#"{"id":"community","provider":"community","label":"Community reports"}"#.utf8))
        let item = try XCTUnwrap(PrototypeCatalog.bundled().items.first)
        let community = item.makeSpot(catalogueSource: source)
        XCTAssertEqual(community.source, .community)
        XCTAssertEqual(community.sourceLabel, "Community reports")
        XCTAssertNil(community.information.source.url)
        let future = item.makeSpot(catalogueSource: .init(id: "future", provider: "future_provider", label: "New source", url: nil))
        XCTAssertEqual(future.source, .unknown)
        XCTAssertEqual(future.sourceLabel, "New source")
    }

    func testCatalogueKeepsExistingSourceIDsAndOnlyPublishesAcceptedMapLinks() throws {
        let catalogue = try PrototypeCatalog.bundled()
        let canning = try XCTUnwrap(catalogue.items.first { $0.name == "Canning Town Library" })
        XCTAssertEqual(canning.id, "5873b0cb-25d4-43a8-93a8-d9ced4c8d3ab")
        let john = try XCTUnwrap(catalogue.items.first { $0.name == "John Harvard Library" })
        XCTAssertEqual(john.id, "244e6c13-f305-4aab-ae17-af70fe562470")
        XCTAssertTrue(catalogue.items.allSatisfy { $0.photos?.isEmpty == true })
        let url = try XCTUnwrap(Bundle.main.url(forResource: "CoolSpotCatalog.prototype", withExtension: "json"))
        var response = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        var item = try XCTUnwrap((response["items"] as? [[String: Any]])?.first)
        item["mapReferences"] = [["provider": "apple_maps", "placeID": "pending-id", "relationship": "same_place", "verification": "pending"]]
        response["items"] = [item]
        let decoded = try PrototypeCatalog.decode(JSONSerialization.data(withJSONObject: response))
        XCTAssertNil(decoded.items.first?.matchedAppleID)
    }

    func testPhotosDecodeForExampleWithoutInventingPhotosForImportedPlaces() throws {
        let store = PrototypeStore.catalogStore(reportDefaults: nil)
        let room = try XCTUnwrap(store.spots.first { $0.name == "Example Community Room" })
        XCTAssertEqual(room.photos.count, 3)
        XCTAssertEqual(Set(room.photos.map(\.id)).count, 3)
        XCTAssertTrue(room.photos.allSatisfy { $0.source == "illustration" && $0.isDisplayable && $0.capturedAt == nil })
        for photo in room.photos {
            let filename = try XCTUnwrap(photo.imageURL.host)
            let url = try XCTUnwrap(Bundle.main.url(forResource: (filename as NSString).deletingPathExtension,
                                                     withExtension: (filename as NSString).pathExtension))
            XCTAssertNotNil(UIImage(data: try Data(contentsOf: url)))
        }
        XCTAssertTrue(store.spots.filter { !$0.isExample }.allSatisfy { $0.photos.isEmpty })

        let url = try XCTUnwrap(Bundle.main.url(forResource: "CoolSpotCatalog.prototype", withExtension: "json"))
        var response = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        var item = try XCTUnwrap((response["items"] as? [[String: Any]])?.first)
        item["photos"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(room.photos))
        response["items"] = [item]
        let decoded = try PrototypeCatalog.decode(JSONSerialization.data(withJSONObject: response))
        XCTAssertEqual(decoded.items.first?.makeSpot().photos, room.photos)
    }

    func testCatalogMakesAllThreePlaceStatesSearchableAndLinksCommunityIdentity() throws {
        let store = PrototypeStore.catalogStore(reportDefaults: nil)
        let gla = try XCTUnwrap(store.searchCoolSpots(query: "Canning Town Library", including: []).first)
        let community = try XCTUnwrap(store.searchCoolSpots(query: "Tate Modern", including: []).first)
        let ordinary = try XCTUnwrap(PlaceSearchResults.matching(store.recognisedPlaces, query: "British Museum").first)
        XCTAssertEqual(store.spots.count, 253)
        XCTAssertFalse(gla.isExample)
        XCTAssertNotNil(gla.information.hours)
        XCTAssertTrue(community.isExample)
        XCTAssertEqual(community.source, .community)
        XCTAssertNil(community.information.hours)
        XCTAssertTrue(community.information.hasFacilities)
        XCTAssertNil(store.existingSpot(for: ordinary))
        let apple = RecognisedPlace(id: "apple-maps:\(try XCTUnwrap(community.applePlaceID))",
                                    name: "Tate Modern", address: community.address,
                                    latitude: community.latitude, longitude: community.longitude,
                                    type: .culture, distance: "")
        XCTAssertEqual(store.existingSpot(for: apple)?.id, community.id)
        XCTAssertEqual(store.searchCoolSpots(query: "Tate Modern", including: [apple]).count, 1)
        XCTAssertEqual(store.visitorReportItems(for: community).count, 3)
    }

    func testCommunityExamplesKeepPublishedFactsAndVisitorEvidenceSeparateFromPersonalData() throws {
        let store = PrototypeStore.catalogStore(reportDefaults: nil)
        let examples = store.spots.filter(\.isExample)
        XCTAssertEqual(examples.count, 3)
        for spot in examples {
            let items = store.visitorReportItems(for: spot)
            XCTAssertTrue(items.allSatisfy(\.isExample))
            XCTAssertEqual(store.experienceReportTotal(for: spot), items.count)
            XCTAssertEqual(store.latestReportDate(for: spot), items.compactMap { $0.report?.visitedAt }.max())
            for experience in CoolingExperience.allCases {
                XCTAssertEqual(store.experienceCounts(for: spot)[experience, default: 0],
                               items.filter { $0.report?.experience == experience }.count)
            }
            XCTAssertFalse(spot.isNearby, "Example reports must not confirm that the current user is nearby.")
        }
        let room = try XCTUnwrap(examples.first { $0.name == "Example Community Room" })
        XCTAssertEqual(room.information.toilets, .none)
        XCTAssertEqual(room.information.wheelchairAccessible, false)
        let garden = try XCTUnwrap(examples.first { $0.name == "Example Shaded Garden" })
        XCTAssertEqual(garden.information.toilets, .unknown)
        XCTAssertNil(garden.information.tables)
        XCTAssertEqual(garden.information.staffedWhenOpen, false)
        XCTAssertTrue(store.visitReports.isEmpty)
        XCTAssertTrue(store.reportDrafts.isEmpty)
        XCTAssertTrue(store.visitConfirmedAt.isEmpty)
        XCTAssertTrue(store.savedLocations.isEmpty)
        XCTAssertTrue(store.contributions.isEmpty)
    }

    func testCatalogPresenceChangesOnlyAfterNearbySharingAndExpires() throws {
        let store = PrototypeStore.catalogStore(reportDefaults: nil)
        var spot = try XCTUnwrap(store.searchCoolSpots(query: "Tate Modern", including: []).first)
        let start = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(store.presence(for: spot, at: start), 0)
        store.checkIn(spot, at: start)
        XCTAssertEqual(store.presence(for: spot, at: start), 0)
        spot.isNearby = true
        store.checkIn(spot, at: start)
        XCTAssertEqual(store.presence(for: spot, at: start), 1)
        XCTAssertEqual(store.presence(for: spot, at: start.addingTimeInterval(599)), 1)
        store.endExpiredPresence(at: start.addingTimeInterval(600))
        XCTAssertEqual(store.presence(for: spot, at: start.addingTimeInterval(600)), 0)
        XCTAssertEqual(store.experienceReportTotal(for: spot), 3, "Sharing presence must not add a visit report.")
    }

    func testOptionalFacilitiesDecodeWithoutInventingMissingOrFutureValues() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "CoolSpotCatalog.prototype", withExtension: "json"))
        var response = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        var items = try XCTUnwrap(response["items"] as? [[String: Any]])
        let sourceAccess = try XCTUnwrap(items[0]["access"] as? [String: Any])
        let cases: [(String?, Bool?)] = [(nil, nil), ("unknown", nil), ("future_code", nil), ("yes", true), ("no", false)]
        for (value, expected) in cases {
            var access = sourceAccess
            access["staffedWhenOpen"] = value
            items[0]["access"] = access
            response["items"] = items
            let catalog = try PrototypeCatalog.decode(JSONSerialization.data(withJSONObject: response))
            XCTAssertEqual(catalog.items[0].makeSpot().information.staffedWhenOpen, expected)
        }
    }

    func testPlaceFactCorrectionsPreserveSourceFactsUntilReview() throws {
        let store = PrototypeStore.catalogStore(reportDefaults: nil)
        let spot = try XCTUnwrap(store.searchCoolSpots(query: "John Harvard Library", including: []).first)
        var draft = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        XCTAssertEqual(draft.values.wheelchairAccess, .yes)
        XCTAssertEqual(draft.values.staffedWhenOpen, .yes)
        XCTAssertEqual(draft.values.toilets, .onSite)
        XCTAssertFalse(draft.isDirty)
        draft.values.staffedWhenOpen = .no
        XCTAssertTrue(draft.canSend)
        XCTAssertTrue(store.submitPlaceContribution(draft))
        XCTAssertEqual(store.contributions.first?.status, .inReview)
        XCTAssertEqual(store.contributions.first?.placeDraft?.values.staffedWhenOpen, .no)
        XCTAssertEqual(store.spot(spot.id)?.information.staffedWhenOpen, true)
        XCTAssertEqual(store.spot(spot.id)?.information.hours, spot.information.hours)
        XCTAssertTrue(store.visitorReportItems(for: spot).isEmpty)

        var proposal = PlaceContributionDraft(kind: .recognised, anchor: spot.coordinate)
        proposal.values.wheelchairAccess = .no
        let reconciled = proposal.reconciled(with: spot)
        XCTAssertEqual(reconciled.values.wheelchairAccess, .no)
        XCTAssertEqual(reconciled.values.staffedWhenOpen, .yes)
        XCTAssertEqual(reconciled.values.toilets, .onSite)
    }

    func testCatalogLoadsAllSourcePlacesWithoutFabricatingVisitorEvidence() throws {
        let catalog = try PrototypeCatalog.bundled()
        let store = PrototypeStore(catalogSpots: catalog.items.map { $0.makeSpot() })
        XCTAssertEqual(store.spots.count, 250)
        XCTAssertEqual(Set(store.spots.map(\.id)).count, 250)
        XCTAssertTrue(store.spots.allSatisfy { !$0.isExample && !$0.features.isEmpty })
        for spot in store.spots {
            XCTAssertEqual(store.experienceReportTotal(for: spot), 0)
            XCTAssertEqual(store.presence(for: spot), 0)
            XCTAssertNil(store.latestReportDate(for: spot))
            XCTAssertTrue(store.visitorReportItems(for: spot).isEmpty)
        }
        XCTAssertNotNil(store.spot("library"), "Previously saved examples remain readable.")
        XCTAssertFalse(store.spots.contains { $0.id == "library" })
    }

    func testCatalogResolvesAppleAliasesOnceWithoutMergingByProximityOrName() throws {
        let item = try XCTUnwrap(PrototypeCatalog.bundled().items.first { $0.matchedAppleID != nil })
        let store = PrototypeStore(catalogSpots: [item.makeSpot()])
        var apple = RecognisedPlace(id: "apple-maps:different-id", name: "Provider alias", address: "",
                                    latitude: item.location.latitude, longitude: item.location.longitude,
                                    type: .library, distance: "")
        XCTAssertNil(store.existingSpot(for: apple))
        apple.alternateApplePlaceIDs = [try XCTUnwrap(item.matchedAppleID)]
        XCTAssertEqual(store.existingSpot(for: apple)?.id, item.id)
        XCTAssertEqual(store.searchCoolSpots(query: "Provider alias", including: [apple, apple]).map(\.id), [item.id])
    }

    func testCatalogUnknownCodesStayUnknownAndUnsupportedVersionsFail() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "CoolSpotCatalog.prototype", withExtension: "json"))
        var response = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        var items = try XCTUnwrap(response["items"] as? [[String: Any]])
        var access = try XCTUnwrap(items[0]["access"] as? [String: Any])
        access["seating"] = "new_unknown_code"
        items[0]["access"] = access
        items[0]["coolingFeatures"] = ["new_cooling_feature"]
        response["items"] = items
        let catalog = try PrototypeCatalog.decode(JSONSerialization.data(withJSONObject: response))
        XCTAssertEqual(catalog.items[0].makeSpot().seating, .unsure)
        XCTAssertEqual(catalog.items[0].makeSpot().features, [.drinkingWater])
        response["schemaVersion"] = 999
        XCTAssertThrowsError(try PrototypeCatalog.decode(JSONSerialization.data(withJSONObject: response)))
    }

    func testCatalogPreservesAnExistingAppleBookmarkAndKeepsReportsOnOurIdentity() throws {
        let suite = "catalog-test-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let item = try XCTUnwrap(PrototypeCatalog.bundled().items.first { $0.matchedAppleID != nil })
        let apple = RecognisedPlace(id: "apple-maps:\(try XCTUnwrap(item.matchedAppleID))", name: item.name,
                                    address: item.address.display, latitude: item.location.latitude,
                                    longitude: item.location.longitude, type: .library, distance: "")
        let old = PrototypeStore(reportDefaults: defaults, catalogSpots: [])
        XCTAssertTrue(old.toggleSaved(apple))
        let saved = try XCTUnwrap(old.savedLocations.first)
        old.updateSaved(saved.id, title: "Private title", note: "Private note")

        let current = PrototypeStore(reportDefaults: defaults, catalogSpots: [item.makeSpot()])
        let spot = try XCTUnwrap(current.spots.first)
        XCTAssertEqual(current.savedLocation(for: spot)?.id, saved.id)
        XCTAssertEqual(current.savedLocation(for: spot)?.note, "Private note")
        current.simulateNearbySpot(spot.id)
        let nearby = try XCTUnwrap(current.spot(spot.id))
        XCTAssertTrue(current.submitReport(spot: nearby, experience: .muchCooler,
                                           helpedFeatures: [.airConditioning], stay: nil, comment: "Test visit"))
        let restored = PrototypeStore(reportDefaults: defaults, catalogSpots: [item.makeSpot()])
        XCTAssertEqual(restored.visitReports.first?.spotID, item.id)
        XCTAssertEqual(restored.experienceReportTotal(for: spot), 1)
        XCTAssertEqual(restored.savedLocations.count, 1)
        XCTAssertEqual(restored.savedLocation(for: spot)?.title, "Private title")
    }

    func testSearchContactDetailsAndCategorySurviveEncodingAndOlderPlacesStillDecode() throws {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: 51.49, longitude: 0.07)))
        item.name = "Tesco Extra"
        item.pointOfInterestCategory = .foodMarket
        item.phoneNumber = "+44 20 1234 5678"
        item.url = URL(string: "https://example.com/store")
        let place = try XCTUnwrap(RecognisedPlace(mapItem: item))
        let restored = try JSONDecoder().decode(RecognisedPlace.self, from: JSONEncoder().encode(place))
        XCTAssertEqual(restored.type, .shop)
        XCTAssertEqual(restored.categoryLabel, "Food market")
        XCTAssertEqual(restored.phoneURL?.absoluteString, "tel:+442012345678")
        XCTAssertEqual(restored.websiteURL, item.url)
        var old = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(place)) as? [String: Any])
        for key in ["sourceCategory", "phoneNumber", "websiteURL"] { old.removeValue(forKey: key) }
        let legacy = try JSONDecoder().decode(RecognisedPlace.self, from: JSONSerialization.data(withJSONObject: old))
        XCTAssertEqual(legacy.id, place.id)
        XCTAssertEqual(legacy.categoryLabel, "Shop")
        XCTAssertNil(legacy.phoneURL)
        XCTAssertNil(legacy.websiteURL)
    }

    func testNameAndTypeCorrectionsAreReviewedWithoutChangingThePublishedPlace() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spots.first)
        var draft = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        draft.values.name = "   "
        XCTAssertTrue(draft.validationIssues.contains { $0.field == .name })
        draft.values.name = "Updated library name"
        draft.values.type = .publicService
        XCTAssertTrue(draft.changes.contains("Name: \(spot.name) → Updated library name"))
        XCTAssertTrue(store.submitPlaceContribution(draft))
        let submitted = try XCTUnwrap(store.contributions.first?.placeDraft)
        XCTAssertEqual(submitted.values.name, "Updated library name")
        XCTAssertEqual(submitted.values.type, .publicService)
        XCTAssertEqual(submitted.original.name, spot.name)
        XCTAssertEqual(store.spot(spot.id)?.name, spot.name)
        XCTAssertEqual(store.spot(spot.id)?.type, spot.type)
        XCTAssertEqual(draft.reconciled(with: spot).values.name, "Updated library name")
    }

    func testDebouncedSearchOnlyRequestsLatestQueryAndCancelsWhenHidden() {
        var scheduled: [() -> Void] = []
        var requests: [String] = []
        var cancellations = 0
        let search = PlaceSearchModel(schedule: { action in
            scheduled.append(action)
            return { cancellations += 1 }
        }, search: { query, _, _ in
            requests.append(query)
            return {}
        })
        search.update(query: "B", region: .init())
        search.update(query: "British Library", region: .init())
        XCTAssertTrue(requests.isEmpty)
        scheduled[0]()
        XCTAssertTrue(requests.isEmpty)
        scheduled[1]()
        XCTAssertEqual(requests, ["British Library"])
        search.update(query: "Museum", region: .init())
        search.cancel()
        scheduled[2]()
        XCTAssertEqual(requests, ["British Library"])
        XCTAssertEqual(cancellations, 3)
        XCTAssertEqual(search.state, .idle)
    }

    func testSearchFailureCanRetryAndEmptySuccessIsNotAnError() {
        var completions: [(Result<[RecognisedPlace], Error>) -> Void] = []
        let search = PlaceSearchModel { _, _, completion in
            completions.append(completion)
            return {}
        }
        search.update(query: "Library", region: .init(), debounce: false)
        completions[0](.success(Fixtures.places))
        XCTAssertFalse(search.places.isEmpty)
        search.update(query: "Museum", region: .init(), debounce: false)
        XCTAssertTrue(search.places.isEmpty)
        completions[1](.failure(URLError(.notConnectedToInternet)))
        XCTAssertEqual(search.state, .failed)
        search.update(query: "Museum", region: .init(), debounce: false)
        XCTAssertEqual(search.state, .loading)
        completions[2](.success([]))
        XCTAssertEqual(search.state, .loaded)
        XCTAssertTrue(search.places.isEmpty)
    }

    func testSearchDeallocationCancelsRequestWithoutBeingRetainedByCompletion() {
        var completion: ((Result<[RecognisedPlace], Error>) -> Void)?
        var cancelled = false
        var search: PlaceSearchModel? = PlaceSearchModel { _, _, callback in
            completion = callback
            return { cancelled = true }
        }
        weak var weakSearch = search
        search?.update(query: "Library", region: .init(), debounce: false)
        search = nil
        XCTAssertNil(weakSearch)
        XCTAssertTrue(cancelled)
        completion?(.success(Fixtures.places))
    }

    func testMapKitRequestSearchesAddressesAndPlacesInTheRequestedRegion() {
        let region = MKCoordinateRegion(center: .init(latitude: 51.5, longitude: -0.12),
                                        span: .init(latitudeDelta: 0.03, longitudeDelta: 0.02))
        let request = MapKitPlaceSearch.request(query: "SW1A 1AA", region: region)
        XCTAssertEqual(request.naturalLanguageQuery, "SW1A 1AA")
        XCTAssertEqual(request.resultTypes, [.address, .pointOfInterest])
        XCTAssertEqual(request.region.center.latitude, 51.5)
        XCTAssertEqual(request.region.span.longitudeDelta, 0.02)
    }

    func testMapKitResultsKeepStableIdentityAndNeverInventCoolingOrIndoorEvidence() throws {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: 51.5299, longitude: -0.1278),
                                                  addressDictionary: ["Street": "96 Euston Road", "City": "London"]))
        item.name = "British Library"
        item.pointOfInterestCategory = .library
        let place = try XCTUnwrap(RecognisedPlace(mapItem: item))
        XCTAssertEqual(place.id, RecognisedPlace(mapItem: item)?.id)
        XCTAssertTrue(place.id.hasPrefix("apple-maps:"))
        XCTAssertEqual(place.name, "British Library")
        XCTAssertTrue(place.address.contains("Euston Road"))
        XCTAssertEqual(place.latitude, 51.5299)
        XCTAssertEqual(place.longitude, -0.1278)
        XCTAssertEqual(place.type, .library)
        XCTAssertTrue(place.hasTrustedType)
        XCTAssertNil(place.trustedSetting)
        XCTAssertNil(place.coolSpotID)
        XCTAssertTrue(place.distance.isEmpty)
        let store = PrototypeStore()
        XCTAssertNil(store.existingSpot(for: place))
        let draft = PlaceContributionDraft(kind: .recognised, anchor: place.coordinate, place: place)
        XCTAssertEqual(draft.values.name, "British Library")
        XCTAssertNil(draft.values.setting)
        XCTAssertTrue(draft.values.features.isEmpty)
        XCTAssertFalse(draft.isUnlisted)
        XCTAssertFalse(draft.isUpdate)
    }

    func testUnknownMapKitCategoryStaysOptionalAndInvalidLocationsAreExcluded() throws {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: 51.5, longitude: -0.1)))
        item.name = "A named place"
        let place = try XCTUnwrap(RecognisedPlace(mapItem: item))
        XCTAssertFalse(place.hasTrustedType)
        let draft = PlaceContributionDraft(kind: .recognised, anchor: place.coordinate, place: place)
        XCTAssertNil(draft.values.type)
        let invalid = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: 100, longitude: 200)))
        invalid.name = "Invalid location"
        XCTAssertNil(RecognisedPlace(mapItem: invalid))
    }

    func testMapKitNoMatchIsEmptyButNetworkFailureIsNotMasked() throws {
        let empty = try MapKitPlaceSearch.result(items: nil, error: MKError(.placemarkNotFound)).get()
        XCTAssertTrue(empty.isEmpty)
        XCTAssertThrowsError(try MapKitPlaceSearch.result(items: nil, error: URLError(.notConnectedToInternet)).get())
        XCTAssertThrowsError(try MapKitPlaceSearch.result(items: nil, error: nil).get())
    }

    func testSearchResultsDeduplicateByIdentityWithoutMergingNearbyDifferentPlaces() {
        let first = Fixtures.places[0]
        let neighbour = RecognisedPlace(id: "different-place", name: first.name, address: first.address,
                                       latitude: first.latitude, longitude: first.longitude, type: first.type, distance: "")
        XCTAssertEqual(PlaceSearchResults.unique([first, first, neighbour]).map(\.id), [first.id, neighbour.id])
        XCTAssertEqual(PlaceSearchResults.matching([first], query: "  \(first.name.lowercased())\n").map(\.id), [first.id])
        XCTAssertTrue(PlaceSearchResults.matching([first], query: " ").isEmpty)
    }

    func testExistingJourneyWithoutSearchedPlaceDetailsStillRestoresOwnerData() throws {
        let suite = "PlaceSearchMigration.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PrototypeStore(reportDefaults: defaults)
        let pin = store.saveCurrentLocation()
        store.updateSaved(pin.id, title: "My private pin", note: "Keep this note")
        let key = "prototype.reportJourneys.v1"
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(defaults.data(forKey: key))) as? [String: Any])
        json.removeValue(forKey: "savedPlaceDetails")
        defaults.set(try JSONSerialization.data(withJSONObject: json), forKey: key)

        let restored = PrototypeStore(reportDefaults: defaults)
        XCTAssertEqual(restored.savedLocations.first { $0.id == pin.id }?.title, "My private pin")
        XCTAssertEqual(restored.savedLocations.first { $0.id == pin.id }?.note, "Keep this note")
        XCTAssertEqual(restored.place(Fixtures.places[0].id)?.name, Fixtures.places[0].name)
    }

    func testClearingSearchCancelsWorkAndIgnoresLateFailureWithoutRequestingWhitespace() {
        var requests: [String] = []
        var completion: ((Result<[RecognisedPlace], Error>) -> Void)?
        var cancellationCount = 0
        let search = PlaceSearchModel { query, _, callback in
            requests.append(query)
            completion = callback
            return { cancellationCount += 1 }
        }
        search.update(query: "Library", region: .init(), debounce: false)
        let oldCompletion = completion
        search.update(query: " \n ", region: .init(), debounce: false)
        oldCompletion?(.failure(URLError(.notConnectedToInternet)))
        XCTAssertEqual(requests, ["Library"])
        XCTAssertEqual(cancellationCount, 1)
        XCTAssertEqual(search.state, .idle)
        XCTAssertTrue(search.places.isEmpty)
    }

    func testSearchCancelsReplacedRequestAndOnlyDisplaysLatestResults() {
        var completions: [(Result<[RecognisedPlace], Error>) -> Void] = []
        var cancelled: [String] = []
        let search = PlaceSearchModel { query, _, completion in
            completions.append(completion)
            return { cancelled.append(query) }
        }
        search.update(query: "Old", region: .init(), debounce: false)
        XCTAssertEqual(search.state, .loading)
        search.update(query: "New", region: .init(), debounce: false)
        XCTAssertEqual(cancelled, ["Old"])
        completions[1](.success([Fixtures.places[1]]))
        completions[0](.success([Fixtures.places[0]]))
        XCTAssertEqual(search.state, .loaded)
        XCTAssertEqual(search.places.map(\.id), [Fixtures.places[1].id])
    }

    func testSearchTrimsQueryAndUsesTheRequestedMapRegion() {
        var requests: [(String, MKCoordinateRegion)] = []
        let search = PlaceSearchModel { query, region, _ in
            requests.append((query, region))
            return {}
        }
        let region = MKCoordinateRegion(center: .init(latitude: 51.53, longitude: -0.12),
                                        span: .init(latitudeDelta: 0.04, longitudeDelta: 0.03))
        search.update(query: "  British Library\n", region: region, debounce: false)
        XCTAssertEqual(requests.map(\.0), ["British Library"])
        XCTAssertEqual(requests.first?.1.center.latitude, 51.53)
        XCTAssertEqual(requests.first?.1.span.longitudeDelta, 0.03)
    }

    func testSavingSearchedPlaceRestoresItsDetailsWithoutLosingPrivateNotesOrReports() throws {
        let suite = "PlaceSearch.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PrototypeStore(reportDefaults: defaults)
        let spot = try XCTUnwrap(store.spot("library"))
        XCTAssertTrue(store.submitReport(spot: spot, experience: .notCooler,
                                        helpedFeatures: [], stay: nil, comment: "Existing report"))
        let place = RecognisedPlace(id: "apple-maps:test-library", name: "British Library",
                                    address: "96 Euston Road, London", latitude: 51.5299,
                                    longitude: -0.1278, type: .library, distance: "",
                                    hasTrustedType: true)
        XCTAssertTrue(store.toggleSaved(place))
        let saved = try XCTUnwrap(store.savedLocations.first { $0.kind == .recognisedPlace(place.id) })
        store.updateSaved(saved.id, title: "My library", note: "Private note")

        let restored = PrototypeStore(reportDefaults: defaults)
        let restoredPlace = try XCTUnwrap(restored.place(place.id))
        XCTAssertEqual(restoredPlace.name, place.name)
        XCTAssertEqual(restoredPlace.address, place.address)
        XCTAssertEqual(restoredPlace.latitude, place.latitude)
        XCTAssertEqual(restoredPlace.longitude, place.longitude)
        XCTAssertEqual(restoredPlace.type, .library)
        XCTAssertNil(restoredPlace.trustedSetting)
        XCTAssertNil(restored.existingSpot(for: restoredPlace))
        XCTAssertEqual(restored.savedLocations.first { $0.id == saved.id }?.title, "My library")
        XCTAssertEqual(restored.savedLocations.first { $0.id == saved.id }?.note, "Private note")
        XCTAssertEqual(restored.visitReports.first?.comment, "Existing report")
        XCTAssertFalse(restored.toggleSaved(restoredPlace))
        XCTAssertFalse(PrototypeStore(reportDefaults: defaults).isSaved(placeID: place.id))
        XCTAssertEqual(PrototypeStore(reportDefaults: defaults).visitReports.count, 1)
    }

    func testPopsicleIsUniqueUndoableAndNeverChangesCoolingEvidence() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let example = try XCTUnwrap(store.visitorReportItems(for: spot).first)
        let evidence = store.coolingEvidence(for: spot)
        let people = store.presence(for: spot)
        XCTAssertTrue(store.sendPopsicle(to: example.id))
        XCTAssertFalse(store.sendPopsicle(to: example.id))
        XCTAssertFalse(store.sendPopsicle(to: "nonexistent"))
        XCTAssertTrue(store.hasSeenPopsicleExplanation)
        XCTAssertEqual(store.coolingEvidence(for: spot), evidence)
        XCTAssertEqual(store.presence(for: spot), people)
        store.undoPopsicle(to: example.id)
        XCTAssertFalse(store.hasSentPopsicle(to: example.id))
    }

    func testPopsiclesPersistAndOwnReportsCannotThankThemselves() throws {
        let suite = "Popsicles.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PrototypeStore(reportDefaults: defaults)
        let spot = try XCTUnwrap(store.spot("library"))
        let example = try XCTUnwrap(store.visitorReportItems(for: spot).first)
        XCTAssertTrue(store.sendPopsicle(to: example.id))
        XCTAssertTrue(store.submitReport(spot: spot, experience: .notCooler,
                                         helpedFeatures: [], stay: nil, comment: ""))
        let own = try XCTUnwrap(store.visitReports.first)
        XCTAssertFalse(store.sendPopsicle(to: own.id.uuidString))
        store.simulateReceivedPopsicle(for: own.id)
        let restored = PrototypeStore(reportDefaults: defaults)
        XCTAssertTrue(restored.hasSentPopsicle(to: example.id))
        XCTAssertTrue(restored.hasReceivedExamplePopsicle(for: own.id))
        XCTAssertTrue(restored.hasSeenPopsicleExplanation)
        XCTAssertEqual(restored.visitorReportItems(for: spot).count, spot.comments.count + 1)
    }

    func testCompleteExamplesHaveExplicitProvenanceAndStableMetadata() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let items = store.visitorReportItems(for: spot)
        XCTAssertEqual(items.map(\.comment), spot.comments)
        XCTAssertTrue(items.allSatisfy { $0.report != nil && $0.isExample && !$0.isOwn })
        XCTAssertEqual(items.first?.report?.visitedAt, ISO8601DateFormatter().date(from: "2026-09-05T14:00:00Z"))
        XCTAssertNotEqual(items.first?.report?.visitedAt, spot.latestReportAt)
    }

    func testLatestReportDoesNotPrioritizeItsAuthor() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let example = try XCTUnwrap(store.visitorReportItems(for: spot).first)
        let date = try XCTUnwrap(example.report?.visitedAt)
        func personal(at date: Date) -> VisitReport {
            .init(id: UUID(), spotID: spot.id, experience: .notCooler, helpedFeatures: [],
                  stayLength: nil, comment: "My visit", visitedAt: date, confirmationAt: date, submittedAt: date)
        }
        store.visitReports = [personal(at: date.addingTimeInterval(-3600))]
        XCTAssertTrue(try XCTUnwrap(store.visitorReportItems(for: spot).first).isExample)
        store.visitReports.append(personal(at: date.addingTimeInterval(3600)))
        XCTAssertTrue(try XCTUnwrap(store.visitorReportItems(for: spot).first).isOwn)
        XCTAssertEqual(store.visitorReportItems(for: spot).compactMap { $0.report?.visitedAt },
                       [date.addingTimeInterval(3600), date, date.addingTimeInterval(-3600)])
    }

    func testUnknownDateNeverWinsNewestPreview() throws {
        let dated = try XCTUnwrap(Fixtures.visitorReports.first)
        let undated = VisitorReportItem(id: "unknown", comment: "Undated", report: nil, provenance: .visitor)
        XCTAssertEqual(VisitorReportItem.newestFirst([undated, dated]).first?.id, dated.id)
        XCTAssertFalse(undated.isOwn)
    }

    func testAppearanceMapsToSystemLightAndDark() {
        XCTAssertNil(AppAppearance.system.colorScheme)
        XCTAssertEqual(AppAppearance.light.colorScheme, .light)
        XCTAssertEqual(AppAppearance.dark.colorScheme, .dark)
        XCTAssertEqual(AppAppearance.allCases.map(\.title), ["Match System", "Light", "Dark"])
    }

    func testAppearanceDefaultsToLightAndPersistsSelection() throws {
        let suiteName = "CoolSpotAppearanceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preference = AppStorage(wrappedValue: AppAppearance.light,
                                    AppAppearance.storageKey, store: defaults)
        XCTAssertEqual(preference.wrappedValue, .light)

        preference.wrappedValue = .dark
        let restored = AppStorage(wrappedValue: AppAppearance.light,
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

    func testConfirmedVisitCanBeStartedAfterSevenDaysAway() throws {
        let suite = "NoVisitDeadline.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PrototypeStore(reportDefaults: defaults)
        let start = Date.now.addingTimeInterval(-7 * 86_400)
        let spot = try XCTUnwrap(store.spot("library"))
        store.checkIn(spot, at: start)
        store.activePresenceSpotID = nil
        store.simulateNearbySpot(nil)
        let restored = PrototypeStore(reportDefaults: defaults)
        let away = try XCTUnwrap(restored.spot(spot.id))
        XCTAssertTrue(restored.canReportVisit(for: away))
        XCTAssertEqual(restored.visitsWithoutReports().map(\.id), [spot.id])
        XCTAssertTrue(restored.beginVisitReport(for: away))
        XCTAssertEqual(restored.reportDrafts[spot.id]?.visitedAt, start)
        XCTAssertTrue(restored.submitReport(spot: away, experience: .muchCooler,
                                            helpedFeatures: [], stay: nil, comment: "A week later"))
        XCTAssertEqual(restored.visitReports.first?.visitedAt, start)
        XCTAssertFalse(restored.canReportVisit(for: away))
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

    func testFinishLaterRestoresAllAnswersAfterLeavingAndRelaunching() throws {
        let suiteName = "ReportJourneyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PrototypeStore(reportDefaults: defaults)
        let spot = try XCTUnwrap(store.spot("library"))
        let startedAt = Date.now.addingTimeInterval(-3_600)
        XCTAssertTrue(store.beginVisitReport(for: spot, at: startedAt))
        let answers = VisitReportDraft(experience: .notCooler, helpedFeatures: [.drinkingWater],
                                       stay: .under30, comment: "Water helped, but the room was warm.",
                                       visitedAt: startedAt.addingTimeInterval(-300))
        store.saveReportDraft(answers, for: spot.id)
        _ = store.toggleSaved(spot)
        store.simulateNearbySpot(nil)

        let restored = PrototypeStore(reportDefaults: defaults)
        let awaySpot = try XCTUnwrap(restored.spot(spot.id))
        XCTAssertFalse(awaySpot.isNearby)
        XCTAssertTrue(restored.isSaved(spotID: spot.id))
        XCTAssertEqual(restored.reportDrafts[spot.id], answers)
        XCTAssertTrue(restored.visitsToShare.contains { $0.id == spot.id })
        XCTAssertNil(restored.activePresenceSpotID)
        XCTAssertTrue(restored.beginVisitReport(for: awaySpot))
        XCTAssertEqual(restored.visitConfirmedAt[spot.id], startedAt)
        XCTAssertTrue(restored.submitReport(spot: awaySpot, experience: .notCooler,
                                            helpedFeatures: answers.helpedFeatures, stay: answers.stay,
                                            comment: answers.comment, visitedAt: answers.visitedAt))
        XCTAssertNil(restored.reportDrafts[spot.id])
        XCTAssertTrue(restored.visitsToShare.isEmpty)

        let relaunchedAfterPublishing = PrototypeStore(reportDefaults: defaults)
        XCTAssertEqual(relaunchedAfterPublishing.visitReports.count, 1)
        XCTAssertEqual(relaunchedAfterPublishing.visitReports.first?.visitedAt, answers.visitedAt)
        XCTAssertFalse(relaunchedAfterPublishing.canReportVisit(for: awaySpot))
        XCTAssertNil(relaunchedAfterPublishing.activePresenceSpotID)
        XCTAssertFalse(try XCTUnwrap(PrototypeStore(reportDefaults: defaults).spot(spot.id)).isNearby)
    }

    func testRepeatedOpeningAndPresenceDoNotMoveTheDeadlineOrEraseAnswers() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let start = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertTrue(store.beginVisitReport(for: spot, at: start))
        let answers = VisitReportDraft(experience: .aLittleCooler, visitedAt: start)
        store.saveReportDraft(answers, for: spot.id)
        store.checkIn(spot, at: start.addingTimeInterval(600))
        XCTAssertTrue(store.beginVisitReport(for: spot, at: start.addingTimeInterval(1_200)))
        XCTAssertEqual(store.visitConfirmedAt[spot.id], start)
        XCTAssertEqual(store.reportDrafts[spot.id], answers)
        XCTAssertTrue(store.hasCurrentConfirmation(for: spot, at: start.addingTimeInterval(7 * 86_400)))
    }

    func testOldDraftCanResumeAndPublishAfterLeavingAndRelaunch() throws {
        let suiteName = "ExpiredJourneyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PrototypeStore(reportDefaults: defaults)
        let spot = try XCTUnwrap(store.spot("library"))
        let start = Date.now.addingTimeInterval(-7 * 86_400)
        XCTAssertTrue(store.beginVisitReport(for: spot, at: start))
        store.saveReportDraft(.init(experience: .notCooler, comment: "Keep my answer", visitedAt: start), for: spot.id)
        store.simulateNearbySpot(nil)
        let restored = PrototypeStore(reportDefaults: defaults)
        let away = try XCTUnwrap(restored.spot(spot.id))
        XCTAssertTrue(restored.canReportVisit(for: away))
        XCTAssertEqual(restored.reportDrafts[spot.id]?.comment, "Keep my answer")
        XCTAssertTrue(restored.visitReports.isEmpty)
        XCTAssertTrue(restored.beginVisitReport(for: away))
        XCTAssertEqual(restored.reportDrafts[spot.id]?.visitedAt, start)
        XCTAssertTrue(restored.submitReport(spot: away, experience: .notCooler,
                                            helpedFeatures: [], stay: nil, comment: "Keep my answer"))
        XCTAssertEqual(restored.visitReports.first?.visitedAt, start)
        XCTAssertFalse(restored.submitReport(spot: away, experience: .muchCooler,
                                             helpedFeatures: [], stay: nil, comment: ""))
        XCTAssertTrue(restored.unfinishedReportSpots.isEmpty)
        XCTAssertTrue(PrototypeStore(reportDefaults: defaults).visitsToShare.isEmpty)
    }

    func testSavingAndBrowsingNeverCreateReportEligibilityAcrossRelaunch() throws {
        let suiteName = "PrivateSaveTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PrototypeStore(reportDefaults: defaults)
        let spot = try XCTUnwrap(store.spot("library"))
        _ = store.toggleSaved(spot)
        let coordinate = store.saveCurrentLocation()
        store.simulateNearbySpot(nil)
        let restored = PrototypeStore(reportDefaults: defaults)
        XCTAssertTrue(restored.savedLocations.contains { $0.id == coordinate.id })
        XCTAssertTrue(restored.visitConfirmedAt.isEmpty)
        XCTAssertFalse(restored.canReportVisit(for: try XCTUnwrap(restored.spot(spot.id))))
    }

    func testLateSubmissionUsesVisitTimeAndDuplicateDoesNotChangeEvidence() throws {
        let store = PrototypeStore()
        var spot = try XCTUnwrap(store.spot("library"))
        let visitTime = Date.now.addingTimeInterval(-1_800)
        XCTAssertTrue(store.beginVisitReport(for: spot, at: visitTime))
        spot.isNearby = false
        let now = Date.now
        XCTAssertTrue(store.submitReport(spot: spot, experience: .notCooler,
                                         helpedFeatures: [], stay: nil, comment: "", at: now))
        XCTAssertEqual(store.latestReportDate(for: spot), visitTime)
        XCTAssertEqual(store.visitReports.first?.submittedAt, now)
        XCTAssertFalse(store.submitReport(spot: spot, experience: .muchCooler,
                                          helpedFeatures: [], stay: nil, comment: "", at: now))
        XCTAssertEqual(store.visitReports.count, 1)
        XCTAssertEqual(store.experienceReportTotal(for: spot), 9)
    }

    func testCannotPublishFutureVisitTimeOrSilentlyChangeAnotherPlacesDraft() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let now = Date.now
        XCTAssertTrue(store.beginVisitReport(for: spot, at: now))
        XCTAssertFalse(store.submitReport(spot: spot, experience: .muchCooler,
                                          helpedFeatures: [], stay: nil, comment: "",
                                          visitedAt: now.addingTimeInterval(60), at: now))
        store.saveReportDraft(.init(experience: .muchCooler, visitedAt: now), for: "museum")
        XCTAssertNil(store.reportDrafts["museum"])
        XCTAssertTrue(store.visitReports.isEmpty)
    }

    func testPresenceExpiresAfterTenMinutesWithoutRemovingReportEligibility() throws {
        let store = PrototypeStore()
        var spot = try XCTUnwrap(store.spot("library"))
        let start = Date.now
        store.checkIn(spot, at: start)
        XCTAssertEqual(store.presence(for: spot, at: start.addingTimeInterval(599)), spot.presenceCount + 1)
        store.endExpiredPresence(at: start.addingTimeInterval(600))
        XCTAssertEqual(store.presence(for: spot, at: start.addingTimeInterval(600)), spot.presenceCount)
        XCTAssertNil(store.activePresenceSpotID)
        spot.isNearby = false
        XCTAssertTrue(store.canReportVisit(for: spot, at: start.addingTimeInterval(601)))
    }

    func testReturningNearbyNeverReplacesAnUnfinishedReportsOriginalVisit() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let oldVisit = Date.now.addingTimeInterval(-90_000)
        XCTAssertTrue(store.beginVisitReport(for: spot, at: oldVisit))
        store.saveReportDraft(.init(experience: .notCooler, visitedAt: oldVisit), for: spot.id)
        let newVisit = Date.now
        store.checkIn(spot, at: newVisit)
        XCTAssertTrue(store.beginVisitReport(for: spot, at: newVisit))
        XCTAssertEqual(store.visitConfirmedAt[spot.id], oldVisit)
        XCTAssertEqual(store.reportDrafts[spot.id]?.experience, .notCooler)
        XCTAssertEqual(store.reportDrafts[spot.id]?.visitedAt, oldVisit)
        XCTAssertTrue(store.submitReport(spot: spot, experience: .notCooler,
                                         helpedFeatures: [], stay: nil, comment: "", visitedAt: oldVisit))
        XCTAssertEqual(store.visitReports.first?.visitedAt, oldVisit)
    }

    func testThreeUnfinishedReportsAreSeparateFromPresenceSavingAndPublishedReports() throws {
        let store = PrototypeStore()
        let now = Date.now
        for (index, fixture) in store.spots.enumerated() {
            var spot = fixture
            spot.isNearby = true
            XCTAssertTrue(store.beginVisitReport(for: spot, at: now.addingTimeInterval(Double(-index) * 86_400)))
        }
        store.simulateNearbySpot(nil)
        XCTAssertEqual(store.unfinishedReportSpots.count, 3)
        XCTAssertTrue(store.visitsWithoutReports().isEmpty)
        let chosen = try XCTUnwrap(store.spot("museum"))
        XCTAssertTrue(store.submitReport(spot: chosen, experience: .aLittleCooler,
                                         helpedFeatures: [], stay: nil, comment: ""))
        XCTAssertEqual(store.unfinishedReportSpots.count, 2)
        XCTAssertFalse(store.unfinishedReportSpots.contains { $0.id == chosen.id })
        XCTAssertEqual(store.visitReports.map(\.spotID), [chosen.id])
        XCTAssertFalse(store.isSaved(spotID: chosen.id))
    }

    func testPresenceWithoutAnswersDoesNotCountAsAnUnfinishedReport() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        store.checkIn(spot)
        XCTAssertTrue(store.unfinishedReportSpots.isEmpty)
        XCTAssertEqual(store.visitsWithoutReports().map(\.id), [spot.id])
        XCTAssertTrue(store.beginVisitReport(for: spot))
        XCTAssertEqual(store.unfinishedReportSpots.map(\.id), [spot.id])
        XCTAssertTrue(store.visitsWithoutReports().isEmpty)
        store.discardReportAnswers(spot.id)
        XCTAssertTrue(store.unfinishedReportSpots.isEmpty)
        XCTAssertTrue(store.visitReports.isEmpty)
    }

    func testRelaunchKeepsPresenceDeadlineAndStopSharingStaysStopped() throws {
        let suiteName = "PresenceJourneyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PrototypeStore(reportDefaults: defaults)
        let spot = try XCTUnwrap(store.spot("library"))
        let start = Date.now
        store.checkIn(spot, at: start)
        let restored = PrototypeStore(reportDefaults: defaults)
        XCTAssertEqual(restored.presenceEndsAt, start.addingTimeInterval(600))
        XCTAssertEqual(restored.presence(for: spot), spot.presenceCount + 1)
        restored.activePresenceSpotID = nil
        let stopped = PrototypeStore(reportDefaults: defaults)
        XCTAssertNil(stopped.activePresenceSpotID)
        XCTAssertTrue(stopped.hasCurrentConfirmation(for: spot))
    }
}

@MainActor
final class ApprovedContributionTests: XCTestCase {
    func testSavedAnchorIsIndependentOfCurrentLocationAndPrivateText() {
        let saved = SavedLocation(id: UUID(), title: "Private name", subtitle: "", savedAt: .now,
                                  latitude: 51.6, longitude: -0.2, kind: .coordinate, note: "Private note")
        let source = ContributionSource.savedCoordinate(saved)
        let anchor = source.anchor(current: .init(latitude: 50, longitude: 0))
        XCTAssertEqual(anchor.latitude, 51.6); XCTAssertEqual(anchor.longitude, -0.2)
        let draft = PlaceContributionDraft(kind: .exact, anchor: anchor)
        XCTAssertTrue(draft.values.name.isEmpty); XCTAssertTrue(draft.values.note.isEmpty)
        XCTAssertNil(draft.values.type); XCTAssertEqual(draft.values.setting, .outdoors)
    }
    func testRecognisedPlaceNeedsUnknownSettingButNoOptionalAnswers() throws {
        let place = try XCTUnwrap(Fixtures.places.first)
        var draft = PlaceContributionDraft(kind: .recognised, anchor: place.coordinate, place: place)
        XCTAssertNil(draft.values.setting)
        draft.values.features = [.drinkingWater]
        XCTAssertFalse(draft.canSend)
        draft.values.setting = .both
        XCTAssertTrue(draft.canSend)
        XCTAssertNil(draft.values.photo)
        XCTAssertEqual(draft.values.laptop, .unknown)
    }
    func testUnknownTypeCanBeLeftUnansweredRatherThanGuessed() throws {
        var place = try XCTUnwrap(Fixtures.places.first)
        place.hasTrustedType = false
        var draft = PlaceContributionDraft(kind: .recognised, anchor: place.coordinate, place: place)
        draft.values.setting = .indoors; draft.values.features = [.airConditioning]
        XCTAssertTrue(draft.canSend); XCTAssertNil(draft.values.type)
        draft.values.type = .food
        XCTAssertTrue(draft.canSend)
    }
    private func placePhoto() -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).pngData { context in
            UIColor.green.setFill(); context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }

    func testUnlistedPlacesAlwaysNeedBothNameAndPhotoWithOptionalType() {
        for kind in [PlaceContributionKind.unlisted, .missing, .exact] {
            for setting in PlaceEnvironment.allCases {
                var draft = PlaceContributionDraft(kind: kind, anchor: .init(latitude: 51.6, longitude: -0.2))
                draft.values.locationConfirmed = true
                draft.values.setting = setting
                draft.values.features = [.treeShade]
                draft.values.name = "Shade beside the playground"
                XCTAssertFalse(draft.canSend, "A name must not waive the photo requirement")
                XCTAssertEqual(draft.validationIssues.map(\.field), [.photo])
                draft.values.photo = Data([1, 2, 3])
                XCTAssertFalse(draft.canSend)
                draft.values.photo = placePhoto()
                XCTAssertTrue(draft.canSend)
                XCTAssertNil(draft.values.type, "Place type is still optional")
                for blank in ["", " \n "] {
                    draft.values.name = blank
                    XCTAssertFalse(draft.canSend, "A photo must not substitute for a descriptive name")
                    XCTAssertEqual(draft.validationIssues.map(\.field), [.name])
                }
                draft.values.name = "Shade beside the playground"
                for answer in PlaceEntryEligibility.allCases {
                    draft.values.entryEligibility = answer
                    XCTAssertTrue(draft.canSend, "All entry eligibility answers permit review")
                }
            }
        }
    }

    func testValidationReportsAllMissingAnswersAndRecoversWithoutLosingOtherAnswers() {
        var draft = PlaceContributionDraft(kind: .unlisted, anchor: .init(latitude: 51.6, longitude: -0.2))
        draft.values.locationConfirmed = true
        draft.values.locationDetails = "By the east gate"
        draft.values.tables = .yes
        XCTAssertEqual(draft.validationIssues.map(\.field), [.setting, .name, .features, .photo])
        draft.values.setting = .outdoors
        draft.values.name = "Shade by the east gate"
        draft.values.features = [.treeShade]
        draft.values.photo = placePhoto()
        XCTAssertTrue(draft.validationIssues.isEmpty)
        XCTAssertTrue(draft.canSend)
        XCTAssertEqual(draft.values.locationDetails, "By the east gate")
        XCTAssertEqual(draft.values.tables, .yes)
        draft.values.photo = nil
        XCTAssertEqual(draft.validationIssues.map(\.field), [.photo])
        XCTAssertFalse(draft.canSend)
    }

    func testStoreRejectsIncompleteIdentificationAndAcceptsCompleteUnlistedProposalOnce() {
        let store = PrototypeStore()
        var draft = PlaceContributionDraft(kind: .unlisted, anchor: .init(latitude: 51.6, longitude: -0.2))
        draft.values.locationConfirmed = true
        draft.values.setting = .outdoors
        draft.values.features = [.treeShade]
        draft.values.name = "Shade beside the playground"
        let initialCount = store.contributions.count
        XCTAssertFalse(store.submitPlaceContribution(draft))
        draft.values.photo = placePhoto()
        draft.values.name = " "
        XCTAssertFalse(store.submitPlaceContribution(draft))
        XCTAssertEqual(store.contributions.count, initialCount)
        draft.values.name = "Shade beside the playground"
        XCTAssertTrue(store.submitPlaceContribution(draft))
        XCTAssertEqual(store.contributions.first?.placeDraft?.values, draft.values)
        XCTAssertFalse(store.submitPlaceContribution(draft))
        XCTAssertEqual(store.contributions.count, initialCount + 1)
    }

    func testUpdateOnlyNeedsARealChangeAndCanRevertToNoChanges() throws {
        let spot = try XCTUnwrap(Fixtures.spots.first)
        var draft = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        XCTAssertFalse(draft.canSend)
        draft.values.tables = .yes
        XCTAssertTrue(draft.canSend)
        XCTAssertEqual(draft.values.features, Set(spot.features))
        XCTAssertEqual(draft.values.laptop, .unknown)
        draft.values.tables = .unknown
        XCTAssertFalse(draft.canSend)
        draft.values.features = []
        XCTAssertFalse(draft.canSend)
        draft.values.removalReason = "The shaded structure was removed."
        XCTAssertTrue(draft.canSend)
    }
    func testUpdateRejectsBlankChangesBookkeepingAndInvalidChangedFields() throws {
        let spot = try XCTUnwrap(Fixtures.spots.first)
        let baseline = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        var draft = baseline
        draft.values.note = " "; draft.values.accessibility = "\n"; draft.values.stayLimit = "  "
        draft.values.sourceCorrection = " "; draft.values.removalReason = "Reason alone"
        XCTAssertTrue(draft.changes.isEmpty)
        XCTAssertFalse(draft.canSend)
        draft = baseline; draft.values.setting = nil
        XCTAssertFalse(draft.canSend)
        draft = baseline; draft.values.type = nil
        XCTAssertFalse(draft.canSend)
        draft = baseline; draft.values.photo = Data([1, 2, 3])
        XCTAssertFalse(draft.canSend)
        draft = baseline; draft.values.note = " A useful correction "
        XCTAssertTrue(draft.canSend)
        XCTAssertEqual(draft.changes, ["Note: A useful correction"])
    }
    func testDuplicateRebasesOnlyProposedFieldsAndPreservesExplicitType() throws {
        let spot = try XCTUnwrap(Fixtures.spots.first)
        var draft = PlaceContributionDraft(kind: .missing, anchor: spot.coordinate)
        draft.values.name = spot.name; draft.values.locationConfirmed = true
        draft.values.setting = .both; draft.values.type = .square
        draft.values.features = [.drinkingWater]; draft.values.note = " Check entry "
        let update = draft.reconciled(with: spot)
        XCTAssertEqual(update.values.access, spot.access)
        XCTAssertEqual(update.values.seating, spot.seating)
        XCTAssertEqual(update.values.type, .square)
        XCTAssertEqual(update.values.note, "Check entry")
        XCTAssertEqual(update.original.type, spot.type)
        XCTAssertTrue(update.changes.contains { $0.hasPrefix("Type:") })
        XCTAssertFalse(update.changes.contains { $0.hasPrefix("Cost to use:") || $0.hasPrefix("Seating:") })
        draft.values.access = .entryFee
        XCTAssertEqual(draft.reconciled(with: spot).values.access, .entryFee)
    }

    func testStudentOnlyEntryIsIndependentOfCostAndSurvivesReviewSubmission() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spots.first)
        var proposal = PlaceContributionDraft(kind: .missing, anchor: spot.coordinate)
        proposal.values.name = spot.name
        proposal.values.locationConfirmed = true
        proposal.values.setting = .indoors
        proposal.values.features = [.airConditioning]
        proposal.values.entryEligibility = .limited
        proposal.values.entryRequirement = " Students with a valid student card "
        proposal.values.access = .free

        let update = proposal.reconciled(with: spot)
        XCTAssertEqual(update.values.entryEligibility, .limited)
        XCTAssertEqual(update.values.entryRequirement, "Students with a valid student card")
        XCTAssertEqual(update.values.access, .free)
        XCTAssertTrue(update.changes.contains("Who can use it: Limited access"))
        XCTAssertTrue(store.submitPlaceContribution(update))
        let submitted = try XCTUnwrap(store.contributions.first?.placeDraft)
        XCTAssertEqual(submitted.values.entryEligibility, .limited)
        XCTAssertEqual(submitted.values.entryRequirement, "Students with a valid student card")
        XCTAssertEqual(submitted.values.access, .free)
    }

    func testEligibilityCorrectionCountsAsAnEditAndDoesNotSubmitHiddenRestrictions() throws {
        let spot = try XCTUnwrap(Fixtures.spots.first)
        var draft = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        XCTAssertFalse(draft.canSend)
        draft.values.entryEligibility = .limited
        XCTAssertTrue(draft.canSend)
        draft.values.entryRequirement = "Residents only"
        draft.values.entryEligibility = .everyone
        XCTAssertEqual(draft.values.entryRequirement, "")
        XCTAssertEqual(draft.changes, ["Who can use it: Everyone"])
        draft.values.entryEligibility = .unknown
        XCTAssertTrue(draft.changes.isEmpty)
        XCTAssertFalse(draft.canSend)
    }

    func testFreeTicketBookingSurvivesEligibilityChangesAndReview() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spots.first)
        var draft = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        draft.values.access = .free
        draft.values.entryEligibility = .limited
        draft.values.entryRequirement = "Students only"
        draft.values.accessibility = " Book a free ticket before visiting "
        draft.values.entryEligibility = .everyone
        XCTAssertEqual(draft.values.entryRequirement, "")
        let update = draft.reconciled(with: spot)
        XCTAssertEqual(update.values.access, .free)
        XCTAssertEqual(update.values.entryEligibility, .everyone)
        XCTAssertEqual(update.values.accessibility, "Book a free ticket before visiting")
        XCTAssertTrue(store.submitPlaceContribution(update))
        let submitted = try XCTUnwrap(store.contributions.first?.placeDraft)
        XCTAssertEqual(submitted.values.access, .free)
        XCTAssertEqual(submitted.values.accessibility, "Book a free ticket before visiting")
    }

    func testEditingReviewedPlacePreservesSpecificEntryConditions() throws {
        let store = PrototypeStore()
        var spot = try XCTUnwrap(store.spots.first)
        spot.entryEligibility = .limited
        spot.entryRequirement = "University students and staff only"
        spot.entryInformation = "Book a free ticket before visiting"
        XCTAssertEqual(spot.entrySummary, "University students and staff only")
        var edit = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        XCTAssertFalse(edit.canSend)
        XCTAssertEqual(edit.values.entryRequirement, spot.entryRequirement)
        XCTAssertEqual(edit.values.accessibility, spot.entryInformation)
        edit.values.seating = .limited
        let update = edit.reconciled(with: spot)
        XCTAssertEqual(update.values.entryEligibility, .limited)
        XCTAssertEqual(update.values.entryRequirement, spot.entryRequirement)
        XCTAssertEqual(update.values.accessibility, spot.entryInformation)
        XCTAssertTrue(store.submitPlaceContribution(update))
        XCTAssertEqual(store.contributions.first?.placeDraft?.values.entryRequirement, spot.entryRequirement)
        // Missing detail must stay visibly unknown, never invent which group can enter.
        spot.entryRequirement = "  "
        XCTAssertEqual(spot.entrySummary, "Limited access · Requirements not confirmed")
    }
    func testSubmissionKeepsAllPublicAnswersWithoutChangingPrivateDataOrEvidence() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spots.first)
        let saved = store.saveCurrentLocation()
        store.updateSaved(saved.id, title: "Private", note: "Personal")
        let before = try XCTUnwrap(store.savedLocations.first)
        let count = store.presence(for: spot)
        let evidence = store.coolingEvidence(for: spot)
        var draft = PlaceContributionDraft(kind: .update, anchor: spot.coordinate, spot: spot)
        draft.values.tables = .yes; draft.values.power = .yes; draft.values.note = "Public note"
        XCTAssertTrue(store.submitPlaceContribution(draft))
        XCTAssertFalse(store.submitPlaceContribution(draft))
        XCTAssertEqual(store.contributions.first?.placeDraft?.values, draft.values)
        XCTAssertEqual(store.savedLocations.first?.title, before.title)
        XCTAssertEqual(store.savedLocations.first?.note, before.note)
        XCTAssertEqual(store.presence(for: spot), count)
        XCTAssertEqual(store.coolingEvidence(for: spot), evidence)
        XCTAssertTrue(store.reportDrafts.isEmpty)
    }
    func testDuplicateMustBecomeUpdateAndRetainsProposedDetailsForReview() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spots.first)
        var place = try XCTUnwrap(Fixtures.places.first)
        place.coolSpotID = spot.id
        XCTAssertEqual(store.existingSpot(for: place)?.id, spot.id)
        var draft = PlaceContributionDraft(kind: .missing, anchor: spot.coordinate)
        draft.values.name = spot.name; draft.values.locationConfirmed = true
        draft.values.setting = .both; draft.values.type = spot.type; draft.values.features = [.drinkingWater]
        draft.values.note = "Please check access"
        draft.values.photo = placePhoto()
        XCTAssertTrue(draft.canSend)
        XCTAssertFalse(store.submitPlaceContribution(draft))
        let update = draft.reconciled(with: spot)
        XCTAssertTrue(update.isUpdate)
        XCTAssertEqual(update.values.note, draft.values.note)
        XCTAssertEqual(update.values.features, draft.values.features)
        XCTAssertTrue(store.submitPlaceContribution(update))
        XCTAssertEqual(store.contributions.first?.kind, .placeUpdate)
    }
    func testDiscardKeepsConfirmedVisitAndAllowsRestartWhileAway() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        XCTAssertTrue(store.beginVisitReport(for: spot))
        store.saveReportDraft(.init(experience: .aLittleCooler, comment: "Discard only this", visitedAt: .now), for: spot.id)
        let confirmation = store.visitConfirmedAt[spot.id]
        store.simulateNearbySpot(nil)
        store.discardReportAnswers(spot.id)
        XCTAssertNil(store.reportDrafts[spot.id])
        XCTAssertEqual(store.visitConfirmedAt[spot.id], confirmation)
        XCTAssertTrue(store.beginVisitReport(for: try XCTUnwrap(store.spot(spot.id))))
        XCTAssertNil(store.reportDrafts[spot.id]?.experience)
        XCTAssertEqual(store.reportDrafts[spot.id]?.comment, "")
    }

    func testExplicitNewVisitPreservesPublishedReportAndDoesNotSharePresence() throws {
        let store = PrototypeStore()
        let spot = try XCTUnwrap(store.spot("library"))
        let first = Date.now.addingTimeInterval(-86_400)
        XCTAssertTrue(store.beginVisitReport(for: spot, at: first))
        XCTAssertTrue(store.submitReport(spot: spot, experience: .muchCooler, helpedFeatures: [], stay: nil, comment: "First", at: first))
        XCTAssertFalse(store.beginVisitReport(for: spot))
        var away = spot; away.isNearby = false
        XCTAssertFalse(store.beginNewVisitReport(for: away))
        XCTAssertTrue(store.beginNewVisitReport(for: spot))
        XCTAssertNil(store.activePresenceSpotID)
        XCTAssertEqual(store.visitReports.count, 1)
        XCTAssertTrue(store.submitReport(spot: spot, experience: .notCooler, helpedFeatures: [], stay: nil, comment: "Second"))
        XCTAssertEqual(store.visitReports.count, 2)
        XCTAssertNotEqual(store.visitReports[0].confirmationAt, store.visitReports[1].confirmationAt)
    }

    func testPrivateNotesPersistForBothPlaceKindsAndUnsaveDoesNotRemoveReports() throws {
        let suite = "SavedKinds.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PrototypeStore(reportDefaults: defaults)
        let spot = try XCTUnwrap(store.spot("library"))
        let place = try XCTUnwrap(store.recognisedPlaces.first)
        _ = store.toggleSaved(spot); _ = store.toggleSaved(place)
        for item in store.savedLocations where item.kind != .coordinate {
            store.updateSaved(item.id, title: "Private \(item.title)", note: "My note")
        }
        let restored = PrototypeStore(reportDefaults: defaults)
        XCTAssertEqual(restored.savedLocations.filter { $0.kind != .coordinate && $0.note == "My note" }.count, 2)
        XCTAssertTrue(restored.beginVisitReport(for: spot))
        XCTAssertTrue(restored.submitReport(spot: spot, experience: .aLittleCooler, helpedFeatures: [], stay: nil, comment: "Keep me"))
        XCTAssertFalse(restored.toggleSaved(spot)); XCTAssertFalse(restored.toggleSaved(place))
        XCTAssertEqual(restored.visitReports.count, 1)
        XCTAssertFalse(restored.isSaved(spotID: spot.id)); XCTAssertFalse(restored.isSaved(placeID: place.id))
    }

}
