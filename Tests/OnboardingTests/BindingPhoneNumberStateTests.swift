//
// Created by Tran Hai Bac on 12.09.2022.
//

import XCTest
@testable import Onboarding

class BindingPhoneNumberTests: XCTestCase {
    func testBindingPhoneNumber() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .bindingPhoneNumber(email: "someEmail", seedPhrase: "someSeedPhrase", ethPublicKey: "someEthPublicKey", deviceShare: "someDeviceShare", BindingPhoneNumberState.initialState), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .bindingPhoneNumberEvent(.enterPhoneNumber(phoneNumber: "somePhoneNumber", channel: BindingPhoneNumberChannel.call)))
        print("Current state: \(stateMachine.currentState)")
    }

    func testBindingPhoneNumber2() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .bindingPhoneNumber(email: "someEmail", seedPhrase: "someSeedPhrase", ethPublicKey: "someEthPublicKey", deviceShare: "someDeviceShare", BindingPhoneNumberState.enterOTP(resendAttempt: Wrapper(0), channel: .sms, phoneNumber: "79182585928", data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: ""))), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .bindingPhoneNumberEvent(.enterOTP(opt: "000000")))
        print("Current state: \(stateMachine.currentState)")
    }

    func testBindingPhoneNumberBreakProcess() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .bindingPhoneNumber(email: "someEmail", seedPhrase: "someSeedPhrase", ethPublicKey: "someEthPublicKey", deviceShare: "someDeviceShare", BindingPhoneNumberState.block(until: .now, reason: .blockEnterPhoneNumber, phoneNumber: "79182585928", data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: ""))), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .bindingPhoneNumberEvent(.home))
        print("Current state: \(stateMachine.currentState)")
    }
}
