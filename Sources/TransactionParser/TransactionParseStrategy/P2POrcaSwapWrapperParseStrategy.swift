// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

/// A strategy for orca swap transactions.
public class P2POrcaSwapWrapperParseStrategy: TransactionParseStrategy {
    /// The list of orca program signatures that will be parsed by this strategy
    private static let orcaProgramSignatures = [
        "12YKFL4mnZz6CBEGePrf293mEzueQM3h8VLPUJsKpGs9",
    ]

    private let apiClient: SolanaAPIClient
    private let tokensRepository: SolanaTokensRepository

    init(apiClient: SolanaAPIClient, tokensRepository: SolanaTokensRepository) {
        self.apiClient = apiClient
        self.tokensRepository = tokensRepository
    }

    open func isHandlable(with transactionInfo: TransactionInfo) -> Bool {
        transactionInfo.transaction.message.instructions.contains {
            Self.orcaProgramSignatures.contains($0.programId)
        }
    }

    open func parse(
        _ transactionInfo: TransactionInfo,
        config configuration: Configuration
    ) async throws -> AnyHashable? {
        let innerInstructions = transactionInfo.meta?.innerInstructions

        switch true {
        case isLiquidityToPool(innerInstructions: innerInstructions): return nil
        case isBurn(innerInstructions: innerInstructions): return nil
        default:
            return try await _parse(
                transactionInfo: transactionInfo,
                config: configuration
            )
        }
    }

    func _parse(
        transactionInfo: TransactionInfo,
        config: Configuration
    ) async throws -> AnyHashable? {
        try Task.checkCancellation()

        // Find P2P swap instruction
        let swapInstructionIndex = transactionInfo.transaction.message.instructions
            .lastIndex { (i: ParsedInstruction) in
                if Self.orcaProgramSignatures.contains(where: { $0 == i.programId }) {
                    if let iData = i.data, Base58.decode(iData).first == 4 { return true }
                }
                return false
            }
        guard let swapInstructionIndex = swapInstructionIndex else { return nil }

        // First attempt of extraction
        let swapInstruction = transactionInfo.transaction.message.instructions[swapInstructionIndex]
        guard
            let sourceAddress: String = swapInstruction.accounts?[3],
            let (sourceWallet, sourceChange) = try await parseToken(transactionInfo, for: sourceAddress),
            var destinationAddress: String = swapInstruction.accounts?[5],
            var (destinationWallet, destinationChange) = try await parseToken(transactionInfo, for: destinationAddress)
        else { return nil }

        // Swap to native SOL
        if destinationChange == .zero {
            let closeInstruction = transactionInfo.transaction.message.instructions[swapInstructionIndex + 1]
            if closeInstruction.programId == TokenProgram.id.base58EncodedString {
                if closeInstruction.parsed?.type == "closeAccount" {
                    guard let destination = closeInstruction.parsed?.info.destination else { return nil }
                    destinationAddress = destination
                    guard let (newDestinationWallet, newDestinationChange) = try await parseToken(
                        transactionInfo,
                        for: destinationAddress
                    ) else { return nil }

                    destinationWallet = newDestinationWallet
                    destinationChange = newDestinationChange
                }
            }
        }

        return SwapInfo(
            source: sourceWallet,
            sourceAmount: sourceChange,
            destination: destinationWallet,
            destinationAmount: destinationChange,
            accountSymbol: config.symbolView
        )

        // return SwapInfo(
        //     source: sourceWallet,
        //     sourceAmount: sourceAmountLamports?.convertToBalance(decimals: sourceWallet.token.decimals),
        //     destination: destinationWallet,
        //     destinationAmount: destinationAmountLamports?
        //         .convertToBalance(decimals: destinationWallet.token.decimals),
        //     accountSymbol: configuration.symbolView
        // )
    }

    func parseToken(_ transactionInfo: TransactionInfo,
                    for address: String) async throws -> (wallet: Wallet, amount: Double)?
    {
        guard let addressIndex = transactionInfo.transaction.message.accountKeys
            .firstIndex(where: { $0.publicKey.base58EncodedString == address }) else { return nil }

        let mintAddress: String = transactionInfo.meta?.postTokenBalances?
            .first(where: { $0.accountIndex == addressIndex })?.mint ?? Token.nativeSolana.address

        let preTokenBalance: Lamports = transactionInfo.meta?.preTokenBalances?
            .first(where: { $0.accountIndex == addressIndex })?.uiTokenAmount.amountInUInt64 ?? 0

        let preBalance: Double
        let postBalance: Double
        if mintAddress == Token.nativeSolana.address {
            preBalance = transactionInfo.meta?.preBalances?[addressIndex]
                .convertToBalance(decimals: Token.nativeSolana.decimals) ?? 0
            postBalance = transactionInfo.meta?.postBalances?[addressIndex]
                .convertToBalance(decimals: Token.nativeSolana.decimals) ?? 0
        } else {
            preBalance = transactionInfo.meta?.preTokenBalances?
                .first(where: { $0.accountIndex == addressIndex })?.uiTokenAmount.uiAmount ?? 0
            postBalance = transactionInfo.meta?.postTokenBalances?
                .first(where: { $0.accountIndex == addressIndex })?.uiTokenAmount.uiAmount ?? 0
        }

        let sourceToken: Token = try await tokensRepository.getTokenWithMint(mintAddress)

        let wallet = Wallet(
            pubkey: try? PublicKey(string: address).base58EncodedString,
            lamports: preTokenBalance,
            token: sourceToken
        )

        let amount = abs(postBalance - preBalance)

        return (wallet, amount)
    }

    func parseFailedTransaction(
        transactionInfo: TransactionInfo,
        accountSymbol: String?
    ) async throws -> SwapInfo? {
        try Task.checkCancellation()

        guard
            let postTokenBalances = transactionInfo.meta?.postTokenBalances,
            let approveInstruction = transactionInfo.transaction.message.instructions
                .first(where: { $0.parsed?.type == "approve" }),
                let sourceAmountString = approveInstruction.parsed?.info.amount,
                let sourceMint = postTokenBalances.first?.mint,
                let destinationMint = postTokenBalances.last?.mint
        else {
            return nil
        }

        let sourceToken = try await tokensRepository.getTokenWithMint(sourceMint)
        let destinationToken = try await tokensRepository.getTokenWithMint(destinationMint)

        let sourceWallet = Wallet(
            pubkey: approveInstruction.parsed?.info.source,
            lamports: Lamports(postTokenBalances.first?.uiTokenAmount.amount ?? "0"),
            token: sourceToken
        )

        let destinationWallet = Wallet(
            pubkey: destinationToken.symbol == "SOL" ? approveInstruction.parsed?.info.owner : nil,
            lamports: Lamports(postTokenBalances.last?.uiTokenAmount.amount ?? "0"),
            token: destinationToken
        )

        return SwapInfo(
            source: sourceWallet,
            sourceAmount: Lamports(sourceAmountString)?.convertToBalance(decimals: sourceWallet.token.decimals),
            destination: destinationWallet,
            destinationAmount: nil,
            accountSymbol: accountSymbol
        )
    }
}

private func isLiquidityToPool(innerInstructions: [InnerInstruction]?) -> Bool {
    guard let instructions = innerInstructions?.first?.instructions else { return false }
    switch instructions.count {
    case 3:
        return instructions[0].parsed?.type == "transfer" &&
            instructions[1].parsed?.type == "transfer" &&
            instructions[2].parsed?.type == "mintTo"
    default:
        return false
    }
}

/// Check the instruction is a burn
private func isBurn(innerInstructions: [InnerInstruction]?) -> Bool {
    guard let instructions = innerInstructions?.first?.instructions else { return false }
    switch instructions.count {
    case 3:
        return instructions.count == 3 &&
            instructions[0].parsed?.type == "burn" &&
            instructions[1].parsed?.type == "transfer" &&
            instructions[2].parsed?.type == "transfer"
    default:
        return false
    }
}
