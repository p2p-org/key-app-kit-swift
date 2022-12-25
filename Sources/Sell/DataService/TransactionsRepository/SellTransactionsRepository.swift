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
    
    /// Delete transaction
    func deleteTransaction(id: String)
    
    /// Mark transactionas completed
    func markAsCompleted(id: String)
}

public actor SellTransactionsRepositoryImpl: SellTransactionsRepository {
    
    // MARK: - Properties

    /// Transactions subject
    @Published public var transactions: [SellDataServiceTransaction] = []
    
    /// Key for storing deletedTransactionIds in UserDefaults
    private static let deletedTransactionIdsKey = "SellTransactionsRepository.deletedTransactionIds"
    
    /// Key for storing completedTransactionIds in UserDefaults
    private static let completedTransactionIdsKey = "SellTransactionsRepository.completedTransactionIds"
    
    /// Deleted transactions id
    private var deletedTransactionIds: [String] {
        didSet {
            guard let data = try? JSONEncoder().encode(deletedTransactionIds) else {
                return
            }
            UserDefaults.standard.set(data, forKey: Self.deletedTransactionIdsKey)
        }
    }
    
    /// Completed transactions id
    private var completedTransactionIds: [String] {
        didSet {
            guard let data = try? JSONEncoder().encode(completedTransactionIds) else {
                return
            }
            UserDefaults.standard.set(data, forKey: Self.completedTransactionIdsKey)
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
        
        // retrieve completed transaction ids
        if let data = UserDefaults.standard.data(forKey: Self.completedTransactionIdsKey),
           let array = try? JSONDecoder().decode([String].self, from: data)
        {
            completedTransactionIds = array
        } else {
            completedTransactionIds = []
        }
    }
    
    // MARK: - Methods
    /// Set transactions
    public func setTransactions(_ transactions: [SellDataServiceTransaction]) {
        // filter out all deleted transactions
        var transactions = transactions.filter { !deletedTransactionIds.contains($0.id) }
        
        // remap all completed transaction
        transactions = transactions.map { transaction in
            var transaction = transaction
            if completedTransactionIds.contains(transaction.id) {
                transaction.status = .completed
            }
            return transaction
        }
        
        self.transactions = transactions
    }
    
    /// Delete transaction
    public func deleteTransaction(id: String) {
        var transactions = transactions
        transactions.removeAll(where: {$0.id == id})
        self.transactions = transactions
        deletedTransactionIds.append(id)
    }
    
    /// Mark transactionas completed
    public func markAsCompleted(id: String) {
        guard let index = transactions.firstIndex(where: {$0.id == id}) else {
            return
        }
        var transactions = transactions
        transactions[index].status = .completed
        self.transactions = transactions
        completedTransactionIds.append(id)
    }
}
