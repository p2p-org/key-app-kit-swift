import Foundation

enum SellActionServiceError: Error {
    case invalidURL
}

public protocol SellActionServiceQuote {
    var extraFeeAmount: Double { get }
    var feeAmount: Double { get }
    var baseCurrencyPrice: Double { get }
    var quoteCurrencyAmount: Double { get }
}

public protocol SellActionService {
    associatedtype Provider: SellActionServiceProvider

    func sellQuote(
        baseCurrencyCode: String,
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        extraFeePercentage: Double
    ) async throws -> Provider.Quote

    func createSellURL(
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        externalTransactionId: String
    ) throws -> URL
}
