// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import TweetNacl

public class APIGatewayClientImpl: APIGatewayClient {
    private let endpoint: URL
    private let networkManager: NetworkManager
    private let dateFormat: DateFormatter
    private var requestID: Int64 = 1

    public init(endpoint: String, networkManager: NetworkManager = URLSession.shared) {
        self.endpoint = URL(string: endpoint)!
        self.networkManager = networkManager

        dateFormat = .init()
        dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSSSSZZZZZ"
        dateFormat.locale = Locale(identifier: "en_US_POSIX")
    }

    private func createDefaultRequest(method: String = "POST") -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.allHTTPHeaderFields
        request.setValue("P2PWALLET_MOBILE", forHTTPHeaderField: "CHANNEL_ID")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return request
    }

    private func prepare(solanaPrivateKey: String, ethereumId: String) throws -> (
        solanaSecretKey: Data,
        solanaPublicKey: Data,
        ethAddress: String
    ) {
        let solanaSecretKey = Data(Base58.decode(solanaPrivateKey))
        let solanaKeypair = try NaclSign.KeyPair.keyPair(fromSecretKey: solanaSecretKey)
        let ethAddress = "0x" + EthereumHelper
            .generatePublicAddress(from: Data(hex: ethereumId))
            .hexString
            .lowercased()

        return (
            solanaSecretKey: solanaSecretKey,
            solanaPublicKey: solanaKeypair.publicKey,
            ethAddress: ethAddress
        )
    }

    public func registerWallet(
        solanaPrivateKey: String,
        ethereumId: String,
        phone: String,
        channel: APIGatewayChannel,
        timestampDevice: Date
    ) async throws {
        guard E164Numbers.validate(phone) else { throw APIGatewayError.invalidE164NumberStandard }

        // Prepare
        var request = createDefaultRequest()
        let (solanaSecretKey, solanaPublicKey, ethAddress) = try prepare(
            solanaPrivateKey: solanaPrivateKey,
            ethereumId: ethereumId
        )
        // Create rpc request
        let rpcRequest = JSONRPCRequest(
            id: requestID,
            method: "register_wallet",
            params: APIGatewayRegisterWalletParams(
                solanaPublicKey: Base58.encode(solanaPublicKey),
                ethereumAddress: ethAddress,
                phone: phone,
                channel: channel.rawValue,
                signature: try RegisterWalletSignature(
                    solanaPublicKey: Base58.encode(solanaPublicKey),
                    ethereumAddress: ethAddress,
                    phone: phone,
                    appHash: "",
                    channel: channel.rawValue
                ).signAsBase58(secretKey: solanaSecretKey),
                timestampDevice: dateFormat.string(from: timestampDevice)
            )
        )
        requestID += 1

        request.httpBody = try JSONEncoder().encode(rpcRequest)
        print(request.cURL(pretty: true))

        // Request
        let responseData = try await networkManager.requestData(request: request)

        // Check result
        let result = try JSONDecoder().decode(JSONRPCResponse<APIGatewayClientResult>.self, from: responseData)
        if let error = result.error {
            throw APIGatewayError(rawValue: error.code) ?? UndefinedAPIGatewayError(code: error.code)
        } else if result.result?.status != true {
            throw APIGatewayError.failedSending
        }
    }

    public func confirmRegisterWallet(
        solanaPrivateKey: String,
        ethereumId: String,
        share: String,
        encryptedPayload: String,
        phone: String,
        otpCode: String,
        timestampDevice: Date
    ) async throws {
        guard E164Numbers.validate(phone) else { throw APIGatewayError.invalidE164NumberStandard }

        // Prepare
        var request = createDefaultRequest()
        let (solanaSecretKey, solanaPublicKey, ethAddress) = try prepare(
            solanaPrivateKey: solanaPrivateKey,
            ethereumId: ethereumId
        )

        // Create rpc request
        let rpcRequest = JSONRPCRequest(
            id: requestID,
            method: "confirm_register_wallet",
            params: APIGatewayConfirmRegisterWalletParams(
                solanaPublicKey: Base58.encode(solanaPublicKey),
                ethereumAddress: ethAddress,
                encryptedShare: share.base64(),
                encryptedPayload: encryptedPayload.base64(),
                phone: phone,
                phoneConfirmationCode: otpCode,
                signature: try ConfirmRegisterWalletSignature(
                    ethereumId: ethAddress,
                    solanaPublicKey: Base58.encode(solanaPublicKey),
                    encryptedShare: share,
                    encryptedPayload: encryptedPayload,
                    phone: phone,
                    phoneConfirmationCode: otpCode
                ).signAsBase58(secretKey: solanaSecretKey),
                timestampDevice: dateFormat.string(from: timestampDevice)
            )
        )
        requestID += 1

        request.httpBody = try JSONEncoder().encode(rpcRequest)
        print(request.cURL(pretty: true))

        // Request
        let responseData = try await networkManager.requestData(request: request)

        // Check result
        let result = try JSONDecoder().decode(JSONRPCResponse<APIGatewayClientResult>.self, from: responseData)
        if let error = result.error {
            throw APIGatewayError(rawValue: error.code) ?? UndefinedAPIGatewayError(code: error.code)
        } else if result.result?.status != true {
            throw APIGatewayError.failedSending
        }
    }

    public func restoreWallet(
        solPrivateKey: Data,
        phone: String,
        channel: BindingPhoneNumberChannel,
        timestampDevice: Date
    ) async throws {
        guard E164Numbers.validate(phone) else { throw APIGatewayError.invalidE164NumberStandard }

        var request = createDefaultRequest()
        let solanaKeypair = try NaclSign.KeyPair.keyPair(fromSecretKey: solPrivateKey)

        let rpcRequest = JSONRPCRequest(
            id: requestID,
            method: "restore_wallet",
            params: APIGatewayRestoreWalletParams(
                restoreId: Base58.encode(solanaKeypair.publicKey),
                phone: phone,
                // appHash: "",
                channel: channel.rawValue,
                signature: try RestoreWalletSignature(
                    restoreId: Base58.encode(solanaKeypair.publicKey),
                    phone: phone,
                    appHash: "",
                    channel: channel.rawValue
                ).signAsBase58(secretKey: solPrivateKey),
                timestampDevice: dateFormat.string(from: timestampDevice)
            )
        )
        requestID += 1

        request.httpBody = try JSONEncoder().encode(rpcRequest)
        print(request.cURL(pretty: true))

        // Request
        let responseData = try await networkManager.requestData(request: request)

        // Check result
        let result = try JSONDecoder().decode(JSONRPCResponse<APIGatewayClientResult>.self, from: responseData)
        if let error = result.error {
            throw APIGatewayError(rawValue: error.code) ?? UndefinedAPIGatewayError(code: error.code)
        } else if result.result?.status != true {
            throw APIGatewayError.failedSending
        }
    }

    public func confirmRestoreWallet(
        solanaPrivateKey: Data,
        phone: String,
        otpCode: String,
        timestampDevice: Date
    ) async throws -> RestoreWalletResult {
        guard E164Numbers.validate(phone) else { throw APIGatewayError.invalidE164NumberStandard }

        var request = createDefaultRequest()
        let solanaKeypair = try NaclSign.KeyPair.keyPair(fromSecretKey: solanaPrivateKey)

        let rpcRequest = JSONRPCRequest(
            id: requestID,
            method: "confirm_restore_wallet",
            params: APIGatewayConfirmRestoreWalletParams(
                restoreId: Base58.encode(solanaKeypair.publicKey),
                phone: phone,
                phoneConfirmationCode: otpCode,
                signature: try ConfirmRestoreWalletSignature(
                    restoreId: Base58.encode(solanaKeypair.publicKey),
                    phone: phone,
                    phoneConfirmationCode: otpCode
                ).signAsBase58(secretKey: solanaPrivateKey),
                timestampDevice: dateFormat.string(from: timestampDevice)
            )
        )
        requestID += 1

        request.httpBody = try JSONEncoder().encode(rpcRequest)
        print(request.cURL(pretty: true))

        // Request
        let responseData = try await networkManager.requestData(request: request)

        // Check result
        let response = try JSONDecoder()
            .decode(JSONRPCResponse<APIGatewayClientConfirmRestoreWalletResult>.self, from: responseData)
        if let error = response.error {
            throw APIGatewayError(rawValue: error.code) ?? UndefinedAPIGatewayError(code: error.code)
        } else if response.result?.status != true {
            throw APIGatewayError.failedSending
        }

        guard let result = response.result else { throw APIGatewayError.failedSending }
        return .init(
            solanaPublicKey: result.solanaPublicKey,
            ethereumId: result.ethereumAddress,
            encryptedShare: try result.share.fromBase64(),
            encryptedPayload: try result.payload.fromBase64()
        )
    }
}

private extension String {
    func base64() -> String {
        Data(utf8).base64EncodedString()
    }

    func fromBase64() throws -> String {
        guard
            let data = Data(base64Encoded: self),
            let result = String(data: data, encoding: .utf8)
        else {
            throw APIGatewayError.failedConvertingFromBase64
        }

        return result
    }
}
