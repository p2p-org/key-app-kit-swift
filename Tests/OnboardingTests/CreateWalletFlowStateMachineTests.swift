//
// Created by Tran Hai Bac on 12.09.2022.
//

import XCTest
@testable import Onboarding

class CreateWalletStateMachineTests: XCTestCase {
    func testSignIn() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .socialSignIn(.initialState), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

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

    func testBindingPhoneNumber1() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .bindingPhoneNumber(email: "abc@gmail.com", seedPhrase: "", ethPublicKey: "", deviceShare: "", .finish(.success)), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .bindingPhoneNumberEvent(.enterPhoneNumber(phoneNumber: "1234567890", channel: .sms)))

        guard case .bindingPhoneNumber = nextState else {
            XCTFail("Expected .bindingPhoneNumber, but was \(nextState)")
            return
        }
    }

    func testBindingPhoneNumber2() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .bindingPhoneNumber(email: "abc@gmail.com", seedPhrase: "", ethPublicKey: "", deviceShare: "", .finish(.success)), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))
        print(stateMachine.currentState)
        var nextState = try await stateMachine.accept(event: .bindingPhoneNumberEvent(.enterPhoneNumber(phoneNumber: "1234567890", channel: .call)))
        print(stateMachine.currentState)

    }

}