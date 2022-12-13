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

        let value: NSNumber = NSNumber(value: amount * pow(10, Double(state.token.decimals)))
        let amountLamports = Lamports(value.int64Value)

        var status: SendInputState.Status = .ready

        // More than available amount in wallet (with different logic for SOL token)
        if state.token.isNativeSOL {
            if amountLamports > state.maxAmountInputInSOLWithLeftAmount.toLamport(decimals: state.token.decimals) {
                if amountLamports == state.maxAmountInputInToken.toLamport(decimals: state.token.decimals) {
                    // Return availability to send the absolute max amount for SOL token
                    status = .ready
                }
                else {
                    status = .error(reason: .inputTooHigh(state.maxAmountInputInSOLWithLeftAmount))
                }
            }
        } else if amountLamports > state.maxAmountInputInToken.toLamport(decimals: state.token.decimals) {
            status = .error(reason: .inputTooHigh(state.maxAmountInputInToken))
        }

        // Minimum amount to send to the account with no funds
        if state.token.isNativeSOL, state.recipientAdditionalInfo.walletAccount == nil {
            let minAmount = feeRelayerContext.minimumRelayAccountBalance
            if amountLamports < minAmount && status == .error(reason: .inputTooHigh(state.maxAmountInputInSOLWithLeftAmount)) {
                // If input amount considered as both tooLow and tooHigh => return another error
                status = .error(reason: .insufficientFunds)
            } else if amountLamports < minAmount {
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

private extension SendInputState {
    var maxAmountInputInSOLWithLeftAmount: Double {
        guard let context = feeRelayerContext, token.isNativeSOL else { return maxAmountInputInToken }

        var maxAmountInToken = maxAmountInputInToken.toLamport(decimals: token.decimals)
        maxAmountInToken = maxAmountInToken - context.minimumRelayAccountBalance
        return Double(maxAmountInToken) / pow(10, Double(token.decimals))
    }
}
