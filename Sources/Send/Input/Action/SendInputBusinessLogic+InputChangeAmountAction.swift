// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import SolanaSwift

extension SendInputBusinessLogic {
    static func sendInputChangeAmountInFiat(
        state: SendInputState,
        amount: Double,
        services: SendInputServices
    ) async -> SendInputState {
        guard let price = state.userWalletEnvironments.exchangeRate[state.token.symbol]?.value else {
            return await sendInputChangeAmountInTokenAction(state: state, amount: 0, services: services)
        }
        let amountInToken = amount / price
        return await sendInputChangeAmountInTokenAction(state: state, amount: amountInToken, services: services)
    }

    static func sendInputChangeAmountInTokenAction(
        state: SendInputState,
        amount: Double,
        services: SendInputServices
    ) async -> SendInputState {
        return state.copy(amountInToken: amount)
    }
}
