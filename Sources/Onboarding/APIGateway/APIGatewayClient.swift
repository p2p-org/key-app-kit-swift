// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public enum APIGatewayError: Int, Error, CaseIterable {
    case invalidOTP = -32061
    case wait10Min = -32053
    case invalidSignature = -32058
    case parseError = -32700
    case invalidRequest = -32600
    case methodNotFound = -32601
    case invalidParams = -32602
    case internalError = -32603
    case everythingIsBroken = -32052
    case retry = -32050
    case changePhone = -32054
    case alreadyConfirmed = -32051
    case callNotPermit = -32055
    case publicKeyExists = -32056
    case publicKeyAndPhoneExists = -32057
}

public enum APIGatewayChannel: String {
    case sms
    case call
}

public struct RestoreWalletResult: Codable {
    let solanaPublicKey: String
    let ethereumId: String
    let encryptedShare: String
    let encryptedPayload: String
}

public protocol APIGatewayClient {
    /// Binding a phone number to solana wallet
    ///
    /// - Parameters:
    ///   - solanaPublicKey: Base58 key.
    ///   - ethereumId: Ethereum public key.
    ///   - phone: E.164 phone number format.
    ///   - channel: The channel through which the otp code will be delivered.
    ///   - timestampDevice: Timestamp of request.
    /// - Throws: ``APIGatewayError``
    func registerWallet(
        solanaPublicKey: String,
        ethereumId: String,
        phone: String,
        channel: APIGatewayChannel,
        timestampDevice: Date
    ) async throws

    /// Confirm binding by delivered otp code.
    ///
    /// - Parameters:
    ///   - solanaPublicKey: Base58 key.
    ///   - ethereumId: Ethereum public key.
    ///   - share: TKey share.
    ///   - encryptedPayload: Encrypted mnemonic (base64).
    ///   - phone: E.164 phone number format.
    ///   - otpCode: delivered OTP code
    ///   - timestampDevice:
    func confirmRegisterWallet(
        solanaPublicKey: String,
        ethereumId: String,
        share: String,
        encryptedPayload: String,
        phone: String,
        otpCode: String,
        timestampDevice: Date
    ) async throws

    /// Restore wallet by using phone number.
    ///
    /// The user will get a share after success confirmation (by calling ``confirmRestoreWallet``).
    /// - Parameters:
    ///   - phone: E.164 phone number format.
    ///   - timestampDevice:
    ///   - restoreID: Temporary solana public key.
    func restoreWallet(
        phone: String,
        timestampDevice: Date,
        restoreID: String
    ) async throws

    /// Confirm restore by sending otp code.
    ///
    /// The user will get a share after success confirmation.
    /// - Parameters:
    ///   - phone: E.164 phone number format.
    ///   - otpCode: delivered OTP code
    ///   - timestampDevice:
    ///   - restoreID:
    func confirmRestoreWallet(
        phone: String,
        otpCode: String,
        timestampDevice: Date,
        restoreID: String
    ) async throws -> RestoreWalletResult

    func isValidOTPFormat(code: String) -> Bool
}

public extension APIGatewayClient {
    func isValidOTPFormat(code: String) -> Bool { code.count == 6 }
}

public class APIGatewayClientImpl: APIGatewayClient {
    public func registerWallet(
        solanaPublicKey _: String,
        ethereumId _: String,
        phone _: String,
        channel _: APIGatewayChannel,
        timestampDevice _: Date
    ) async throws {
        fatalError()
    }

    public func confirmRegisterWallet(
        solanaPublicKey _: String,
        ethereumId _: String,
        share _: String,
        encryptedPayload _: String,
        phone _: String,
        otpCode _: String,
        timestampDevice _: Date
    ) async throws {
        fatalError()
    }

    public func restoreWallet(phone _: String, timestampDevice _: Date, restoreID _: String) async throws {
        fatalError()
    }

    public func confirmRestoreWallet(
        phone _: String,
        otpCode _: String,
        timestampDevice _: Date,
        restoreID _: String
    ) async throws -> RestoreWalletResult {
        fatalError()
    }
}

public class APIGatewayClientImplMock: APIGatewayClient {
    private var code = "000000"

    public init() {}

    public func registerWallet(
        solanaPublicKey _: String,
        ethereumId _: String,
        phone: String,
        channel _: APIGatewayChannel,
        timestampDevice _: Date
    ) async throws {
        debugPrint("SMSServiceImplMock code: \(code) for phone \(phone)")
        sleep(4)

        if
            let exep = APIGatewayError(rawValue: -(Int(String(phone.suffix(5))) ?? 0)),
            exep.rawValue != APIGatewayError.invalidOTP.rawValue
        {
            throw exep
        }
    }

    public func confirmRegisterWallet(
        solanaPublicKey _: String,
        ethereumId _: String,
        share _: String,
        encryptedPayload _: String,
        phone: String,
        otpCode: String,
        timestampDevice _: Date
    ) async throws {
        sleep(4)
        debugPrint("SMSServiceImplMock confirm isConfirmed: \(code == code)")

        if
            let exep = APIGatewayError(rawValue: -(Int(otpCode) ?? 0)),
            exep.rawValue != APIGatewayError.invalidOTP.rawValue
        {
            throw exep
        }

        guard otpCode == code else {
            throw APIGatewayError.invalidOTP
        }
    }

    public func restoreWallet(phone _: String, timestampDevice _: Date, restoreID _: String) async throws {
        fatalError()
    }

    public func confirmRestoreWallet(
        phone _: String,
        otpCode _: String,
        timestampDevice _: Date,
        restoreID _: String
    ) async throws -> RestoreWalletResult {
        fatalError()
    }
}
