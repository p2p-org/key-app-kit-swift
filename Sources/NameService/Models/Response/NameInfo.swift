struct NameInfo: Codable {
    public let parent: String
    public let ownerClass: String
    public let name: String?
    public let address: String
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case parent, address, updatedAt, name
        case ownerClass = "class"
    }
}
