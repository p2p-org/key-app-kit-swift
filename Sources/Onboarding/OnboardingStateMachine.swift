// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public typealias OnboardingStateMachine = StateMachine<OnboardingState>

public enum OnboardingState: Codable, State, Equatable {
    public typealias Event = OnboardingEvent
    public private(set) static var initialState: OnboardingState = .socialSignIn

    case socialSignIn
    case socialSignInUnhandleableError

    case enterPhoneNumber(solPrivateKey: String, ethPublicKey: String, deviceShare: String)
    case verifyPhoneNumber(solPrivateKey: String, ethPublicKey: String, deviceShare: String, phoneNumber: String)
    case enterPincode(solPrivateKey: String, ethPublicKey: String, deviceShare: String, phoneNumberShare: String)

    // Final state
    case finish(solPrivateKey: String, ethPublicKey: String, deviceShare: String, phoneNumberShare: String, pincode: String)
    
    public func accept(currentState: OnboardingState, event: OnboardingEvent) async throws -> OnboardingState {
        switch currentState {
        case .socialSignIn:
            if case let .signIn(tokenID, provider) = event {
                print("Login into torus with \(tokenID) from \(provider)")
                return .enterPhoneNumber(
                    solPrivateKey: "fakeSolPrivateKey",
                    ethPublicKey: "fakeEthPublicKey",
                    deviceShare: "someDeviceToken"
                )
            }
        case .socialSignInUnhandleableError:
            break
        case let .enterPhoneNumber(solPrivateKey: solPrivateKey, ethPublicKey: ethPublicKey, deviceShare: deviceShare):
            if case let .enterPhoneNumber(phoneNumber) = event {
                print("Send sms to phone number: \(phoneNumber)")
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
                print("Enter sms confirmation code: \(code)")
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
                print("Enter pincode: \(pincode)")
                return .finish(
                    solPrivateKey: solPrivateKey,
                    ethPublicKey: ethPublicKey,
                    deviceShare: deviceShare,
                    phoneNumberShare: phoneNumberShare,
                    pincode: pincode
                )
            }
        case .finish: return currentState
        }

        throw StateMachineError.invalidEvent
    }
}

public enum SignInProvider {
    case apple
    case google
}

public enum OnboardingEvent {
    case signIn(tokenID: String, type: SignInProvider)
    case enterPhoneNumber(phoneNumber: String)
    case enterSmsConfirmationCode(code: String)
    case enterPincode(pincode: String)
}
