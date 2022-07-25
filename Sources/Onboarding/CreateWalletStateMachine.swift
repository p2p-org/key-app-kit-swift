// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public typealias CreateWalletStateMachine = StateMachine<CreateWalletState>

public enum CreateWalletState: Codable, State, Equatable {
    public typealias Event = CreateWalletEvent
    public typealias Provider = TKeyFacade

    public private(set) static var initialState: CreateWalletState = .socialSignIn

    // States
    case socialSignIn
    case socialSignInUnhandleableError

    case enterPhoneNumber(solPrivateKey: String, ethPublicKey: String, deviceShare: String)
    case verifyPhoneNumber(solPrivateKey: String, ethPublicKey: String, deviceShare: String, phoneNumber: String)
    case enterPincode(solPrivateKey: String, ethPublicKey: String, deviceShare: String, phoneNumberShare: String)

    // Final state
    case finish(
        solPrivateKey: String,
        ethPublicKey: String,
        deviceShare: String,
        phoneNumberShare: String,
        pincode: String
    )
    case finishWithoutResult

    public func accept(
        currentState: CreateWalletState,
        event: CreateWalletEvent,
        provider: TKeyFacade
    ) async throws -> CreateWalletState {
        switch currentState {
        case .socialSignIn:
            return try await socialSignInHandler(event: event, provider: provider)
        case .socialSignInUnhandleableError:
            return currentState
        case let .enterPhoneNumber(solPrivateKey: solPrivateKey, ethPublicKey: ethPublicKey, deviceShare: deviceShare):
            if case let .enterPhoneNumber(phoneNumber) = event {
                return .verifyPhoneNumber(
                    solPrivateKey: solPrivateKey,
                    ethPublicKey: ethPublicKey,
                    deviceShare: deviceShare,
                    phoneNumber: phoneNumber
                )
            }
        case let .verifyPhoneNumber(
            solPrivateKey: solPrivateKey,
            ethPublicKey: ethPublicKey,
            deviceShare: deviceShare,
            phoneNumber: phoneNumber
        ):
            if case let .enterSmsConfirmationCode(code) = event {
                return .enterPincode(
                    solPrivateKey: solPrivateKey,
                    ethPublicKey: ethPublicKey,
                    deviceShare: deviceShare,
                    phoneNumberShare: phoneNumber
                )
            }
        case let .enterPincode(
            solPrivateKey: solPrivateKey,
            ethPublicKey: ethPublicKey,
            deviceShare: deviceShare,
            phoneNumberShare: phoneNumberShare
        ):
            if case let .enterPincode(pincode) = event {
                return .finish(
                    solPrivateKey: solPrivateKey,
                    ethPublicKey: ethPublicKey,
                    deviceShare: deviceShare,
                    phoneNumberShare: phoneNumberShare,
                    pincode: pincode
                )
            }
        default: throw StateMachineError.invalidEvent
        }
        throw StateMachineError.invalidEvent
    }

    internal func socialSignInHandler(event: Event, provider: Provider) async throws -> Self {
        switch event {
        case let .signIn(tokenID, authProvider):
            let result = try await provider.signUp(tokenID: .init(value: tokenID, provider: authProvider.rawValue))
            return .enterPhoneNumber(
                solPrivateKey: result.privateSOL,
                ethPublicKey: result.reconstructedETH,
                deviceShare: result.deviceShare
            )
        case .signInBack:
            return .finishWithoutResult
        default:
            throw StateMachineError.invalidEvent
        }
    }
}

public enum SignInProvider: String {
    case apple
    case google
}

public enum CreateWalletEvent {
    // Sign in step
    case signIn(tokenID: String, authProvider: SignInProvider)
    case signInBack

    case enterPhoneNumber(phoneNumber: String)
    case enterSmsConfirmationCode(code: String)

    case enterPincode(pincode: String)
}
