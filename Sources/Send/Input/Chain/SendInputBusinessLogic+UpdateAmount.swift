//
//  SendInputBusinessLogic+UpdateAmount.swift
//  Send
//
//  Created by Giang Long Tran on 28.12.2022.
//

import Foundation

extension SendInputBusinessLogic {
    static func updateAmountChain(_ state: SendInputState, _ services: SendInputServices) async -> SendInputState {
        return state.copy(
            amountInFiat: state.userWalletEnvironments.amountInFiat(state.token.symbol, state.amountInToken)
        )
    }
}
