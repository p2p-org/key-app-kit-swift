import Foundation

// MARK: - Country
public struct Country: Codable, Hashable {
    public let name: String
    public let code: String
    public let countryCallingCodes: [String]
    public let emoji: String?
    public var dialCode: String
    var status: Status?

    enum CodingKeys: String, CodingKey {
        case name
        case code = "alpha2"
        case countryCallingCodes
        case emoji
        case status
    }

    public init(name: String, dialCode: String, code: String, emoji: String?) {
        self.name = name
        self.code = code
        self.dialCode = dialCode
        self.emoji = emoji
        self.countryCallingCodes = [dialCode]
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.code = try container.decode(String.self, forKey: .code)
        self.countryCallingCodes = try container.decode([String].self, forKey: .countryCallingCodes)
        self.emoji = try? container.decode(String.self, forKey: .emoji)
        self.status = try? container.decode(Status.self, forKey: .status)
        self.dialCode = self.countryCallingCodes.first ?? ""
    }

    enum Status: String, Codable {
        case assigned
        case reserved
        case deleted
        case userAssigned = "user assigned"
    }
}

public typealias Countries = [Country]
