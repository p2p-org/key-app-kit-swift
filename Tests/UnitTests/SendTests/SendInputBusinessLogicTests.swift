// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import NameService
import XCTest
@testable import Send

class SendInputBusinessLogicTests: XCTestCase {
    let defaultUserWalletState: UserWalletEnvironments = .init(
        wallets: [.nativeSolana(pubkey: "8JmwhqewSppZ2sDNqGZoKu3bWh8wUKZP8mdbP4M1XQx1", lamport: 30_000_000)],
        exchangeRate: ["SOL": .init(value: 12.5)]
    )

    let services: SendInputServices = .init(swapService: MockedSwapService(result: nil))

    /// Change input amount
    ///
    /// Token: SOL
    func testChangeAmountInToken() async throws {
        let initialState = SendInputState.zero(
            recipient: .init(
                address: "5bYReP8iw5UuLVS5wmnXfEfrYCKdiQ1FFAZQao8JqY7V",
                category: .solanaAddress,
                hasFunds: true
            ),
            token: .nativeSolana,
            feeToken: .nativeSolana,
            userWalletState: defaultUserWalletState
        )

        let nextState = await SendInputBusinessLogic.sendInputBusinessLogic(
            state: initialState,
            action: .changeAmountInToken(0.001),
            services: services
        )

        XCTAssertEqual(nextState.amountInToken, 0.001)
        XCTAssertEqual(nextState.amountInFiat, 0.0125)
        XCTAssertEqual(nextState.status, .ready)
    }

    /// Change input amount to max
    ///
    /// Token: SOL
    func testChangeMaxAmountInToken() async throws {
        let initialState = SendInputState.zero(
            recipient: .init(
                address: "5bYReP8iw5UuLVS5wmnXfEfrYCKdiQ1FFAZQao8JqY7V",
                category: .solanaAddress,
                hasFunds: true
            ),
            token: .nativeSolana,
            feeToken: .nativeSolana,
            userWalletState: defaultUserWalletState
        )

        let nextState = await SendInputBusinessLogic.sendInputBusinessLogic(
            state: initialState,
            action: .changeAmountInToken(initialState.maxAmountInputInToken),
            services: services
        )

        XCTAssertEqual(nextState.amountInToken, 0.03)
        XCTAssertEqual(nextState.amountInFiat, 0.375)
        XCTAssertEqual(nextState.status, .ready)
    }
}
