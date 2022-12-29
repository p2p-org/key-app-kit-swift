//
//  SendInputBusinessLogic+Helper.swift
//  Send
//
//  Created by Giang Long Tran on 27.12.2022.
//

import Foundation
import SolanaSwift

enum SendInputBusinessLogicHelper {
    static func resolveAvailableWalletForPayingFee(
        _ state: SendInputState,
        _ services: SendInputServices,
        _ payingTokenMint: String
    ) async throws -> SendInputState.PayingWalletFee? {
        if
            let feeRelayerContext = state.feeRelayerContext,
            let wallet = state.userWalletEnvironments.wallets.first(where: { $0.token.address == payingTokenMint }),
            let fee = try await services.feeService.getFees(
                from: state.token,
                recipient: state.recipient,
                recipientAdditionalInfo: state.recipientAdditionalInfo,
                payingTokenMint: payingTokenMint,
                feeRelayerContext: feeRelayerContext
            ),
            let payingTokenMint = try? PublicKey(string: payingTokenMint),
            let feeInToken = try? await services.swapService.calculateFeeInPayingToken(
                feeInSOL: fee,
                payingFeeTokenMint: payingTokenMint
            )
        {
            return .init(wallet: wallet, fee: fee, feeInToken: feeInToken)
        }

        return nil
    }
}
