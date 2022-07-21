import Foundation

// MARK: - Country
public struct Country: Codable {
    public let name, dialCode, code: String
    public let emoji: String?

    enum CodingKeys: String, CodingKey {
        case name
        case dialCode = "dial_code"
        case code, emoji
    }

    public init(name: String, dialCode: String, code: String, emoji: String?) {
        self.name = name
        self.dialCode = dialCode
        self.code = code
        self.emoji = emoji
    }
}

public typealias Countries = [Country]
