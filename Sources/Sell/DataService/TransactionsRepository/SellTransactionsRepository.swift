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
    
    // MARK: - Initializer
    public init() {}
    
    // MARK: - Methods
    /// Set transactions
    public func setTransactions(_ transactions: [SellDataServiceTransaction]) {
        self.transactions = transactions
    }
    
    /// Delete transaction
    public func deleteTransaction(id: String) {
        transactions.removeAll(where: {$0.id == id})
    }
}
