// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import SolanaSwift

extension SendInputBusinessLogic {
    static func changeToken(
        state: SendInputState,
        token: Token,
        services: SendInputServices
    ) async -> SendInputState {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return state.copy(
                status: .error(reason: .missingFeeRelayer),
                token: token
            )
        }

        do {
            // Update fee in SOL and source token
            let fee = try await services.feeService.getFees(
                from: token,
                recipient: state.recipient,
                recipientAdditionalInfo: state.recipientAdditionalInfo,
                payingTokenMint: state.tokenFee.address,
                feeRelayerContext: feeRelayerContext
            ) ?? .zero

            var state = state.copy(
                token: token,
                fee: fee,
                minAmount: .zero
            )

            // Auto select fee  token
            state = state.copy(
                tokenFee: await autoSelectTokenFee(
                    userWallets: state.userWalletEnvironments.wallets,
                    feeInSol: state.fee,
                    token: state.token,
                    services: services
                )
            )

            // Update fee in token
            let feeInToken = try? await services.swapService.calculateFeeInPayingToken(
                feeInSOL: fee,
                payingFeeTokenMint: try PublicKey(string: state.tokenFee.address)
            ) ?? .zero

            state = state.copy(
                feeInToken: feeInToken
            )

            return state
        } catch {
            return state.copy(status: .error(reason: .unknown(error as NSError)))
        }
    }

    static func autoSelectTokenFee(
        userWallets: [Wallet],
        feeInSol: FeeAmount,
        token: Token,
        services: SendInputServices
    ) async -> Token? {
        let preferOrder: [String: Int] = ["usdc": 1, "usdt": 2, token.symbol: 3, "sol": 4]
        let sortedWallets = userWallets.sorted { (lhs: Wallet, rhs: Wallet) -> Bool in
            (preferOrder[lhs.token.symbol] ?? 5) < (preferOrder[rhs.token.symbol] ?? 5)
        }

        for wallet in sortedWallets {
            let feeInToken: FeeAmount = (try? await services.swapService.calculateFeeInPayingToken(
                feeInSOL: feeInSol,
                payingFeeTokenMint: try PublicKey(string: wallet.token.address)
            )) ?? .zero

            if feeInToken.total < (wallet.lamports ?? 0) {
                return wallet.token
            }
        }

        return .nativeSolana
    }
}
