import Combine
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

public enum SellPriceProvider {
    func currentPrice(for tokenSymbol: String) -> Double?
}

public protocol SellDataService {
    associatedtype Provider: SellDataServiceProvider
    
    /// Status of service
    var statusPublisher: AnyPublisher<SellDataServiceStatus, Never> { get }
    
    /// Publisher that emit sell transactions every time when any transaction is updated
    var transactionsPublisher: AnyPublisher<[SellDataServiceTransaction], Never> { get }
    
    /// Get current loaded transactions
    var transactions: [SellDataServiceTransaction] { get }
    
    /// Get current currency
    var currency: Provider.Currency? { get }
    
    /// Get fiat
    var fiat: Fiat? { get }
    
    /// Get userId
    var userId: String { get }
    
    /// Check if service available
    func isAvailable() async -> Bool
    
    /// Request for pendings, rates, min amounts
    func update() async
    
    /// Retrieve all incompleted transactions
    func updateIncompletedTransactions() async throws
    
    /// Get transaction with id
    func getTransactionDetail(id: String) async throws -> Provider.Transaction
    
    /// Delete transaction from list
    func deleteTransaction(id: String) async throws
}
