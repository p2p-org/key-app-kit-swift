//
//  SellTransactionsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/12/2022.
//

import Foundation
import Combine

/// Repository that control the flow of sell transactions
public protocol SellTransactionsRepository: Actor {
    /// Get/Set current fetched transactions
    var transactions: [SellDataServiceTransaction] { get }
    
    /// Set transactions
    func setTransactions(_ transactions: [SellDataServiceTransaction])
    
    /// Delete transactions
    func deleteTransaction(id: String)
}

public actor SellTransactionsRepositoryImpl: SellTransactionsRepository {
    
    // MARK: - Properties

    /// Transactions subject
    @Published public var transactions: [SellDataServiceTransaction] = []
    
    /// Key for storing deletedTransactionIds in UserDefaults
    private static let deletedTransactionIdsKey = "SellTransactionsRepository.deletedTransactionIds"
    
    /// Deleted transactions id
    private var deletedTransactionIds: [String] {
        didSet {
            guard let data = try? JSONEncoder().encode(deletedTransactionIds) else {
                return
            }
            UserDefaults.standard.set(data, forKey: Self.deletedTransactionIdsKey)
        }
    }
    
    // MARK: - Initializer
    public init() {
        // retrieve deleted transaction ids
        if let data = UserDefaults.standard.data(forKey: Self.deletedTransactionIdsKey),
           let array = try? JSONDecoder().decode([String].self, from: data)
        {
            deletedTransactionIds = array
        } else {
            deletedTransactionIds = []
        }
    }
    
    // MARK: - Methods
    /// Set transactions
    public func setTransactions(_ transactions: [SellDataServiceTransaction]) {
        self.transactions = transactions.filter { !deletedTransactionIds.contains($0.id) }
    }
    
    /// Delete transaction
    public func deleteTransaction(id: String) {
        transactions.removeAll(where: {$0.id == id})
        deletedTransactionIds.append(id)
    }
}
