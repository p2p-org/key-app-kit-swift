// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

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
    let share: String
    let payload: String
}

public enum BindingPhoneNumberState: Codable, State, Equatable {
    public typealias Event = BindingPhoneNumberEvent
    public typealias Provider = APIGatewayClient

    case enterPhoneNumber(initialPhoneNumber: String?, data: BindingPhoneNumberData)
    case enterOTP(phoneNumber: String, data: BindingPhoneNumberData)
    case finish(_ result: BindingPhoneNumberResult)

    public static var initialState: BindingPhoneNumberState = .enterPhoneNumber(
        initialPhoneNumber: nil,
        data: .init(solanaPublicKey: "", ethereumId: "", share: "", payload: "")
    )

    public static func createInitialState(provider: Provider) async -> BindingPhoneNumberState {
        return BindingPhoneNumberState.initialState
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
                try await provider.registerWallet(
                    solanaPublicKey: data.solanaPublicKey,
                    ethereumId: data.ethereumId,
                    phone: phoneNumber,
                    channel: channel,
                    timestampDevice: Date()
                )

                return .enterOTP(
                    phoneNumber: phoneNumber,
                    data: data
                )
            default:
                throw StateMachineError.invalidEvent
            }
        case let .enterOTP(phoneNumber, data):
            switch event {
            case let .enterOTP(opt):
                try await provider.confirmRegisterWallet(
                    solanaPublicKey: data.solanaPublicKey,
                    ethereumId: data.ethereumId,
                    share: data.share,
                    encryptedPayload: data.payload,
                    phone: phoneNumber,
                    otpCode: opt,
                    timestampDevice: Date()
                )
                
                return .finish(.success)
            case .resendOTP:
                // TODO: How to resend?
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
        case let .enterPhoneNumber(initialPhoneNumber: initialPhoneNumber):
            return 1
        case let .enterOTP(phoneNumber: phoneNumber):
            return 2
        case .finish:
            return 3
        }
    }
}
