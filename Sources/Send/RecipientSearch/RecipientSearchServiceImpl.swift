// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import NameService
import SolanaSwift

public class RecipientSearchServiceImpl: RecipientSearchService {
    let nameService: NameService
    let solanaClient: SolanaAPIClient
    let swapService: SwapService

    public init(nameService: NameService, solanaClient: SolanaAPIClient, swapService: SwapService) {
        self.nameService = nameService
        self.solanaClient = solanaClient
        self.swapService = swapService
    }

    public func search(input: String, env: UserWalletEnvironments) async -> RecipientSearchResult {
        if input.isEmpty {
            return .ok([])
        } else if let address = try? PublicKey(string: input) {
            do {
                let addressBase58 = address.base58EncodedString
                let account: BufferInfo<SmartInfo>? = try await solanaClient
                    .getAccountInfo(account: addressBase58)

                var attributes: Recipient.Attribute = []

                if PublicKey.isOnCurve(publicKeyBytes: address.data) == 0 {
                    attributes.insert(.pda)
                }

                if let account = account {
                    switch account.data {
                    case .empty:
                        // Detect wallet address
                        return .ok([
                            .init(
                                address: addressBase58,
                                category: .solanaAddress,
                                attributes: [.funds, attributes]
                            ),
                        ])
                    case let .splAccount(accountInfo):
                        // Detect token account
                        let recipient: Recipient = .init(
                            address: addressBase58,
                            category: .solanaTokenAddress(
                                walletAddress: try .init(string: accountInfo.owner.base58EncodedString),
                                token: env.tokens
                                    .first(where: { $0.address == accountInfo.mint.base58EncodedString }) ??
                                    .unsupported(mint: accountInfo.mint.base58EncodedString)
                            ),
                            attributes: [.funds, attributes]
                        )

                        if let wallet = env.wallets
                            .first(where: { $0.token.address == accountInfo.mint.base58EncodedString }),
                            (wallet.lamports ?? 0) > 0
                        {
                            // User has the same token
                            return .ok([recipient])
                        } else {
                            // User doesn't have the same token
                            return .missingUserToken(recipient: recipient)
                        }
                    }
                } else {
                    // This account doesn't exits in blockchain
                    if try await checkBalanceForCreateAccount(env: env) {
                        return .ok([.init(
                            address: addressBase58,
                            category: .solanaAddress,
                            attributes: [attributes]
                        )])
                    } else {
                        return .insufficientUserFunds(recipient: .init(
                            address: addressBase58,
                            category: .solanaAddress,
                            attributes: [attributes]
                        ))
                    }
                }
            } catch let error as SolanaSwift.APIClientError {
                switch error {
                case let .responseError(detailedError):
                    if detailedError.code == -32602 { return .ok([]) }
                default:
                    break
                }
                debugPrint(error)
                return .solanaServiceError(error as NSError)
            } catch {
                debugPrint(error)
                return .solanaServiceError(error as NSError)
            }
        } else {
            do {
                let records: [NameRecord] = try await nameService.getOwners(input)
                let recipients: [Recipient] = records.map { record in
                    var name = ""
                    var domain = ""

                    if
                        let nameComponents: [String] = record.name?.components(separatedBy: "."),
                        nameComponents.count > 1
                    {
                        name = nameComponents.prefix(nameComponents.count - 1).joined(separator: ".")
                        domain = nameComponents.last ?? ""
                    } else {
                        name = record.name ?? ""
                    }

                    return .init(
                        address: record.owner,
                        category: .username(name: name, domain: domain),
                        attributes: []
                    )
                }

                return .ok(recipients)
            } catch {
                debugPrint(error)
                return .nameServiceError(error as NSError)
            }
        }
    }

    func checkBalanceForCreateAccount(env: UserWalletEnvironments) async throws -> Bool {
        let wallets = env.wallets

        if wallets.contains(where: { !$0.token.isNativeSOL }) {
            if try await checkBalanceForCreateSPLAccount(env: env) {
                return true
            }
        }

        return try await checkBalanceForCreateNativeAccount(env: env)
    }

    func checkBalanceForCreateNativeAccount(env: UserWalletEnvironments) async throws -> Bool {
        let wallets = env.wallets

        for wallet in wallets {
            try Task.checkCancellation()

            guard
                let balance = wallet.lamports,
                let mint = try? PublicKey(string: wallet.token.address)
            else { continue }

            let result = try await swapService.calculateFeeInPayingToken(
                feeInSOL: .init(transaction: 0, accountBalances: env.rentExemptionAmountForWalletAccount),
                payingFeeTokenMint: mint
            )

            let rentExemptionAmountForWalletAccountInToken = result?.accountBalances ?? 0
            if balance > rentExemptionAmountForWalletAccountInToken {
                return true
            }
        }

        return false
    }

    func checkBalanceForCreateSPLAccount(env: UserWalletEnvironments) async throws -> Bool {
        let wallets = env.wallets

        for wallet in wallets {
            try Task.checkCancellation()

            guard
                let balance = wallet.lamports,
                let mint = try? PublicKey(string: wallet.token.address)
            else { continue }

            let result = try await swapService.calculateFeeInPayingToken(
                feeInSOL: .init(transaction: 0, accountBalances: env.rentExemptionAmountForSPLAccount),
                payingFeeTokenMint: mint
            )

            let rentExemptionAmountForWalletAccountInToken = result?.accountBalances ?? 0
            if balance > rentExemptionAmountForWalletAccountInToken {
                return true
            }
        }

        return false
    }
}
