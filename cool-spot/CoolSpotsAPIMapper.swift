import Foundation

struct CoolSpotAPIRecord {
    let schemaVersion: Int
    let datasetID: String
    let generatedAt: String
    let sources: [CoolSpotsAPIResponse.Source]
    let item: CoolSpotsAPIResponse.Item

    var applePlaceID: String? {
        acceptedMapReferences.first {
            $0.relationship == "same_place"
        }?.placeID
    }

    var detailsApplePlaceID: String? {
        applePlaceID ?? acceptedMapReferences.first {
            $0.relationship == "within_place"
        }?.placeID
    }

    var displayablePhotos: [PlacePhotoAsset] {
        let isExample = sources.first?.isExample == true

        return item.photos.filter { photo in
            guard photo.isDisplayable else { return false }

            return [photo.thumbnailURL, photo.imageURL].allSatisfy { url in
                url.scheme == "https" ||
                (url.scheme == "bundle" &&
                 isExample &&
                 photo.source == "illustration")
            }
        }
    }

    private var acceptedMapReferences: [CoolSpotsAPIResponse.Item.MapReference] {
        item.mapReferences.filter {
            $0.provider == "apple_maps" &&
            ["automatic", "reviewed"].contains($0.verification) &&
            !$0.placeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

extension CoolSpotsAPIResponse {
    func makeSpots() -> [CoolSpot] {
        let sourceByID = Dictionary(
            uniqueKeysWithValues: sources.map { ($0.id, $0) }
        )

        return items.map { item in
            var linkedSourceIDs = Set<String>()

            let linkedSources: [CoolSpotsAPIResponse.Source] =
                item.sourceReferences.compactMap { reference in
                    guard linkedSourceIDs.insert(reference.sourceID).inserted else {
                        return nil
                    }
                    return sourceByID[reference.sourceID]
                }

            let record = CoolSpotAPIRecord(
                schemaVersion: schemaVersion,
                datasetID: datasetID,
                generatedAt: generatedAt,
                sources: linkedSources,
                item: item
            )

            let primarySource = record.sources.first

            let sourceKind: SpotSource = switch primarySource?.provider {
            case "gla": .gla
            case "community": .community
            default: .unknown
            }

            let displayAddress: String
            if let formatted = item.address.formatted, !formatted.isEmpty {
                displayAddress = formatted
            } else {
                displayAddress = [
                    item.address.line1,
                    item.address.line2,
                    item.address.locality,
                    item.address.postalCode
                ]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            }

            var features = item.coolingFeatures.compactMap(\.feature)
            if item.access.drinkingWater == .yes {
                features.append(.drinkingWater)
            }

            let seating: SeatingType = switch item.access.seating {
            case .yes: .available
            case .limited: .limited
            case .no: .none
            case .unknown: .unsure
            }

            var spot = CoolSpot(
                id: item.id,
                name: item.name,
                address: displayAddress,
                latitude: item.location.latitude,
                longitude: item.location.longitude,
                source: sourceKind,
                environment: item.setting.environment,
                type: item.placeType.type,
                features: features,
                access: item.access.cost.access,
                seating: seating,
                distance: "",
                presenceCount: 0,
                experienceReports: [:],
                latestReportAt: .distantPast,
                stayReports: [:],
                comments: [],
                isNearby: false
            )

            spot.placeID = item.placeID
            spot.apiRecord = record
            spot.applePlaceID = record.applePlaceID
            spot.photos = record.displayablePhotos
            spot.entryEligibility = switch item.access.eligibility {
            case .everyone: .everyone
            case .limited: .limited
            case .unknown: .unknown
            }

            spot.information = PlaceInformation(
                source: .init(
                    label: primarySource?.label ?? "Source unknown",
                    url: primarySource?.url,
                    isExample: primarySource?.isExample ?? false
                ),
                coolingDetails: item.coolingDetails,
                hours: item.hours?.text,
                toilets: .init(rawValue: item.access.toilets.rawValue) ?? .unknown,
                wheelchairAccessible: item.access.wheelchairAccess.knownBool,
                staffedWhenOpen: item.access.staffedWhenOpen.knownBool,
                tables: item.access.tables.knownBool,
                areaDescription: item.access.areaDescription,
                postedStayLimit: item.access.postedStayLimit,
                additionalInformation: item.additionalInformation,
                drinkingWater: item.access.drinkingWater.knownBool
            )

            return spot
        }
    }
}

private extension CoolSpotAvailability {
    var knownBool: Bool? {
        switch self {
        case .yes: true
        case .no: false
        case .unknown: nil
        }
    }
}
