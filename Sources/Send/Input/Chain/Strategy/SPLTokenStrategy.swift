//
//  SPLTokenStrategy.swift
//  Send
//
//  Created by Giang Long Tran on 03.01.2023.
//

import Foundation

struct SPLTokenStrategy: ChainStrategy {
    static func validateInput(_ state: SendInputState, _ service: SendInputServices) async -> SendInputState {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return state.copy(status: .error(reason: .missingFeeRelayer))
        }

        let amountLamports = state.amountInToken.toLamport(decimals: state.token.decimals)
        var status: SendInputState.Status = .ready

        if amountLamports > state.maxAmountInputInToken.toLamport(decimals: state.token.decimals) {
            status = .error(reason: .inputTooHigh(state.maxAmountInputInToken))
        }

        return state.copy(status: status)
    }
}
