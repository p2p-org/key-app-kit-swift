//
// Created by Tran Hai Bac on 12.09.2022.
//

import XCTest
@testable import Onboarding

class CreateWalletFlowStateMachineTests: XCTestCase {
    func testSignIn1() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .socialSignIn(.socialSelection), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .socialSignInEvent(.signIn(socialProvider: .google)))

        guard case .bindingPhoneNumber = nextState else {
            XCTFail("Expected .bindingPhoneNumber, but was \(nextState)")
            return
        }
    }

    func testSignIn2() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .socialSignIn(.socialSelection), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .socialSignInEvent(.signInBack))

        guard case .finish(.breakProcess) = nextState else {
            XCTFail("Expected .finish(.breakProcess), but was \(nextState)")
            return
        }
    }

    func testSignIn3() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .socialSignIn(.socialSignInAccountWasUsed(signInProvider: .google, usedEmail: "abc@gmail.com")), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .socialSignInEvent(.restore(authProvider: .google, email: "abc@gmail.com")))

        guard case .finish = nextState else {
            XCTFail("Expected .finish(.breakProcess), but was \(nextState)")
            return
        }
    }

    func testSignIn4() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .socialSignIn(.socialSignInAccountWasUsed(signInProvider: .google, usedEmail: "abc@gmail.com")), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .socialSignInEvent(.signInBack))

        guard case .socialSignIn = nextState else {
            XCTFail("Expected .finish(.breakProcess), but was \(nextState)")
            return
        }
    }

    func testBindingPhoneNumber1() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .bindingPhoneNumber(email: "abc@gmail.com", seedPhrase: "", ethPublicKey: "", deviceShare: "", .enterOTP(resendAttempt: .init(0), channel: .call, phoneNumber: "1234567890", data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: ""))), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .bindingPhoneNumberEvent(.enterOTP(opt: "000000")))

        guard case .securitySetup = nextState else {
            XCTFail("Expected .bindingPhoneNumber, but was \(nextState)")
            return
        }
    }

    func testBindingPhoneNumber2() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .bindingPhoneNumber(email: "abc@gmail.com", seedPhrase: "", ethPublicKey: "", deviceShare: "", .enterPhoneNumber(initialPhoneNumber: "1234567890", didSend: true, data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: ""))), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .bindingPhoneNumberEvent(.enterPhoneNumber(phoneNumber: "1234567890", channel: .sms)))

        guard case .bindingPhoneNumber = nextState else {
            XCTFail("Expected .bindingPhoneNumber, but was \(nextState)")
            return
        }
    }

    func testSecuritySetup1() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .securitySetup(email: "", wallet: .init(seedPhrase: ""), ethPublicKey: "", deviceShare: "", .confirmPincode(pincode: "0000")), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .securitySetup(.setPincode(pincode: "0000", isBiometryEnabled: false)))
        guard case .finish = nextState else {
            XCTFail("Expected .bindingPhoneNumber, but was \(nextState)")
            return
        }
    }

    func testSecuritySetup2() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .securitySetup(email: "", wallet: .init(seedPhrase: ""), ethPublicKey: "", deviceShare: "", .initialState), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))
        do {
            var nextState = try await stateMachine.accept(event: .securitySetup(.createPincode))
            print("Current state: \(stateMachine.currentState)")
        } catch {}
    }

}