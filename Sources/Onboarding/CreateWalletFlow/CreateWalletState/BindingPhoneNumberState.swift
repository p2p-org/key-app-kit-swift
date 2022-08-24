// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift
import TweetNacl

public typealias BindingPhoneNumberChannel = APIGatewayChannel

public enum BindingPhoneNumberResult: Codable {
    case success
    case breakProcess
}

public enum BindingPhoneBlockReason: Codable {
    case blockEnterPhoneNumber
    case blockEnterOTP
}

public enum BindingPhoneNumberEvent {
    case enterPhoneNumber(phoneNumber: String, channel: BindingPhoneNumberChannel)
    case enterOTP(opt: String)
    case resendOTP
    case blockFinish
    case home
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
    case block(until: Date, reason: BindingPhoneBlockReason, phoneNumber: String, data: BindingPhoneNumberData)
    case broken
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
                    case -32058, -32700, -32600, -32601, -32602, -32603, -32052:
                        return .broken
                    case -32053:
                        return .block(
                            until: Date() + (60 * 10),
                            reason: .blockEnterPhoneNumber,
                            phoneNumber: phoneNumber,
                            data: data
                        )
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
                    case -32058, -32700, -32600, -32601, -32602, -32603, -32052:
                        return .broken
                    case -32053:
                        return .block(
                            until: Date() + (60 * 10),
                            reason: .blockEnterOTP,
                            phoneNumber: phoneNumber,
                            data: data
                        )
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
        case .broken:
            switch event {
            case .back:
                return .finish(.breakProcess)
            default:
                throw StateMachineError.invalidEvent
            }
        case let .block(until, reason, phoneNumber, data):
            switch event {
            case .home:
                return .finish(.breakProcess)
            case .blockFinish:
                guard Date() > until else { throw StateMachineError.invalidEvent }
                switch reason {
                case .blockEnterPhoneNumber:
                    return .enterPhoneNumber(
                        initialPhoneNumber: phoneNumber,
                        data: data
                    )
                case .blockEnterOTP:
                    return .enterPhoneNumber(
                        initialPhoneNumber: phoneNumber,
                        data: data
                    )
                }
            default: throw StateMachineError.invalidEvent
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
        case .block:
            return 3
        case .broken:
            return 4
        case .finish:
            return 5
        }
    }
}
