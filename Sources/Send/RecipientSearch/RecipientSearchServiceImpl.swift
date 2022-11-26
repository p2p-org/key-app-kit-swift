// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import NameService
import SolanaSwift

public class RecipientSearchServiceImpl: RecipientSearchService {
    let nameService: NameService
    let solanaClient: SolanaAPIClient

    public init(nameService: NameService, solanaClient: SolanaAPIClient) {
        self.nameService = nameService
        self.solanaClient = solanaClient
    }

    // TODO: Implement me

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
                        return .ok([
                            .init(
                                address: addressBase58,
                                category: .solanaAddress,
                                attributes: [.funds, attributes]
                            ),
                        ])
                    case let .splAccount(accountInfo):
                        return .ok([
                            .init(
                                address: addressBase58,
                                category: .solanaTokenAddress(
                                    walletAddress: try .init(string: accountInfo.owner.base58EncodedString),
                                    token: env.tokens
                                        .first(where: { $0.address == accountInfo.mint.base58EncodedString }) ??
                                        .unsupported(mint: accountInfo.mint.base58EncodedString)
                                ),
                                attributes: [.funds, attributes]
                            ),
                        ])
                    }
                } else {
                    // This account doesn't exits in blockchain
                    return .ok([.init(
                        address: addressBase58,
                        category: .solanaAddress,
                        attributes: [attributes]
                    )])
                }
            } catch {
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
                        attributes: [.funds]
                    )
                }

                return .ok(recipients)
            } catch {
                return .nameServiceError(error as NSError)
            }
        }
    }
}
