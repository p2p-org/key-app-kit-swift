import Foundation

public enum PricesProviderError: Error {
    case invalidURL
    case invalidResponseStatusCode(Int?)
}
