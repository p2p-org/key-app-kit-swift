//
//  NativeTokenStrategy.swift
//  Send
//
//  Created by Giang Long Tran on 03.01.2023.
//

import Foundation

struct NativeTokenStrategy: ChainStrategy {
    static func validateInput(_ state: SendInputState, _ service: SendInputServices) async -> SendInputState {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return state.copy(status: .error(reason: .missingFeeRelayer))
        }

        let amountLamports = state.amountInToken.toLamport(decimals: state.token.decimals)
        var status: SendInputState.Status = .ready
        
        let maxAmount = state.maxAmountInputInToken.toLamport(decimals: state.token.decimals)
        let maxAmountWithLeftAmount = state.maxAmountInputInSOLWithLeftAmount.toLamport(decimals: state.token.decimals)
        let minAmount = feeRelayerContext.minimumRelayAccountBalance

        if amountLamports > maxAmountWithLeftAmount {
            if amountLamports == maxAmount {
                // Return availability to send the absolute max amount for SOL token
                status = .ready
            } else {
                let limit = amountLamports < maxAmount ? state.maxAmountInputInSOLWithLeftAmount : state.maxAmountInputInToken
                status = .error(reason: .inputTooHigh(limit))
            }
        }

        if state.recipientAdditionalInfo.walletAccount == nil {
            // Minimum amount to send to the account with no funds
            if minAmount > maxAmountWithLeftAmount && amountLamports < maxAmount {
                // If minimum appears to be less than available maximum than return this error
                status = .error(reason: .insufficientFunds)
            } else if amountLamports < minAmount {
                status = .error(reason: .inputTooLow(minAmount.convertToBalance(decimals: state.token.decimals)))
            }
        }

        return state.copy(status: status)
    }
}
