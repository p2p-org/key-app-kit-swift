import Foundation

public enum SellDataServiceStatus {
    case initialized
    case updating
    case ready
    case error(Error)
    
    var isReady: Bool {
        switch self {
        case .ready:
            return true
        default:
            return false
        }
    }
}

public protocol ProviderCurrency: Equatable {
    var id: String { get }
    var name: String { get }
    var code: String { get }
    var minSellAmount: Double? { get }
    var maxSellAmount: Double? { get }
}

public protocol ProviderFiat: Equatable {
//    var id: String { get }
//    var name: String { get }
//    var code: String { get }
//    var minSellAmount: Double? { get }
//    var maxSellAmount: Double? { get }
}

public protocol ProviderTransaction: Hashable {
    var id: String { get }
//    var status: String { get }
    var baseCurrencyAmount: Double { get }
    var depositWalletId: String { get }
}

public struct SellDataServiceTransaction: Hashable {
    var id: String
    var createdAt: Date?
    var status: Status
    var baseCurrencyAmount: Double
    var quoteCurrencyAmount: Double
    var usdRate: Double
    var eurRate: Double
    var gbpRate: Double
    var depositWallet: String
    
    enum Status: String {
        case waitingForDeposit
        case pending
        case failed
        case completed
    }
}

public enum SellDataServiceError: Error {
    case couldNotLoadSellData
}

public protocol SellPriceProvider {
    func getCurrentPrice(for tokenSymbol: String) -> Double?
}
