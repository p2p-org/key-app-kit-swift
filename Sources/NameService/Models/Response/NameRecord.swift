public struct NameRecord: Codable {
    public let name: String?
    public let parent: String
    public let owner: String
    public let ownerClass: String

    enum CodingKeys: String, CodingKey {
        case parent
        case owner
        case ownerClass = "class"
        case name
    }
}
