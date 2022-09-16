// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import FeeRelayerSwift
import Foundation
import P2PSwift
import SolanaSwift

public typealias SolendSymbol = P2PSwift.SolendSymbol
public typealias SolendUserDeposit = P2PSwift.SolendUserDeposit
public typealias SolendDepositFee = P2PSwift.SolendDepositFee
public typealias SolendConfigAsset = P2PSwift.SolendConfigAsset

public struct SolendMarketInfo: Codable {
    public let symbol: String
    public let currentSupply: String
    public let depositLimit: String
    public let supplyInterest: String

    public init(symbol: String, currentSupply: String, depositLimit: String, supplyInterest: String) {
        self.symbol = symbol
        self.currentSupply = currentSupply
        self.depositLimit = depositLimit
        self.supplyInterest = supplyInterest
    }
}

public protocol SolendService {
    var availableAssets: AnyPublisher<[SolendConfigAsset], Never> { get }
    var deposits: AnyPublisher<[SolendUserDeposit], Never> { get }
    var marketInfo: AnyPublisher<[SolendMarketInfo], Never> { get }

    func update() async throws

    func depositFee(amount: UInt64, symbol: SolendSymbol) async throws -> SolendDepositFee
    func deposit(amount: UInt64, symbol: String) async throws -> [TransactionID]
}

struct StaticAccountStorage: SolanaAccountStorage {
    private(set) var account: Account?

    func save(_: Account) throws {}
}

public class SolendServiceMock: SolendService {
    public init() {}

    public var availableAssets: AnyPublisher<[SolendConfigAsset], Never> {
        CurrentValueSubject([
            .init(
                name: "Wrapped SOL",
                symbol: "SOL",
                decimals: 9,
                mintAddress: "So11111111111111111111111111111111111111112",
                logo: "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png"
            ),
            .init(
                name: "USDC",
                symbol: "USD Coin",
                decimals: 6,
                mintAddress: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
                logo: "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v/logo.png"
            ),
            .init(
                name: "Wrapped Bitcoin (Sollet)",
                symbol: "BTC",
                decimals: 9,
                mintAddress: "9n4nbM75f5Ui33ZbPYXn59EwSgE8CGsHtAeTH5YFeJ9E",
                logo: "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/9n4nbM75f5Ui33ZbPYXn59EwSgE8CGsHtAeTH5YFeJ9E/logo.png"
            )
        
        ]).eraseToAnyPublisher()
    }

    public var deposits: AnyPublisher<[SolendUserDeposit], Never> {
        CurrentValueSubject([
            .init(symbol: "USDT", depositedAmount: "3096.19231"),
            .init(symbol: "SOL", depositedAmount: "23.8112"),
        ]).eraseToAnyPublisher()
    }

    public var marketInfo: AnyPublisher<[SolendMarketInfo], Never> {
        CurrentValueSubject([
            .init(symbol: "USDT", currentSupply: "0", depositLimit: "0", supplyInterest: "3.0521312"),
            .init(symbol: "SOL", currentSupply: "0", depositLimit: "0", supplyInterest: "2.4312123"),
            .init(symbol: "USDC", currentSupply: "0", depositLimit: "0", supplyInterest: "2.21321312"),
            .init(symbol: "ETH", currentSupply: "0", depositLimit: "0", supplyInterest: "0.78321312"),
            .init(symbol: "BTC", currentSupply: "0", depositLimit: "0", supplyInterest: "0.042321321"),
        ]).eraseToAnyPublisher()
    }

    public func update() async throws {}

    public func depositFee(amount _: UInt64, symbol _: SolendSymbol) async throws -> SolendDepositFee {
        .init(fee: 0, rent: 0)
    }

    public func deposit(amount _: UInt64, symbol _: String) async throws -> [TransactionID] {
        []
    }
}

public class SolendServiceImpl: SolendService {
    private let solend: Solend
    private let solana: SolanaAPIClient

    private let feeRelayApi: FeeRelayerAPIClient
    private let feeRelay: FeeRelayer
    private let feeRelayContextManager: FeeRelayerContextManager

    private var owner: Account
    private var lendingMark: String

    private let allowerdSymbols = ["SOL", "USDC", "USDT", "ETH", "BTC"]
    public let availableAssetsSubject: CurrentValueSubject<[SolendConfigAsset], Never> = .init([])
    public var availableAssets: AnyPublisher<[SolendConfigAsset], Never> { availableAssetsSubject.eraseToAnyPublisher() }

    public let depositsSubject: CurrentValueSubject<[SolendUserDeposit], Never> = .init([])
    public var deposits: AnyPublisher<[SolendUserDeposit], Never> { depositsSubject.eraseToAnyPublisher() }

    public let marketInfoSubject: CurrentValueSubject<[SolendMarketInfo], Never> = .init([])
    public var marketInfo: AnyPublisher<[SolendMarketInfo], Never> { marketInfoSubject.eraseToAnyPublisher() }

    public init(
        solend: Solend,
        solana: SolanaAPIClient,
        feeRelayApi: FeeRelayerAPIClient,
        feeRelay: FeeRelayer,
        feeRelayContextManager: FeeRelayerContextManager,
        owner: Account,
        lendingMark: String
    ) {
        self.solend = solend
        self.owner = owner
        self.lendingMark = lendingMark

        self.solana = solana
        self.feeRelayApi = feeRelayApi
        self.feeRelay = feeRelay
        self.feeRelayContextManager = feeRelayContextManager
    }

    public var hasDeposits: Bool {
        depositsSubject.value.first { (Double($0.depositedAmount) ?? 0) > 0 } != nil
    }
    
    public func update() async throws {
        // Get config first
        if availableAssetsSubject.value.isEmpty {
            let config: SolendConfig = try await solend.getConfig(environment: .production)
            let filteredAssets = config.assets.filter { allowerdSymbols.contains($0.symbol) }
            availableAssetsSubject.send(filteredAssets)
        }
        
        await updateValues(
            marketInfo: try? solend
                .getMarketInfo(symbols: availableAssetsSubject.value.map(\.symbol), pool: "main")
                .map { token, marketInfo -> SolendMarketInfo in .init(
                    symbol: token,
                    currentSupply: marketInfo.currentSupply,
                    depositLimit: marketInfo.currentSupply,
                    supplyInterest: marketInfo.supplyInterest
                ) },
            deposits: try? solend.getUserDeposits(
                owner: owner.publicKey.base58EncodedString,
                poolAddress: lendingMark
            )
        )
    }

    public func updateValues(
        marketInfo: [SolendMarketInfo]?,
        deposits: [SolendUserDeposit]?
    ) {
        depositsSubject.send(deposits ?? [])
        marketInfoSubject.send(marketInfo ?? [])
    }

    public func depositFee(amount: UInt64, symbol: SolendSymbol) async throws -> SolendDepositFee {
        try await solend.getDepositFee(
            rpcUrl: "https://p2p.rpcpool.com/82313b15169cb10f3ff230febb8d",
            owner: owner.publicKey.base58EncodedString,
            tokenAmount: amount,
            tokenSymbol: symbol
        )
    }

    public func deposit(amount: UInt64, symbol: String) async throws -> [TransactionID] {
        let feeRelayContext = try await feeRelayContextManager.getCurrentContext()

        do {
            let transactionsRaw = try await solend.createDepositTransaction(
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
            print(transactionsRaw)
            let d = Data(Base58.decode(transactionsRaw.first!))
            print(d.base64EncodedString())
            
            print(transactionsRaw.first)
            
            let transactions = try transactionsRaw
                .map { (trx: String) -> Data in Data(Base58.decode(trx)) }
                .map { (trxData: Data) -> Transaction in
                    var trx = try Transaction.from(data: trxData)
                    try trx.sign(signers: [owner])
                    return trx
                }

            print(transactions.count)
            print(transactions.first?.instructions.count)
            print(transactions.first?.signatures)
            print(transactions.first)
            
//            var t1 = transactions.first!
//            let t: Data = try t1.serialize()
//            print(try JSONSerialization.jsonObject(with: t))

            var ids: [String] = []
            for var trx in transactions {
//                let id = try await feeRelayApi.sendTransaction(.relayTransaction(.init(preparedTransaction: .init(transaction: trx, signers: [owner], expectedFee: .zero))))
//                ids.append(id)
                print(try trx.serialize().base64EncodedString())
                ids.append(try await solana.sendTransaction(transaction: try trx.serialize(requiredAllSignatures: true, verifySignatures: true).base64EncodedString(), configs: RequestConfiguration(encoding: "base64", skipPreflight: true)!))
            }

            Task { try await update() }

            return ids
        } catch {
            print(error)
            throw error
        }
    }
}
