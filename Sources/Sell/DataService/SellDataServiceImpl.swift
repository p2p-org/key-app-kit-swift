import Combine
import Foundation

final class SellDataServiceImpl: SellDataService {
    
    // MARK: - Associated type

    typealias Provider = MoonpaySellDataServiceProvider
    
    // MARK: - Dependencies

    private let priceProvider: SellPriceProvider
    @Injected private var userWalletManager: UserWalletManager
    @Injected private var sellTransactionsRepository: SellTransactionsRepository
    
    // MARK: - Properties

    private var provider = Provider()
    
    @SwiftyUserDefault(keyPath: \.isSellAvailable, options: .cached)
    private var cachedIsAvailable: Bool?
    
    @Published private var status: SellDataServiceStatus = .initialized
    var statusPublisher: AnyPublisher<SellDataServiceStatus, Never> {
        $status.eraseToAnyPublisher()
    }
    
    @Published private(set) var transactions: [SellDataServiceTransaction] = []
    var transactionsPublisher: AnyPublisher<[SellDataServiceTransaction], Never> {
        $transactions.eraseToAnyPublisher()
    }
    
    var currency: MoonpaySellDataServiceProvider.MoonpayCurrency?
    
    var fiat: Fiat?
    
    let userId: String
    
    // MARK: - Initializer
    init(userId: String, priceProvider: SellPriceProvider) {
        self.userId = userId
        self.priceProvider = priceProvider
    }
    
    // MARK: - Methods
    
    func isAvailable() async -> Bool {
        return true
        guard cachedIsAvailable == nil else {
            defer {
                Task {
                    do {
                        cachedIsAvailable = try await provider.isAvailable()
                    } catch {}
                }
            }
            return cachedIsAvailable ?? false
        }
        do {
            cachedIsAvailable = try await provider.isAvailable()
        } catch {
            return false
        }
        return (cachedIsAvailable ?? false)
    }
    
    func update() async {
        // mark as updating
        status = .updating
        
        // get currency
        do {
            let (currency, fiat, _) = try await(
                provider.currencies().filter({ $0.code.uppercased() == "SOL" }).first,
                provider.fiat(),
                updateIncompletedTransactions()
            )
            if currency == nil {
                throw SellDataServiceError.couldNotLoadSellData
            }
            self.currency = currency
            self.fiat = fiat
            status = .ready
        } catch {
            self.currency = nil
            self.fiat = nil
            status = .error(SellDataServiceError.couldNotLoadSellData)
            return
        }
    }
    
    func updateIncompletedTransactions() async throws {
        let txs = try await provider.sellTransactions(externalTransactionId: userId)
        
        let incompletedTransactions = try await withThrowingTaskGroup(of: SellDataServiceTransaction?.self) { group in
            var transactions = [SellDataServiceTransaction?]()
            
            for id in txs.map(\.id) {
                group.addTask { [weak self] in
                    guard let self = self else {return nil}
                    let detailed = try await self.provider.detailSellTransaction(id: id)
                    
                    let quoteCurrencyAmount = detailed.quoteCurrencyAmount ?? (self.priceProvider.currentPrice(for: "SOL")?.value ?? 0) * detailed.baseCurrencyAmount
                    guard
                        let usdRate = detailed.usdRate,
                        let eurRate = detailed.eurRate,
                        let gbpRate = detailed.gbpRate,
                        let depositWallet = detailed.depositWallet?.walletAddress,
                        let status = SellDataServiceTransaction.Status(rawValue: detailed.status.rawValue)
                    else { return nil }
                    
                    let dateFormatter = ISO8601DateFormatter()
                    dateFormatter.formatOptions =  [.withInternetDateTime, .withFractionalSeconds]
                    let createdAt = dateFormatter.date(from: detailed.createdAt)
                    
                    return SellDataServiceTransaction(
                        id: detailed.id,
                        createdAt: createdAt,
                        status: status,
                        baseCurrencyAmount: detailed.baseCurrencyAmount,
                        quoteCurrencyAmount: quoteCurrencyAmount,
                        usdRate: usdRate,
                        eurRate: eurRate,
                        gbpRate: gbpRate,
                        depositWallet: depositWallet
                    )
                }
            }
            
            // grab results
            for try await tx in group {
                transactions.append(tx)
            }
            
            return transactions
        }.compactMap {$0}
        
        await sellTransactionsRepository.setTransactions(incompletedTransactions)
        transactions = await sellTransactionsRepository.transactions
    }
    
    func getTransactionDetail(id: String) async throws -> Provider.Transaction {
        try await provider.detailSellTransaction(id: id)
    }

    func deleteTransaction(id: String) async throws {
        try await provider.deleteSellTransaction(id: id)
        await sellTransactionsRepository.deleteTransaction(id: id)
        transactions = await sellTransactionsRepository.transactions
    }
}
