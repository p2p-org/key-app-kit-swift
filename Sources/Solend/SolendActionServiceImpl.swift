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
    private let rpcUrl: String

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
        rpcUrl: String,
        lendingMark: String,
        userAccountStorage: SolanaAccountStorage,
        solend: Solend,
        solana: SolanaAPIClient,
        feeRelayApi: FeeRelayerAPIClient,
        feeRelay: FeeRelayer,
        feeRelayContextManager: FeeRelayerContextManager
    ) {
        self.rpcUrl = rpcUrl
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
        currentActionSubject.eraseToAnyPublisher()
    }

    public func clearAction() throws {
        currentActionSubject.send(nil)
    }

    public func check() async throws {
        if let currentAction = getCurrentAction() {
            switch currentAction.status {
            case .processing:
                throw SolendActionError.actionIsAlreadyRunning
            default: break
            }
        }
    }

    public func depositFee(amount: UInt64, symbol: SolendSymbol) async throws -> SolendDepositFee {
        let depositFee = try await solend.getDepositFee(
            rpcUrl: rpcUrl,
            owner: owner.publicKey.base58EncodedString,
            tokenAmount: amount,
            tokenSymbol: symbol
        )

        let feeRelayContext = try await feeRelayContextManager.getCurrentContext()
        let coveredByFeeRelay = feeRelayContext.usageStatus.currentUsage < feeRelayContext.usageStatus.maxUsage

        return .init(
            fee: coveredByFeeRelay ? 0 : depositFee.fee,
            rent: depositFee.rent
        )
    }

    public func deposit(
        amount: UInt64,
        symbol: String,
        feePayer: SolendFeePayer?
    ) async throws {
        do {
            try await check()

            let feeRelayContext = try await feeRelayContextManager.getCurrentContext()
            let useRelay = feeRelayContext.usageStatus.currentUsage < feeRelayContext.usageStatus.maxUsage
            let feePayerAddress: PublicKey = try useRelay ? feeRelayContext.feePayerAddress : owner.publicKey
            print(UInt32(
                feeRelayContext.usageStatus.maxUsage - feeRelayContext.usageStatus.currentUsage
            ))

            let transactionsRaw: [SolanaSerializedTransaction] = try await solend.createDepositTransaction(
                solanaRpcUrl: rpcUrl,
                relayProgramId: RelayProgram.id(network: .mainnetBeta).base58EncodedString,
                amount: amount,
                symbol: symbol,
                ownerAddress: owner.publicKey.base58EncodedString,
                environment: .production,
                lendingMarketAddress: lendingMark,
                blockHash: try await solana.getRecentBlockhash(commitment: nil),
                freeTransactionsCount: UInt32(
                    feeRelayContext.usageStatus.maxUsage - feeRelayContext.usageStatus.currentUsage
                ),
                needToUseRelay: useRelay,
                payInFeeToken: nil,
                feePayerAddress: feePayerAddress.base58EncodedString
            )

            let initialAction = SolendAction(
                type: .deposit,
                transactionID: nil,
                status: .processing,
                amount: amount,
                symbol: symbol
            )

            if useRelay {
                let depositFee = try await solend.getDepositFee(
                    rpcUrl: rpcUrl,
                    owner: owner.publicKey.base58EncodedString,
                    tokenAmount: amount,
                    tokenSymbol: symbol
                )

                var transactionFee = depositFee.fee
                let rentExemption = depositFee.rent
                if useRelay { transactionFee += feeRelayContext.lamportsPerSignature }

                try await relay(
                    transactionsRaw: transactionsRaw,
                    feeRelayContext: feeRelayContext,
                    fee: .init(transaction: transactionFee, accountBalances: rentExemption),
                    feePayer: feePayer,
                    initialAction: initialAction
                )
            } else {
                try await submitTransaction(
                    transactionsRaw: transactionsRaw,
                    initialAction: initialAction
                )
            }

        } catch {
            currentActionSubject.send(.init(
                type: .deposit,
                transactionID: nil,
                status: .failed(msg: error.localizedDescription),
                amount: amount,
                symbol: symbol
            ))
            throw error
        }
    }

    public func withdraw(
        amount: UInt64,
        symbol: SolendSymbol,
        feePayer: SolendFeePayer?
    ) async throws {
        do {
            try await check()

            let feeRelayContext = try await feeRelayContextManager.getCurrentContext()
            let needToUseRelay = feeRelayContext.usageStatus.currentUsage < feeRelayContext.usageStatus.maxUsage
            let feePayerAddress: PublicKey = try needToUseRelay ? feeRelayContext.feePayerAddress : owner.publicKey

            let transactionsRaw: [SolanaSerializedTransaction] = try await solend.createWithdrawTransaction(
                solanaRpcUrl: rpcUrl,
                relayProgramId: RelayProgram.id(network: .mainnetBeta).base58EncodedString,
                amount: amount,
                symbol: symbol,
                ownerAddress: owner.publicKey.base58EncodedString,
                environment: .production,
                lendingMarketAddress: lendingMark,
                blockHash: try await solana.getRecentBlockhash(commitment: nil),
                freeTransactionsCount: UInt32(
                    feeRelayContext.usageStatus.maxUsage - feeRelayContext.usageStatus.currentUsage
                ),
                needToUseRelay: needToUseRelay,
                payInFeeToken: nil,
                feePayerAddress: feePayerAddress.base58EncodedString
            )

            let initialAction = SolendAction(
                type: .withdraw,
                transactionID: nil,
                status: .processing,
                amount: amount,
                symbol: symbol
            )
            if needToUseRelay {
                try await relay(
                    transactionsRaw: transactionsRaw,
                    feeRelayContext: feeRelayContext,
                    fee: .zero,
                    feePayer: feePayer,
                    initialAction: initialAction
                )
            } else {
                try await submitTransaction(
                    transactionsRaw: transactionsRaw,
                    initialAction: initialAction
                )
            }
        } catch {
            currentActionSubject.send(.init(
                type: .withdraw,
                transactionID: nil,
                status: .failed(msg: error.localizedDescription),
                amount: amount,
                symbol: symbol
            ))
            throw error
        }
    }

    func submitTransaction(
        transactionsRaw: [SolanaSerializedTransaction],
        initialAction: SolendAction
    ) async throws {
        var ids: [String] = []

        // Sign transactions
        let transactions: [Transaction] = try transactionsRaw
            .map { (trx: String) -> Data in Data(Base58.decode(trx)) }
            .map { (trxData: Data) -> Transaction in
                var trx = try Transaction.from(data: trxData)
                try trx.sign(signers: [owner])
                return trx
            }

        for var transaction in transactions {
            let transactionID = try await solana.sendTransaction(
                transaction: try transaction.serialize().base64EncodedString(),
                configs: RequestConfiguration(encoding: "base64")!
            )
            ids.append(transactionID)
        }
        // Listen last transaction
        guard let primaryTrxId = ids.last else { throw SolanaError.unknown }
        Task.detached(priority: .utility) { [self] in
            try await listenTransactionStatus(
                transactionID: primaryTrxId,
                initialAction: initialAction
            )
        }
    }

    func relay(
        transactionsRaw: [SolanaSerializedTransaction],
        feeRelayContext: FeeRelayerContext,
        fee: FeeAmount,
        feePayer: SolendFeePayer?,
        initialAction: SolendAction
    ) async throws {
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
        // Allow only one transaction for using with relay. We can not calculate fee for others transactions
        guard transactions.count == 1 else { throw SolendActionError.expectedOneTransaction }

        // Setup fee payer
        let feePayer = try feePayer ?? .init(
            address: try owner.publicKey.base58EncodedString,
            mint: PublicKey.wrappedSOLMint.base58EncodedString
        )

        // Prepare transaction
        let preparedTransactions = try transactions.map { (trx: Transaction) -> PreparedTransaction in
            PreparedTransaction(
                transaction: trx,
                signers: [try owner],
                expectedFee: fee
            )
        }

        // Relay transaction
        let transactionsIDs = try await feeRelay.topUpAndRelayTransaction(
            feeRelayContext,
            preparedTransactions,
            fee: .init(
                address: try PublicKey(string: feePayer.address),
                mint: try PublicKey(string: feePayer.mint)
            ),
            config: .init(
                operationType: .other,
                autoPayback: false
            )
        )
        ids.append(contentsOf: transactionsIDs)

        // Listen last transaction
        guard let primaryTrxId = ids.last else { throw SolanaError.unknown }
        Task.detached(priority: .utility) { [self] in
            try await listenTransactionStatus(
                transactionID: primaryTrxId,
                initialAction: initialAction
            )
        }
    }

    func listenTransactionStatus(transactionID: TransactionID, initialAction: SolendAction) async throws {
        var action = initialAction
        action.transactionID = transactionID

        do {
            for try await status in solana.observeSignatureStatus(signature: transactionID) {
                let actionStatus: SolendActionStatus
                switch status {
                case .sending, .confirmed:
                    actionStatus = .processing
                case .finalized:
                    actionStatus = .success
                case let .error(msg):
                    actionStatus = .failed(msg: msg ?? "")
                }

                action.status = actionStatus
                currentActionSubject.send(action)

                if actionStatus == .success {
                    currentActionSubject.send(nil)
                    return
                }
            }
        }
    }

    public func getCurrentAction() -> SolendAction? {
        currentActionSubject.value
    }
}
