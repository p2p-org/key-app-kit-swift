// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import P2pSdk

struct CollateralAccount: Codable {
    let address: String
    let mint: String
}

protocol SolendSdk {
    func getCollateralAccounts(rpcURL: String, owner: String) async throws -> [CollateralAccount]
}

enum SolendSdkError: Error {
    case invalidJson
}

class SolendSdkFFI: SolendSdk {
    private static let concurrentQueue = DispatchQueue(label: "SolendSDK", attributes: .concurrent)

    func getCollateralAccounts(rpcURL: String, owner: String) async throws -> [CollateralAccount] {
        // Fetch
        let jsonResult: String = try await withCheckedThrowingContinuation { continuation in
            SolendSdkFFI.concurrentQueue.async {
                do {
                    let result = get_solend_collateral_accounts(rpcURL, owner)
                    continuation.resume(returning: String(cString: result!))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        // Decode
        struct Response: Codable {
            struct Result: Codable {
                let accounts: [CollateralAccount]
            }

            let success: Result
        }

        // Return
        do {
            let response: Response = try JSONDecoder().decode(Response.self, from: jsonResult.data(using: .utf8)!)
            return response.success.accounts
        } catch {
            throw SolendSdkError.invalidJson
        }
    }
}
