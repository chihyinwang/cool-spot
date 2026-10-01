import Foundation

extension CoolSpotsAPIResponse {
    func makeSpots() -> [CoolSpot] {
        let sourceByID = Dictionary(
            uniqueKeysWithValues: sources.map { ($0.id, $0) }
        )

        return items.map { item in
            let primarySource = item.sourceReferences.first.flatMap {
                sourceByID[$0.sourceID]
            }

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
