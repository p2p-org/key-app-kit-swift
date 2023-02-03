//
//  SendInputBusinessLogic+UpdateWalletsForPayingFee.swift
//  Send
//
//  Created by Giang Long Tran on 28.12.2022.
//

import FeeRelayerSwift
import Foundation
import SolanaSwift

extension SendInputBusinessLogic {
    static func calculateWalletsForPayingFeeChain(_ state: SendInputState, _ services: SendInputServices) async -> SendInputState {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return state.copy(
                status: .error(reason: .missingFeeRelayer)
            )
        }

        let token = state.token

        // Auto selection definition
        var tokenAddresses: Set<String> = [
            // Same token that will pay fee.
            token.address,

            // Solana.
            Token.nativeSolana.address,

            // Any other token, that have the largest amount in fiat.
            state.userWalletEnvironments.wallets
                .filter { wallet in
                    !Set([token.address, Token.nativeSolana.address]).contains(wallet.token.address)
                }
                .sorted(by: { (lhs: Wallet, rhs: Wallet) -> Bool in
                    state.userWalletEnvironments.amountInFiat(lhs.token.symbol, lhs.amount) > state.userWalletEnvironments.amountInFiat(rhs.token.symbol, rhs.amount)
                })
                .first?
                .token
                .address ?? Token.nativeSolana.address
        ]

        // Calculating
        var availableWalletsForPayingFee: [SendInputState.PayingWalletFee] = await withTaskGroup(of: SendInputState.PayingWalletFee?.self) { group in

            // Generate tasks
            for tokenAddress in tokenAddresses {
                group.addTask {
                    try? await resolveTokenWalletForPayingFee(state, services, feeRelayerContext, tokenAddress)
                }
            }

            var result: [SendInputState.PayingWalletFee] = []

            // Wait all tasks
            for await executedTaskResult in group {
                if let executedTaskResult = executedTaskResult {
                    result.append(executedTaskResult)
                }
            }

            return result
        }

        // Still add solana for safety
        if availableWalletsForPayingFee.isEmpty {
            availableWalletsForPayingFee.append(await resolveSolanaWalletForPayingFee(state, services, feeRelayerContext))
        }

        // Sort by priority: same token, solana, any spl token
        availableWalletsForPayingFee.sort { lhs, _ in
            switch true {
            case lhs.wallet.token.address == token.address:
                return true
            case lhs.wallet.isNativeSOL:
                return true
            default:
                return false
            }
        }

        return state.copy(walletsForPayingFee: availableWalletsForPayingFee)
    }

    /// Resolve solana account for paying fee
    fileprivate static func resolveSolanaWalletForPayingFee(
        _ state: SendInputState,
        _ services: SendInputServices,
        _ feeRelayerContext: FeeRelayerContext
    ) async -> SendInputState.PayingWalletFee {
        let token = Token.nativeSolana

        let fee: FeeAmount = (try? await services.feeService.getFees(
            from: state.token,
            recipient: state.recipient,
            recipientAdditionalInfo: state.recipientAdditionalInfo,
            payingTokenMint: token.address,
            feeRelayerContext: feeRelayerContext
        )) ?? .zero

        let payingTokenMint: PublicKey = try! PublicKey(string: token.address)
        let feeInToken: FeeAmount = (try? await services.swapService.calculateFeeInPayingToken(
            feeInSOL: fee,
            payingFeeTokenMint: payingTokenMint
        )) ?? .zero

        return .init(
            wallet: .init(token: .nativeSolana),
            fee: fee,
            feeInToken: feeInToken ?? .zero
        )
    }

    // Resolve spl account for paying fee
    fileprivate static func resolveTokenWalletForPayingFee(
        _ state: SendInputState,
        _ services: SendInputServices,
        _ feeRelayerContext: FeeRelayerContext,
        _ payingTokenMint: String
    ) async throws -> SendInputState.PayingWalletFee? {
        let wallet = state.userWalletEnvironments.wallets.first(where: { $0.token.address == payingTokenMint })
        let fee = try await services.feeService.getFees(
            from: state.token,
            recipient: state.recipient,
            recipientAdditionalInfo: state.recipientAdditionalInfo,
            payingTokenMint: payingTokenMint,
            feeRelayerContext: feeRelayerContext
        )

        if
            let wallet = wallet,
            let fee = fee,
            let payingTokenMint = try? PublicKey(string: payingTokenMint),
            let feeInToken = try? await services.swapService.calculateFeeInPayingToken(
                feeInSOL: fee,
                payingFeeTokenMint: payingTokenMint
            )
        {
            return .init(wallet: wallet, fee: fee, feeInToken: feeInToken)
        } else if let wallet = wallet, let fee = fee, fee == .zero {
            return .init(wallet: wallet, fee: fee, feeInToken: .zero)
        } else {
            return nil
        }
    }
}
