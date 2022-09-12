//
// Created by Tran Hai Bac on 12.09.2022.
//

import XCTest
@testable import Onboarding

class SocialSignInTests: XCTestCase {
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
        do {
            var nextState = try await stateMachine.accept(event: .socialSignInEvent(.signIn(socialProvider: .apple)))
            print("Current state: \(stateMachine.currentState)")
            XCTFail()
        } catch {

        }

    }
}