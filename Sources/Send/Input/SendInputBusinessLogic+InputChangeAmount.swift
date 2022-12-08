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
            return await sendInputChangeAmountInToken(state: state, amount: 0, services: services)
        }
        let amountInToken = amount / price
        return await sendInputChangeAmountInToken(state: state, amount: amountInToken, services: services)
    }

    static func sendInputChangeAmountInToken(
        state: SendInputState,
        amount: Double,
        services _: SendInputServices
    ) async -> SendInputState {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return state.copy(status: .error(reason: .missingFeeRelayer))
        }

        let userTokenAccount: Wallet? = state.userWalletEnvironments.wallets
            .first(where: { $0.token.symbol == state.token.symbol })
        let tokenBalance = userTokenAccount?.lamports ?? 0
        let amountLamports = Lamports(amount * pow(10, Double(state.token.decimals)))

        var status: SendInputState.Status = .ready

        // More than available amount in wallet
        if state.token.address == state.tokenFee.address {
            if amountLamports + state.feeInToken.total > tokenBalance {
                status = .error(reason: .inputTooHigh)
            }
        } else {
            if amountLamports > tokenBalance {
                status = .error(reason: .inputTooHigh)
            }
        }

        // Minimum amount to send to the account with no funds
        if state.token.isNativeSOL, state.recipientAdditionalInfo.walletAccount == nil {
            let minAmount = feeRelayerContext.minimumRelayAccountBalance
            if amountLamports < minAmount {
                status = .error(reason: .inputTooLow(minAmount.convertToBalance(decimals: state.token.decimals)))
            }
        }

        if !checkIsReady(state) {
            status = .error(reason: .requiredInitialize)
        }

        var state = state.copy(
            status: status,
            amountInFiat: amount * (state.userWalletEnvironments.exchangeRate[state.token.symbol]?.value ?? 0),
            amountInToken: amount
        )
        
        state = await validateFee(state: state)
        
        return state
    }
}
