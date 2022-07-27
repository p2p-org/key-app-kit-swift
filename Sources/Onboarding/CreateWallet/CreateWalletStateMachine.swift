// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public typealias CreateWalletStateMachine = StateMachine<CreateWalletState>

public enum SignInProvider: String, Codable {
    case apple
    case google
}

public enum CreateWalletEvent {
    // Sign in step
    case signIn(tokenID: String, authProvider: SignInProvider, email: String)
    case signInBack
    case signInRerouteToRestore(authProvider: SignInProvider, email: String)

    case enterPhoneNumber(phoneNumber: String)
    case enterSmsConfirmationCode(code: String)

    case enterPincode(pincode: String)
}

public enum CreateWalletState: Codable, State, Equatable {
    public typealias Event = CreateWalletEvent
    public typealias Provider = TKeyFacade

    public private(set) static var initialState: CreateWalletState = .socialSignIn

    // States
    case socialSignIn
    case socialSignInAccountWasUsed(provider: SignInProvider, usedEmail: String)
    case socialSignInUnhandleableError

    case enterPhoneNumber(solPrivateKey: String, ethPublicKey: String, deviceShare: String)
    case verifyPhoneNumber(solPrivateKey: String, ethPublicKey: String, deviceShare: String, phoneNumber: String)
    case enterPincode(solPrivateKey: String, ethPublicKey: String, deviceShare: String, phoneNumberShare: String)

    // Special state
    // case retry(lastState: Self, event: Event)

    // Final state
    case finish(
        solPrivateKey: String,
        ethPublicKey: String,
        deviceShare: String,
        phoneNumberShare: String,
        pincode: String
    )
    case finishWithoutResult
    case finishWithRerouteToRestore(signInProvider: SignInProvider, email: String)

    public func accept(
        currentState: CreateWalletState,
        event: CreateWalletEvent,
        provider: TKeyFacade
    ) async throws -> CreateWalletState {
        switch currentState {
        case .socialSignIn:
            return try await socialSignInHandler(currentState: currentState, event: event, provider: provider)
        case .socialSignInAccountWasUsed:
            return try await socialSignInAccountWasUsedHandler(
                currentState: currentState,
                event: event,
                provider: provider
            )
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
}

public extension CreateWalletState {
    var step: Float {
        switch self {
        case .socialSignIn:
            return 1.0
        case .socialSignInAccountWasUsed:
            return 1.1
        case .socialSignInUnhandleableError:
            return 1.2
        case .enterPhoneNumber:
            return 2.0
        case .verifyPhoneNumber:
            return 2.1
        case .enterPincode:
            return 3.0
        case .finish, .finishWithoutResult, .finishWithRerouteToRestore:
            return 4.0
        }
    }
}
