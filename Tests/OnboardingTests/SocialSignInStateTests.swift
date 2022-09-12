//
// Created by Tran Hai Bac on 12.09.2022.
//

import XCTest
@testable import Onboarding

class SocialSignInTests: XCTestCase {
    func testSocialSignIn() async throws {
        let stateMachine: StateMachine<SocialSignInState> = StateMachine(
            initialState: .socialSelection,
            provider: SocialSignInContainer(tKeyFacade: TKeyMockupFacade(), authService: SocialAuthServiceMock())
        )

        var nextState = try await stateMachine.accept(event: .signIn(socialProvider: .apple))
        guard case .finish(.successful) = nextState else {
            XCTFail("Expected .finish(.successful), but was \(nextState)")
            return
        }
    }

    func testSocialSignInBack() async throws {
        let stateMachine: StateMachine<SocialSignInState> = StateMachine(
            initialState: .socialSignInTryAgain(signInProvider: .apple, usedEmail: "abc@gmail.com"),
            provider: SocialSignInContainer(tKeyFacade: TKeyMockupFacade(), authService: SocialAuthServiceMock())
        )

        var nextState = try await stateMachine.accept(event: .signInBack)
        guard case .finish(.breakProcess) = nextState else {
            XCTFail("Expected .finish(.successful), but was \(nextState)")
            return
        }
    }

    func testSocialSignInSwitchRestoreFlow() async throws {
        let stateMachine: StateMachine<SocialSignInState> = StateMachine(
            initialState: .socialSignInAccountWasUsed(signInProvider: .apple, usedEmail: "abc@gmail.com"),
            provider: SocialSignInContainer(tKeyFacade: TKeyMockupFacade(), authService: SocialAuthServiceMock())
        )

        var nextState = try await stateMachine
            .accept(event: .restore(authProvider: .apple, email: "someEmail"))

        guard case .finish(.switchToRestoreFlow) = nextState else {
            XCTFail("Expected .finish(.successful), but was \(nextState)")
            return
        }
    }

    func testSocialSignIn2() async throws {
        let stateMachine: StateMachine<SocialSignInState> = StateMachine(
            initialState: .finish(.breakProcess),
            provider: SocialSignInContainer(tKeyFacade: TKeyMockupFacade(), authService: SocialAuthServiceMock())
        )
        do {
            var nextState = try await stateMachine.accept(event: .signIn(socialProvider: .apple))
            print("Current state: \(stateMachine.currentState)")
            XCTFail()
        } catch {}
    }

    func testSocialTryAgainEventHandler() async throws {
        let state: SocialSignInState = .socialSignInTryAgain(signInProvider: .apple, usedEmail: "abc@gmail.com")

//        let nextState = try await state.socialTryAgainEventHandler(currentState: state, event: .signIn(socialProvider: .apple), provider: .init(tKeyFacade: TKeyMockupFacade(), authService: SocialAuthServiceMock()))
        let nextState = try await state <- (
            event: .signIn(socialProvider: .apple),
            provider: .init(tKeyFacade: TKeyMockupFacade(), authService: SocialAuthServiceMock())
        )

        guard case .finish(.successful) = nextState else {
            XCTFail("Expected .finish(.successful), but was \(nextState)")
            return
        }
    }
}
