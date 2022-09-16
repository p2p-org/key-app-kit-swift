//
// Created by Tran Hai Bac on 12.09.2022.
//

import XCTest
@testable import Onboarding

class BindingPhoneNumberTests: XCTestCase {
    func testBindingPhoneNumber() async throws {
        let stateMachine: StateMachine<BindingPhoneNumberState> = StateMachine(
                initialState: .enterPhoneNumber(
                        initialPhoneNumber: "1234567890",
                        didSend: false,
                        data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: "")
                ),
                provider: APIGatewayClientImplMock()
        )

        var nextState = try await stateMachine
                .accept(event: .enterPhoneNumber(phoneNumber: "1234567890",
                        channel: BindingPhoneNumberChannel.sms))
        print("Current state: \(stateMachine.currentState)")
    }

//    func testBindingPhoneNumber3() async throws {
//        let stateMachine: StateMachine<BindingPhoneNumberState> = StateMachine(
//                initialState: .enterPhoneNumber(
//                        initialPhoneNumber: "1234567890",
//                        didSend: true,
//                        data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: "")
//                ),
//                provider: APIGatewayClientImplMock()
//        )
//
//        var nextState = try await stateMachine.accept(event: .enterOTP(opt: "000000"))
//        print("Current state: \(stateMachine.currentState)")
//    }

    func testBindingPhoneNumber2() async throws {
        let stateMachine: StateMachine<BindingPhoneNumberState> = StateMachine(
                initialState: .enterOTP(
                        resendAttempt: .init(0),
                        channel: .sms,
                        phoneNumber: "1234567890",
                        data: .init(seedPhrase: "", ethAddress: "", customShare: "", payload: "")
                ),
                provider: APIGatewayClientImplMock()
        )

        var nextState = try await stateMachine.accept(event: .enterOTP(opt: "000000"))
        print("Current state: \(stateMachine.currentState)")
    }

    func testBindingPhoneNumberBreakProcess() async throws {
        let stateMachine = CreateWalletStateMachine(
                initialState: .bindingPhoneNumber(email: "someEmail", seedPhrase: "someSeedPhrase",
                        ethPublicKey: "someEthPublicKey", deviceShare: "someDeviceShare",
                        BindingPhoneNumberState.block(
                                until: .now,
                                reason: .blockEnterPhoneNumber,
                                phoneNumber: "79182585928",
                                data: .init(
                                        seedPhrase: "",
                                        ethAddress: "",
                                        customShare: "",
                                        payload: ""
                                )
                        )),
                provider: CreateWalletFlowContainer(
                        authService: SocialAuthServiceMock(),
                        apiGatewayClient: APIGatewayClientImplMock(),
                        tKeyFacade: TKeyMockupFacade()
                )
        )

        var nextState = try await stateMachine.accept(event: .bindingPhoneNumberEvent(.home))
        print("Current state: \(stateMachine.currentState)")
    }
}
