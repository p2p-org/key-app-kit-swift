// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

struct SendInputBusinessLogic {
    static func sendInputBusinessLogic(
        state: SendInputState,
        action: SendInputAction,
        services: SendInputServices
    ) async -> SendInputState {
        switch action {
        case let .changeAmountInToken(amount):
            return await sendInputChangeAmountInToken(state: state, amount: amount, services: services)
        default:
            return state
        }
    }

    static func sendInputChangeAmountInToken(
        state: SendInputState,
        amount: Double,
        services _: SendInputServices
    ) async -> SendInputState {
        let userTokenAccount: Wallet? = state.userWalletState.wallets
            .first(where: { $0.token.symbol == state.token.symbol })
        let tokenBalance = userTokenAccount?.lamports ?? 0

        // More than available amount in wallet
        var status: SendInputState.Status = .ready
        if state.token.address == state.tokenFee.address {
            if Lamports(amount * pow(10, Double(state.token.decimals))) + state.feeInToken.total > tokenBalance {
                status = .error(reason: .inputTooHigh)
            }
        }

        return state.copy(
            status: status,
            amountInFiat: amount * (state.userWalletState.exchangeRate[state.token.symbol]?.value ?? 0),
            amountInToken: amount
        )
    }
}
