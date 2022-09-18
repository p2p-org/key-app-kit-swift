// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import FeeRelayerSwift
import Foundation
import P2PSwift
import SolanaSwift

public class SolendActionServiceImpl: SolendActionService {
    private let lendingMark: String
    private let userAccountStorage: SolanaAccountStorage

    private let solend: Solend
    private let solana: SolanaAPIClient

    private let feeRelayApi: FeeRelayerAPIClient
    private let feeRelay: FeeRelayer
    private let feeRelayContextManager: FeeRelayerContextManager

    private var owner: Account {
        get throws {
            guard let account = userAccountStorage.account else {
                throw SolanaError.unauthorized
            }
            return account
        }
    }

    public init(
        lendingMark: String,
        userAccountStorage: SolanaAccountStorage,
        solend: Solend,
        solana: SolanaAPIClient,
        feeRelayApi: FeeRelayerAPIClient,
        feeRelay: FeeRelayer,
        feeRelayContextManager: FeeRelayerContextManager
    ) {
        self.lendingMark = lendingMark
        self.userAccountStorage = userAccountStorage
        self.solend = solend
        self.solana = solana
        self.feeRelayApi = feeRelayApi
        self.feeRelay = feeRelay
        self.feeRelayContextManager = feeRelayContextManager
    }

    private let currentActionSubject: CurrentValueSubject<SolendAction?, Never> = .init(nil)
    public var currentAction: AnyPublisher<SolendAction?, Never> {
        CurrentValueSubject(nil).eraseToAnyPublisher()
    }

    public func clearAction() throws {}

    public func check() async throws {
        guard currentActionSubject.value == nil else {
            throw SolendActionError.actionIsAlreadyRunning
        }
    }

    public func depositFee(amount: UInt64, symbol: SolendSymbol) async throws -> SolendDepositFee {
        try await solend.getDepositFee(
            rpcUrl: "https://p2p.rpcpool.com/82313b15169cb10f3ff230febb8d",
            owner: owner.publicKey.base58EncodedString,
            tokenAmount: amount,
            tokenSymbol: symbol
        )
    }

    public func deposit(amount: UInt64, symbol: String) async throws {
        try await check()

        // let feeRelayContext = try await feeRelayContextManager.getCurrentContext()

        let transactionsRaw: [SolanaSerializedTransaction] = try await solend.createDepositTransaction(
            solanaRpcUrl: "https://p2p.rpcpool.com/82313b15169cb10f3ff230febb8d",
            relayProgramId: RelayProgram.id(network: .mainnetBeta).base58EncodedString,
            amount: amount,
            symbol: symbol,
            ownerAddress: owner.publicKey.base58EncodedString,
            environment: .production,
            lendingMarketAddress: lendingMark,
            blockHash: try await solana.getRecentBlockhash(commitment: nil),
            freeTransactionsCount: 0,
            needToUseRelay: false,
            payInFeeToken: nil,
            feePayerAddress: owner.publicKey.base58EncodedString
        )

        // Sign transactions
        let transactions: [Transaction] = try transactionsRaw
            .map { (trx: String) -> Data in Data(Base58.decode(trx)) }
            .map { (trxData: Data) -> Transaction in
                var trx = try Transaction.from(data: trxData)
                try trx.sign(signers: [owner])
                return trx
            }

        // Send transactions
        var ids: [String] = []
        for var trx in transactions {
            let transactionID: TransactionID = try await solana.sendTransaction(
                transaction: try trx.serialize().base64EncodedString(),
                configs: RequestConfiguration(encoding: "base64")!
            )
            ids.append(transactionID)
        }

        // Listen last transaction
        guard let primaryTrxId = ids.last else { throw SolanaError.unknown }
        Task.detached(priority: .utility) { [self] in
            try await listenTransactionStatus(
                transactionID: primaryTrxId,
                initialAction: .init(
                    type: .deposit,
                    transactionID: primaryTrxId,
                    status: .processing,
                    amount: amount,
                    symbol: symbol
                )
            )
        }
    }

    public func withdraw(amount: UInt64, symbol: SolendSymbol) async throws {
        try await check()

        // let feeRelayContext = try await feeRelayContextManager.getCurrentContext()

        let transactionsRaw: [SolanaSerializedTransaction] = try await solend.createWithdrawTransaction(
            solanaRpcUrl: "https://p2p.rpcpool.com/82313b15169cb10f3ff230febb8d",
            relayProgramId: RelayProgram.id(network: .mainnetBeta).base58EncodedString,
            amount: amount,
            symbol: symbol,
            ownerAddress: owner.publicKey.base58EncodedString,
            environment: .production,
            lendingMarketAddress: lendingMark,
            blockHash: try await solana.getRecentBlockhash(commitment: nil),
            freeTransactionsCount: 0,
            needToUseRelay: false,
            payInFeeToken: nil,
            feePayerAddress: owner.publicKey.base58EncodedString
        )

        // Sign transactions
        let transactions: [Transaction] = try transactionsRaw
            .map { (trx: String) -> Data in Data(Base58.decode(trx)) }
            .map { (trxData: Data) -> Transaction in
                var trx = try Transaction.from(data: trxData)
                try trx.sign(signers: [owner])
                return trx
            }

        // Send transactions
        var ids: [String] = []
        for var trx in transactions {
            let transactionID: TransactionID = try await solana.sendTransaction(
                transaction: try trx.serialize().base64EncodedString(),
                configs: RequestConfiguration(encoding: "base64")!
            )
            ids.append(transactionID)
        }

        // Listen last transaction
        guard let primaryTrxId = ids.last else { throw SolanaError.unknown }
        Task.detached(priority: .utility) { [self] in
            try await listenTransactionStatus(
                transactionID: primaryTrxId,
                initialAction: .init(
                    type: .withdraw,
                    transactionID: primaryTrxId,
                    status: .processing,
                    amount: amount,
                    symbol: symbol
                )
            )
        }
    }

    func listenTransactionStatus(transactionID: TransactionID, initialAction: SolendAction) async throws {
        var action = initialAction
        for try await status in solana.observeSignatureStatus(signature: transactionID) {
            let actionStatus: SolendActionStatus
            switch status {
            case .sending, .confirmed: actionStatus = .processing
            case .finalized: actionStatus = .success
            case let .error(msg): actionStatus = .failed(msg: msg ?? "")
            }

            action.status = actionStatus
            currentActionSubject.send(action)
        }
    }
}
