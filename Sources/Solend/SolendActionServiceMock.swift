// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation

public class SolendActionServiceMock: SolendActionService {
    let currentActionSubject: CurrentValueSubject<SolendAction?, Never> = .init(nil)

    public init(currentAction: SolendAction? = nil) {
        currentActionSubject.send(currentAction)
    }

    public var currentAction: AnyPublisher<SolendAction?, Never> {
        currentActionSubject.eraseToAnyPublisher()
    }

    public func clearAction() throws {}

    public func depositFee(amount _: UInt64, symbol _: SolendSymbol) async throws -> SolendDepositFee {
        .init(fee: 0, rent: 0)
    }

    public func deposit(amount: UInt64, symbol: SolendSymbol,fee: SolendDepositFee, feePayer: SolendFeePayer?) async throws {
        await mockProcessing(id: "123456", type: .deposit, amount: amount, symbol: symbol)
    }

    public func withdraw(amount: UInt64, symbol: SolendSymbol, fee: SolendDepositFee,feePayer: SolendFeePayer?) async throws {
        await mockProcessing(id: "123456", type: .withdraw, amount: amount, symbol: symbol)
    }

    private func mockProcessing(id: String, type: SolendActionType, amount: UInt64, symbol: SolendSymbol) async {
        let action = SolendAction(
            type: type,
            transactionID: id,
            status: .processing,
            amount: amount,
            symbol: symbol
        )

        currentActionSubject.send(action)

        Task.detached { [currentActionSubject] in
            for _ in 0 ... 5 {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                let action = SolendAction(
                    type: .withdraw,
                    transactionID: id,
                    status: .processing,
                    amount: amount,
                    symbol: symbol
                )
                currentActionSubject.send(action)
            }

            let action = SolendAction(
                type: .withdraw,
                transactionID: id,
                status: .success,
                amount: amount,
                symbol: symbol
            )
            currentActionSubject.send(action)

            try await Task.sleep(nanoseconds: 1_000_000_000)
            currentActionSubject.send(nil)
        }
    }
    
    public func getCurrentAction() -> SolendAction? {
        currentActionSubject.value
    }
}
