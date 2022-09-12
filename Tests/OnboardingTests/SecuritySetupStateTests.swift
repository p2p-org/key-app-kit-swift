//
// Created by Tran Hai Bac on 12.09.2022.
//

import XCTest
@testable import Onboarding

class SecuritySetupTests: XCTestCase {
    func testBindingPhoneNumber() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .securitySetup(email: "", wallet: .init(seedPhrase: ""), ethPublicKey: "", deviceShare: "", .confirmPincode(pincode: "0000")), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))

        var nextState = try await stateMachine.accept(event: .securitySetup(.setPincode(pincode: "", isBiometryEnabled: false)))
        print("Current state: \(stateMachine.currentState)")
    }

    func testBindingPhoneNumber2() async throws {
        let stateMachine = CreateWalletStateMachine(initialState: .securitySetup(email: "", wallet: .init(seedPhrase: ""), ethPublicKey: "", deviceShare: "", .initialState), provider: CreateWalletFlowContainer.init(authService: SocialAuthServiceMock(), apiGatewayClient: APIGatewayClientImplMock(), tKeyFacade: TKeyMockupFacade()))
        do{
            var nextState = try await stateMachine.accept(event: .securitySetup(.createPincode))
            print("Current state: \(stateMachine.currentState)")
            XCTFail()
        } catch {

        }

    }
}