// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import XCTest
@testable import Onboarding

class OnboardingStateMachineTests: XCTestCase {
    func testGeneralFlow() async throws {
        let stateMachine = StateMachine<OnboardingState>(initialState: .socialSignIn)

        // Sign in with apple
        var nextState = try await stateMachine.accept(event: .signIn(tokenID: "SomeTokenID", type: .apple))
        print("Current state: \(await stateMachine.currentState)")

        switch nextState {
        case .enterPhoneNumber: break
        default: XCTFail("Expected .enterPhoneNumber state")
        }

        // Enter phone number
        nextState = try await stateMachine.accept(event: .enterPhoneNumber(phoneNumber: "999999999"))
        print("Current state: \(await stateMachine.currentState)")

        // Enter verify code
        nextState = try await stateMachine.accept(event: .enterSmsConfirmationCode(code: "1234"))
        print("Current state: \(await stateMachine.currentState)")

        // Enter pincode
        nextState = try await stateMachine.accept(event: .enterPincode(pincode: "1234"))
        print("Current state: \(await stateMachine.currentState)")
        
        switch nextState {
        case .finish: break
        default: XCTFail("Expected .enterPhoneNumber state")
        }
    }
}
