// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift
import TweetNacl

public typealias BindingPhoneNumberChannel = APIGatewayChannel

public enum BindingPhoneNumberResult: Codable {
    case success
}

public enum BindingPhoneNumberEvent {
    case enterPhoneNumber(phoneNumber: String, channel: BindingPhoneNumberChannel)
    case enterOTP(opt: String)
    case resendOTP
    case back
}

public struct BindingPhoneNumberData: Codable, Equatable {
    let solanaPublicKey: String
    let ethereumId: String
    let customShare: String
    let payload: String
}

public enum BindingPhoneNumberState: Codable, State, Equatable {
    public typealias Event = BindingPhoneNumberEvent
    public typealias Provider = APIGatewayClient

    case enterPhoneNumber(initialPhoneNumber: String?, data: BindingPhoneNumberData)
    case enterOTP(channel: BindingPhoneNumberChannel, phoneNumber: String, data: BindingPhoneNumberData)
    case finish(_ result: BindingPhoneNumberResult)

    public static var initialState: BindingPhoneNumberState = .enterPhoneNumber(
        initialPhoneNumber: nil,
        data: .init(solanaPublicKey: "", ethereumId: "", customShare: "", payload: "")
    )

    public static func createInitialState(provider _: Provider) async -> BindingPhoneNumberState {
        BindingPhoneNumberState.initialState
    }

    public func accept(
        currentState: BindingPhoneNumberState,
        event: BindingPhoneNumberEvent,
        provider: APIGatewayClient
    ) async throws -> BindingPhoneNumberState {
        switch currentState {
        case let .enterPhoneNumber(_, data):
            switch event {
            case let .enterPhoneNumber(phoneNumber, channel):
                let account = try await Account(
                    phrase: data.solanaPublicKey.components(separatedBy: " "),
                    network: .mainnetBeta,
                    derivablePath: .default
                )

                do {
                    try await provider.registerWallet(
                        solanaPrivateKey: Base58.encode(account.secretKey),
                        ethereumId: data.ethereumId,
                        phone: phoneNumber,
                        channel: channel,
                        timestampDevice: Date()
                    )
                } catch let error as APIGatewayError {
                    switch error._code {
                    // case -32056:
                    //     return .finish(.success)
                    default:
                        throw error
                    }
                }

                return .enterOTP(
                    channel: channel,
                    phoneNumber: phoneNumber,
                    data: data
                )
            default:
                throw StateMachineError.invalidEvent
            }
        case let .enterOTP(channel, phoneNumber, data):
            switch event {
            case let .enterOTP(opt):
                let account = try await Account(
                    phrase: data.solanaPublicKey.components(separatedBy: " "),
                    network: .mainnetBeta,
                    derivablePath: .default
                )

                do {
                    try await provider.confirmRegisterWallet(
                        solanaPrivateKey: Base58.encode(account.secretKey),
                        ethereumId: data.ethereumId,
                        share: data.customShare,
                        encryptedPayload: data.payload,
                        phone: phoneNumber,
                        otpCode: opt,
                        timestampDevice: Date()
                    )
                } catch let error as APIGatewayError {
                    switch error._code {
                    // case -32056:
                    //     return .finish(.success)
                    default:
                        throw error
                    }
                }

                return .finish(.success)
            case .resendOTP:
                let account = try await Account(
                    phrase: data.solanaPublicKey.components(separatedBy: " "),
                    network: .mainnetBeta,
                    derivablePath: .default
                )

                try await provider.registerWallet(
                    solanaPrivateKey: Base58.encode(account.secretKey),
                    ethereumId: data.ethereumId,
                    phone: phoneNumber,
                    channel: channel,
                    timestampDevice: Date()
                )

                return currentState
            case .back:
                return .enterPhoneNumber(
                    initialPhoneNumber: phoneNumber,
                    data: data
                )
            default:
                throw StateMachineError.invalidEvent
            }
        default:
            throw StateMachineError.invalidEvent
        }
    }
}

extension BindingPhoneNumberState: Step, Continuable {
    public var continuable: Bool { true }

    public var step: Float {
        switch self {
        case .enterPhoneNumber:
            return 1
        case .enterOTP:
            return 2
        case .finish:
            return 3
        }
    }
}
