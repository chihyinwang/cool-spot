import Foundation

// Public read values preserve answers independently of their English form labels.
struct CatalogStayLimit: Codable, Equatable {
    enum Status: String, Codable { case unknown, limited, noStatedLimit = "no_stated_limit" }
    var status: Status
    var minutes: Int?
    static let unknown = Self(status: .unknown, minutes: nil)

    var isValid: Bool { status == .limited ? (minutes ?? 0) > 0 : minutes == nil }
    var label: String? {
        switch status {
        case .unknown: nil
        case .noStatedLimit: "No stated time limit"
        case .limited: minutes.map { "Stay limit: \($0) minutes" }
        }
    }
    var formValue: String {
        switch status {
        case .unknown: ""
        case .noStatedLimit: "No stated limit"
        case .limited:
            switch minutes {
            case 30: "30 minutes"
            case 60: "1 hour"
            case 120: "2 hours"
            case .some(let value): "\(value / 60) hr \(value % 60) min"
            case nil: ""
            }
        }
    }
    static func fromForm(_ value: String) throws -> Self {
        switch value {
        case "", "Not sure": return .unknown
        case "No stated limit": return .init(status: .noStatedLimit, minutes: nil)
        case "30 minutes": return .init(status: .limited, minutes: 30)
        case "1 hour": return .init(status: .limited, minutes: 60)
        case "2 hours": return .init(status: .limited, minutes: 120)
        default:
            let parts = value.split(separator: " ")
            if parts.count == 4, parts[1] == "hr", parts[3] == "min",
               let h = Int(parts[0]), let m = Int(parts[2]), (0...24).contains(h), (0...59).contains(m), h + m > 0 {
                return .init(status: .limited, minutes: h * 60 + m)
            }
            // Existing draft strings used this representation.
            if parts.count == 2, parts[1] == "minutes", let m = Int(parts[0]), m > 0 {
                return .init(status: .limited, minutes: m)
            }
            throw PrototypePublicationError.invalidTimeLimit
        }
    }
}

enum PrototypePublicationError: LocalizedError {
    case invalidTimeLimit, changedSinceSubmission, missingPhoto, invalidContribution, duplicatePlace
    var errorDescription: String? {
        switch self {
        case .invalidTimeLimit: "Choose a valid posted time limit."
        case .changedSinceSubmission: "A detail changed after this proposal was sent. Review the current place before applying it."
        case .missingPhoto: "The submitted photo could not be read. Add it again before publishing."
        case .invalidContribution: "This contribution needs correction before it can be published."
        case .duplicatePlace: "This place already has cooling information. Review it as an update."
        }
    }
}
