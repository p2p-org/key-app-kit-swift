import Foundation

class MoonpaySellActionService: SellActionService {
    typealias Provider = MoonpaySellActionServiceProvider
    private var provider = Provider()
    
    private let refundWalletAddress: String

    init(refundWalletAddress: String) {
        self.refundWalletAddress = refundWalletAddress
    }

    func sellQuote(
        baseCurrencyCode: String,
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        extraFeePercentage: Double
    ) async throws -> Provider.Quote {
        try await provider.sellQuote(
            baseCurrencyCode: baseCurrencyCode,
            quoteCurrencyCode: quoteCurrencyCode,
            baseCurrencyAmount: baseCurrencyAmount
        )
    }

    func createSellURL(
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        externalTransactionId: String
    ) throws -> URL {
        let endpoint: String
        let apiKey: String
        switch Defaults.moonpayEnvironment {
        case .production:
            endpoint = .secretConfig("MOONPAY_PRODUCTION_SELL_ENDPOINT")!
            apiKey = .secretConfig("MOONPAY_PRODUCTION_API_KEY")!
        case .sandbox:
            endpoint = .secretConfig("MOONPAY_STAGING_SELL_ENDPOINT")!
            apiKey = .secretConfig("MOONPAY_STAGING_API_KEY")!
        }

        var components = URLComponents(string: endpoint + "sell")!
        components.queryItems = [
            .init(name: "apiKey", value: apiKey),
            .init(name: "baseCurrencyCode", value: "sol"),
            .init(name: "refundWalletAddress", value: refundWalletAddress),
            .init(name: "quoteCurrencyCode", value: quoteCurrencyCode),
            .init(name: "baseCurrencyAmount", value: baseCurrencyAmount.toString()),
            .init(name: "externalTransactionId", value: externalTransactionId),
            .init(name: "externalCustomerId", value: externalTransactionId)
        ]

        guard let url = components.url else {
            throw SellActionServiceError.invalidURL
        }
        return url
    }

    func saveTransaction() async throws {}
    func deleteTransaction() async throws {}
}
