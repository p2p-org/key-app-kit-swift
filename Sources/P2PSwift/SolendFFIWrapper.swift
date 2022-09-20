// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import P2pSdk

internal struct SolendResponse<Success: Codable>: Codable {
    let success: Success?
    let error: String?
}

public class SolendFFIWrapper: Solend {
    private static let concurrentQueue = DispatchQueue(label: "SolendSDK", attributes: .concurrent)

    public init() {}

    public func getCollateralAccounts(rpcURL: String, owner: String) async throws -> [SolendCollateralAccount] {
        // Fetch
        let jsonResult: String = try await execute { get_solend_collateral_accounts(rpcURL, owner) }

        // Decode
        struct Success: Codable {
            let accounts: [SolendCollateralAccount]
        }

        // Return
        do {
            let response = try JSONDecoder().decode(
                SolendResponse<Success>.self,
                from: jsonResult.data(using: .utf8)!
            )

            if let error = response.error { throw SolendError.message(error) }
            if let success = response.success { return success.accounts }
            throw SolendError.invalidJson
        } catch {
            throw SolendError.invalidJson
        }
    }

    public func getMarketInfo(
        symbols: [SolendSymbol],
        pool: String
    ) async throws -> [(token: SolendSymbol, marketInfo: SolendMarketInfo)] {
        let jsonResult: String = try await execute {
            get_solend_market_info(symbols.joined(separator: ","), pool)
        }

        // Decode

        enum MarketInfoElement: Codable {
            case marketInfoClass(SolendMarketInfo)
            case token(String)

            var asToken: String {
                get throws {
                    guard case let .token(value) = self else { throw SolendError.decodingException }
                    return value
                }
            }

            var asMarketInfo: SolendMarketInfo {
                get throws {
                    guard case let .marketInfoClass(value) = self else { throw SolendError.decodingException }
                    return value
                }
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let x = try? container.decode(String.self) {
                    self = .token(x)
                    return
                }
                if let x = try? container.decode(SolendMarketInfo.self) {
                    self = .marketInfoClass(x)
                    return
                }
                throw DecodingError.typeMismatch(
                    MarketInfoElement.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Wrong type for MarketInfoElement"
                    )
                )
            }

            func encode(to _: Encoder) throws { fatalError("MarketInfoElement doesn't support encode") }
        }

        struct Success: Codable {
            let marketInfo: [[MarketInfoElement]]

            private enum CodingKeys: String, CodingKey {
                case marketInfo = "market_info"
            }
        }

        // Return
        do {
            let response = try JSONDecoder().decode(
                SolendResponse<Success>.self,
                from: jsonResult.data(using: .utf8)!
            )

            if let error = response.error { throw SolendError.message(error) }
            if let success = response.success {
                return try success.marketInfo.map { (try $0.first!.asToken, try $0.last!.asMarketInfo) }
            }
            throw SolendError.invalidJson
        } catch {
            throw SolendError.invalidJson
        }
    }

    public func getUserDeposits(owner: String, poolAddress: String) async throws -> [SolendUserDeposit] {
        let jsonResult: String = try await execute {
            get_solend_user_deposits(owner, poolAddress)
        }

        struct Success: Codable {
            let marketInfo: [SolendUserDeposit]

            private enum CodingKeys: String, CodingKey {
                case marketInfo = "market_info"
            }
        }

        do {
            let response = try JSONDecoder().decode(
                SolendResponse<Success>.self,
                from: jsonResult.data(using: .utf8)!
            )

            if let error = response.error { throw SolendError.message(error) }
            if let success = response.success { return success.marketInfo }
            throw SolendError.invalidJson
        } catch {
            throw SolendError.invalidJson
        }
    }

    public func getUserDepositBySymbol(
        owner: String,
        symbol: SolendSymbol,
        poolAddress: String
    ) async throws -> SolendUserDeposit {
        let jsonResult: String = try await execute {
            get_solend_user_deposit_by_symbol(owner, symbol, poolAddress)
        }

        struct Success: Codable {
            let marketInfo: SolendUserDeposit

            private enum CodingKeys: String, CodingKey {
                case marketInfo = "market_info"
            }
        }

        do {
            let response = try JSONDecoder().decode(
                SolendResponse<Success>.self,
                from: jsonResult.data(using: .utf8)!
            )

            if let error = response.error { throw SolendError.message(error) }
            if let success = response.success { return success.marketInfo }
            throw SolendError.invalidJson
        } catch {
            throw SolendError.invalidJson
        }
    }

    public func getDepositFee(
        rpcUrl: String,
        owner: String,
        tokenAmount: UInt64,
        tokenSymbol: SolendSymbol
    ) async throws -> SolendDepositFee {
        let jsonResult: String = try await execute {
            get_solend_deposit_fees(rpcUrl, owner, tokenAmount, tokenSymbol)
        }

        do {
            let response = try JSONDecoder().decode(
                SolendResponse<SolendDepositFee>.self,
                from: jsonResult.data(using: .utf8)!
            )

            if let error = response.error { throw SolendError.message(error) }
            if let success = response.success { return success }
            throw SolendError.invalidJson
        } catch {
            throw SolendError.invalidJson
        }
    }

    public func createDepositTransaction(
        solanaRpcUrl: String,
        relayProgramId: String,
        amount: UInt64,
        symbol: SolendSymbol,
        ownerAddress: String,
        environment: SolendEnvironment,
        lendingMarketAddress: String,
        blockHash: String,
        freeTransactionsCount: UInt32,
        needToUseRelay: Bool,
        payInFeeToken: SolendPayFeeInToken,
        feePayerAddress: String
    ) async throws -> [String] {
        let payInFeeTokenJson = String(data: try JSONEncoder().encode(payInFeeToken), encoding: .utf8)!

        let jsonResult: String = try await execute {
            create_solend_deposit_transactions(
                solanaRpcUrl,
                relayProgramId,
                amount,
                symbol,
                ownerAddress,
                environment.rawValue,
                lendingMarketAddress,
                blockHash,
                freeTransactionsCount,
                needToUseRelay,
                payInFeeTokenJson,
                feePayerAddress
            )
        }

        struct Success: Codable {
            let transactions: [String]
        }

        do {
            let response = try JSONDecoder().decode(
                SolendResponse<Success>.self,
                from: jsonResult.data(using: .utf8)!
            )

            if let error = response.error { throw SolendError.message(error) }
            if let success = response.success { return success.transactions }
            throw SolendError.invalidJson
        } catch {
            throw SolendError.invalidJson
        }
    }

    public func createWithdrawTransaction(
        solanaRpcUrl: String,
        relayProgramId: String,
        amount: UInt64,
        symbol: SolendSymbol,
        ownerAddress: String,
        environment: SolendEnvironment,
        lendingMarketAddress: String,
        blockHash: String,
        freeTransactionsCount: UInt32,
        needToUseRelay: Bool,
        payInFeeToken: SolendPayFeeInToken,
        feePayerAddress: String
    ) async throws -> [SolanaRawTransaction] {
        let payInFeeTokenJson = String(data: try JSONEncoder().encode(payInFeeToken), encoding: .utf8)!

        let jsonResult: String = try await execute {
            create_solend_withdraw_transactions(
                solanaRpcUrl,
                relayProgramId,
                amount,
                symbol,
                ownerAddress,
                environment.rawValue,
                lendingMarketAddress,
                blockHash,
                freeTransactionsCount,
                needToUseRelay,
                payInFeeTokenJson,
                feePayerAddress
            )
        }

        struct Success: Codable {
            let transactions: [String]
        }

        do {
            let response = try JSONDecoder().decode(
                SolendResponse<Success>.self,
                from: jsonResult.data(using: .utf8)!
            )

            if let error = response.error { throw SolendError.message(error) }
            if let success = response.success { return success.transactions }
            throw SolendError.invalidJson
        } catch {
            throw SolendError.invalidJson
        }
    }

    // Utils
    internal func execute(_ networkCall: @escaping () -> UnsafeMutablePointer<CChar>?) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            SolendFFIWrapper.concurrentQueue.async {
                do {
                    let result = networkCall()
                    continuation.resume(returning: String(cString: result!))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
