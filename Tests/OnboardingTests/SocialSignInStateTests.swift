//
// Created by Tran Hai Bac on 12.09.2022.
//

import XCTest
@testable import Onboarding

class SocialSignInTests: XCTestCase {
    func testSocialSignIn() async throws {
        let state: SocialSignInState = .socialSelection

        var nextState = try await state <- (
                event: .signIn(socialProvider: .apple),
                provider: SocialSignInContainer(tKeyFacade: TKeyMockupFacade(), authService: SocialAuthServiceMock())
        )
        guard case .finish(.successful) = nextState else {
            XCTFail("Expected .finish(.successful), but was \(nextState)")
            return
        }
    }

    func testSocialSignInBack() async throws {
        let state: SocialSignInState = .socialSignInTryAgain(signInProvider: .apple, usedEmail: "abc@gmail.com")

        var nextState = try await state <- (
                event: .signInBack,
                provider: SocialSignInContainer(tKeyFacade: TKeyMockupFacade(), authService: SocialAuthServiceMock())
        )
        guard case .finish(.breakProcess) = nextState else {
            XCTFail("Expected .finish(.breakProcess), but was \(nextState)")
            return
        }
    }

    func testSocialSignInSwitchRestoreFlow() async throws {
        let state: SocialSignInState = .socialSignInAccountWasUsed(signInProvider: .apple, usedEmail: "abc@gmail.com")

        var nextState = try await state <- (
                event: .restore(authProvider: .apple, email: "someEmail"),
                provider: SocialSignInContainer(tKeyFacade: TKeyMockupFacade(), authService: SocialAuthServiceMock())
        )
        guard case .finish(.switchToRestoreFlow) = nextState else {
            XCTFail("Expected .finish(.switchToRestoreFlow), but was \(nextState)")
            return
        }
    }

    func testSocialSignIn2() async throws {
        let state: SocialSignInState = .finish(.breakProcess)

        do {
            var nextState = try await state <- (
                    event: .signIn(socialProvider: .apple),
                    provider: SocialSignInContainer(tKeyFacade: TKeyMockupFacade(), authService: SocialAuthServiceMock())
            )
            print("Current state: \(nextState)")
        } catch {}
    }

    func testSocialTryAgainEventHandler() async throws {
        let state: SocialSignInState = .socialSignInTryAgain(signInProvider: .apple, usedEmail: "abc@gmail.com")

        let nextState = try await state <- (
                event: .signIn(socialProvider: .apple),
                provider: .init(tKeyFacade: TKeyMockupFacade(), authService: SocialAuthServiceMock())
        )

        guard case .finish(.successful) = nextState else {
            XCTFail("Expected .finish(.successful), but was \(nextState)")
            return
        }
    }

    func testSocialTryAgainEventHandlerError() async throws {
        let state: SocialSignInState = .socialSignInTryAgain(signInProvider: .apple, usedEmail: "abc@gmail.com")

        let nextState = try await state <- (
                event: .signIn(socialProvider: .apple),
                provider: .init(tKeyFacade: TKeyFacadeErrorMock(errorCode: 1009), authService: SocialAuthServiceMock())
        )

        guard case .socialSignInAccountWasUsed = nextState else {
            XCTFail("Expected .socialSignInAccountWasUsed, but was \(nextState)")
            return
        }
    }


    func testSocialSignInError() async throws {
       let state: SocialSignInState = .socialSelection

        var nextState = try await state <- (
                event: .signIn(socialProvider: .apple),
                provider: SocialSignInContainer(tKeyFacade: TKeyFacadeErrorMock(errorCode: 1009), authService: SocialAuthServiceMock())
        )
        guard case .socialSignInAccountWasUsed = nextState else {
            XCTFail("Expected ..socialSignInAccountWasUsed, but was \(nextState)")
            return
        }
    }
}
