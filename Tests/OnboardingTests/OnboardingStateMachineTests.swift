// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import XCTest
@testable import Onboarding

class OnboardingStateMachineTests: XCTestCase {
     func testSocialSignIn() async throws {
         let stateMachine = CreateWalletStateMachine(initialState: .socialSignIn(SocialSignInState.socialSelection), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

         var nextState = try await stateMachine.accept(event: .socialSignInEvent(.signIn(socialProvider: .apple)))
         print("Current state: \(stateMachine.currentState)")
     }

    func testSocialSignInBreakProcess() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .socialSignIn(SocialSignInState.socialSignInTryAgain(signInProvider: .apple, usedEmail: "someUsedEmail")), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .socialSignInEvent(.signInBack))
        print("Current state: \(stateMachine.currentState)")
    }

    func testSocialSignInSwitchRestoreFlow() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .socialSignIn(SocialSignInState.socialSignInAccountWasUsed(signInProvider: .apple, usedEmail: "someUsedEmail")), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .socialSignInEvent(.restore(authProvider: .apple, email: "someEmail")))
        print("Current state: \(stateMachine.currentState)")
    }

    func testSocialSignIn2() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .socialSignIn(SocialSignInState.finish(.breakProcess)), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .socialSignInEvent(.signIn(socialProvider: .apple)))
        print("Current state: \(stateMachine.currentState)")
    }

    func testBindingPhoneNumber() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .bindingPhoneNumber(email: "someEmail", seedPhrase: "someSeedPhrase", ethPublicKey: "someEthPublicKey", deviceShare: "someDeviceShare", BindingPhoneNumberState.initialState), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .bindingPhoneNumberEvent(.enterPhoneNumber(phoneNumber: "somePhoneNumber", channel: BindingPhoneNumberChannel.call)))
        print("Current state: \(stateMachine.currentState)")
    }


}
