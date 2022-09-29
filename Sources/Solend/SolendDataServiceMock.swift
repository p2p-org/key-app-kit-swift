// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import SolanaSwift

public class SolendDataServiceMock: SolendDataService {
    public init() {}
    
    public var error: AnyPublisher<Error?, Never> {
        CurrentValueSubject(nil)
            .eraseToAnyPublisher()
    }
    
    public var availableAssets: AnyPublisher<[SolendConfigAsset]?, Never> {
        CurrentValueSubject([
            SolendConfigAsset.Mock.sol,
            SolendConfigAsset.Mock.usdc,
            SolendConfigAsset.Mock.btc,
        ]).eraseToAnyPublisher()
    }

    public var deposits: AnyPublisher<[SolendUserDeposit]?, Never> {
        CurrentValueSubject([
            .init(symbol: "USDT", depositedAmount: "3096.19231"),
            .init(symbol: "SOL", depositedAmount: "23.8112"),
        ]).eraseToAnyPublisher()
    }

    public var marketInfo: AnyPublisher<[SolendMarketInfo]?, Never> {
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

    public var status: Combine.AnyPublisher<SolendDataStatus, Never> {
        CurrentValueSubject(.ready).eraseToAnyPublisher()
    }
}
