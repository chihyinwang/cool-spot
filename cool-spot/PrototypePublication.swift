import Foundation
import UIKit

// Device-local stand-in for a reviewed publication operation. No remote API or moderation is implied.
enum PrototypePublication {
    static let source = CoolSpotsResponse.SourceMetadata(
        id: "prototype-community", provider: "community", label: "Community info · Local demo", url: nil)

    static func publish(_ draft: PlaceContributionDraft, onto current: CoolSpot?, photoID: String?,
                        at date: Date) throws -> CoolSpotsResponse.Item {
        guard draft.canSend, !draft.isUpdate || current != nil else { throw PrototypePublicationError.invalidContribution }
        let now = ISO8601DateFormatter().string(from: date)
        let v = draft.values.normalized
        let before = draft.original.normalized
        let currentValues = current.map { PlaceContributionDraft(kind: .update, anchor: $0.coordinate, spot: $0).values.normalized }
        var item = current?.publishedRecord ?? baseline(draft, current: current)
        var changed: [String] = []

        // Only explicitly changed answers become writes. Untouched facts keep their existing evidence.
        func apply<V: Equatable>(_ key: KeyPath<PlaceContributionValues, V>, path: String, write: (V) throws -> Void) throws {
            let proposed = v[keyPath: key]
            if draft.isUpdate {
                guard proposed != before[keyPath: key] else { return }
                if let currentValues, currentValues[keyPath: key] != before[keyPath: key],
                   currentValues[keyPath: key] != proposed { throw PrototypePublicationError.changedSinceSubmission }
            }
            try write(proposed)
            changed.append(path)
        }
        try apply(\.name, path: "/name") { item.name = $0 }
        try apply(\.setting, path: "/setting") { item.setting = CoolSpotSetting(environment: $0) }
        try apply(\.type, path: "/placeType") { item.placeType = CoolSpotPlaceType(type: $0) }
        try apply(\.features, path: "/coolingFeatures") {
            item.coolingFeatures = $0.compactMap(CoolSpotFeature.init(feature:)).sorted { $0.rawValue < $1.rawValue }
            // This checkbox can assert yes or withdraw an assertion. It cannot assert no.
            if !draft.isUpdate || $0.contains(.drinkingWater) != before.features.contains(.drinkingWater) {
                item.access.drinkingWater = $0.contains(.drinkingWater) ? .yes : .unknown
                changed.append("/access/drinkingWater")
            }
        }
        try apply(\.access, path: "/access/cost") { item.access.cost = CoolSpotCost(access: $0) }
        try apply(\.entryEligibility, path: "/access/eligibility") {
            item.access.eligibility = $0 == .everyone ? "everyone" : $0 == .limited ? "limited" : "unknown"
            if $0 != .limited { item.access.eligibilityDetails = nil; changed.append("/access/eligibilityDetails") }
        }
        try apply(\.seating, path: "/access/seating") { item.access.seating = CoolSpotSeating(seating: $0) }
        try apply(\.toilets, path: "/access/toilets") { item.access.toilets = CoolSpotToilets(rawValue: $0.rawValue) ?? .unknown }
        try apply(\.wheelchairAccess, path: "/access/wheelchairAccess") { item.access.wheelchairAccess = .init(answer: $0) }
        try apply(\.staffedWhenOpen, path: "/access/staffedWhenOpen") { item.access.staffedWhenOpen = .init(answer: $0) }
        try apply(\.tables, path: "/access/tables") { item.access.tables = .init(answer: $0) }
        try apply(\.locationDetails, path: "/access/areaDescription") { item.access.areaDescription = $0.nilIfEmpty }
        try apply(\.stayLimit, path: "/access/postedStayLimit") { item.access.postedStayLimit = try .fromForm($0) }
        try apply(\.note, path: "/additionalInformation") { item.additionalInformation = $0.nilIfEmpty }

        if v.photo != before.photo, v.photo != nil {
            guard let photoID else { throw PrototypePublicationError.missingPhoto }
            let photo = try PrototypePhotoStorage.publishedPhoto(id: photoID, contributionID: draft.id.uuidString, at: now)
            if !(item.photos ?? []).contains(where: { $0.id == photo.id }) { item.photos = (item.photos ?? []) + [photo] }
            changed.append("/photos")
        }
        if !draft.isUpdate {
            item.location.scope = draft.selectedPlace == nil ? (draft.kind == .exact ? .specificArea : .unknown) : .venue
            // Optional area text describes where to cool down; it does not change the selected venue identity.
            if let place = draft.selectedPlace, place.appleMapItemIdentifier != nil {
                item.mapReferences = [.init(provider: "apple_maps", placeID: String(place.id.dropFirst("apple-maps:".count)),
                                            relationship: item.location.scope == .specificArea ? "within_place" : "same_place",
                                            verification: "reviewed", checkedAt: now)]
            }
            changed += ["/location/latitude", "/location/longitude", "/location/scope"]
            if !item.address.display.isEmpty { changed.append("/address") }
            let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(item)) as? [String: Any] ?? [:]
            changed = changed.filter { pointer in
                var value: Any? = encoded
                for key in pointer.dropFirst().split(separator: "/") { value = (value as? [String: Any])?[String(key)] }
                if value == nil || value is NSNull { return false }
                if let code = value as? String, code == "unknown" { return false }
                if let list = value as? [Any], list.isEmpty { return false }
                if let limit = value as? [String: Any], limit["status"] as? String == "unknown" { return false }
                return true
            }
        }
        guard !changed.isEmpty else { throw PrototypePublicationError.invalidContribution }
        let recordID = draft.id.uuidString
        var references = item.sourceReferences ?? []
        references.append(.init(sourceID: source.id, recordID: recordID))
        item.sourceReferences = references
        var evidence = item.provenance ?? []
        // This response describes current evidence. Earlier values/reasons remain in the private proposal history.
        evidence = evidence.compactMap { entry in
            var entry = entry
            entry.fields.removeAll { changed.contains($0) }
            return entry.fields.isEmpty ? nil : entry
        }
        evidence.append(.init(sourceID: source.id, method: "reviewed_contribution", fields: Array(Set(changed)).sorted(),
                              recordID: recordID, recordedAt: now))
        item.provenance = evidence
        return item
    }

    private static func baseline(_ draft: PlaceContributionDraft, current: CoolSpot?) -> CoolSpotsResponse.Item {
        let place = draft.selectedPlace
        let v = draft.values
        var item = CoolSpotsResponse.Item(id: current?.id ?? draft.id.uuidString, name: v.name,
                     location: .init(latitude: v.latitude, longitude: v.longitude, scope: .unknown),
                     address: place?.structuredAddress ?? .init(line1: nil, formatted: current?.address ?? place?.address,
                                                                line2: nil, borough: nil, locality: nil, countryCode: nil, postalCode: nil),
                     placeType: .unknown, setting: .unknown, coolingFeatures: [], coolingDetails: nil,
                     access: .init(cost: .unknown, eligibility: "unknown", seating: .unknown, drinkingWater: .unknown,
                                   toilets: .unknown, wheelchairAccess: .unknown, staffedWhenOpen: .unknown, tables: .unknown,
                                   eligibilityDetails: nil, instructions: nil, postedStayLimitMinutes: nil,
                                   postedStayLimit: .unknown),
                     hours: nil, sourceRecord: nil, appleMatch: nil, sourceReferences: [], mapReferences: [], photos: [])
        if let current {
            item.name = current.name
            item.placeType = .init(type: current.type)
            item.setting = .init(environment: current.environment)
            item.coolingFeatures = current.features.compactMap(CoolSpotFeature.init(feature:))
            item.coolingDetails = current.information.coolingDetails
            item.additionalInformation = current.information.additionalInformation
            item.access.cost = .init(access: current.access)
            item.access.seating = .init(seating: current.seating)
            item.access.eligibility = current.entryEligibility == .everyone ? "everyone" : current.entryEligibility == .limited ? "limited" : "unknown"
            item.access.eligibilityDetails = current.entryRequirement.nilIfEmpty
            item.access.drinkingWater = current.features.contains(.drinkingWater) ? .yes : .unknown
            item.access.toilets = .init(rawValue: current.information.toilets.rawValue) ?? .unknown
            item.access.wheelchairAccess = current.information.wheelchairAccessible.map { $0 ? .yes : .no } ?? .unknown
            item.access.staffedWhenOpen = current.information.staffedWhenOpen.map { $0 ? .yes : .no } ?? .unknown
            item.access.tables = current.information.tables.map { $0 ? .yes : .no } ?? .unknown
            item.access.areaDescription = current.information.areaDescription
            item.access.postedStayLimit = current.information.postedStayLimit
            item.photos = current.photos
            if let placeID = current.applePlaceID {
                item.mapReferences = [.init(provider: "apple_maps", placeID: placeID, relationship: "same_place", verification: "reviewed")]
            }
        }
        return item
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

extension CoolSpotAvailability {
    init(answer: OptionalFact) { self = answer == .yes ? .yes : answer == .no ? .no : .unknown }
}
extension CoolSpotSeating {
    init(seating: SeatingType) {
        self = switch seating { case .available: .yes; case .limited: .limited; case .none: .no; case .unsure: .unknown }
    }
}
extension CoolSpotCost {
    init(access: AccessType) {
        self = switch access { case .free: .free; case .purchase: .purchaseRequired; case .entryFee: .entryFee; case .unsure: .unknown }
    }
}
extension CoolSpotSetting {
    init(environment: PlaceEnvironment?) {
        self = switch environment { case .indoors: .indoors; case .outdoors: .outdoors; case .both: .both; default: .unknown }
    }
}
extension CoolSpotPlaceType {
    init(type: PlaceType?) {
        self = switch type {
        case .library: .library; case .publicService: .community; case .faith: .faith; case .culture: .culture
        case .leisure: .leisure; case .shop: .shop; case .food: .food; case .park: .park; case .square: .square
        case .waterside: .waterside; case .transport: .transport; case .other: .other; default: .unknown
        }
    }
}
extension CoolSpotFeature {
    init?(feature: CoolingFeature) {
        switch feature {
        case .airConditioning: self = .airConditioning; case .fans: self = .fans; case .coolerIndoors: self = .coolerIndoors
        case .treeShade: self = .treeShade; case .structuralShade: self = .structuralShade
        case .waterFeature: self = .waterNearby; case .ventilation: self = .ventilation
        case .drinkingWater: return nil
        }
    }
}
