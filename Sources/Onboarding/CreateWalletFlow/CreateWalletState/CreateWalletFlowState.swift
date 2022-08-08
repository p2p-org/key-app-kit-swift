// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public enum CreateWalletFlowResult: Codable, Equatable {
    case newWallet(
        solPrivateKey: String,
        ethPublicKey: String,
        deviceShare: String,
        phoneNumberShare: String,
        pincode: String
    )
    case breakProcess
    case switchToRestoreFlow(socialProvider: SocialProvider, email: String)
}

public enum CreateWalletFlowEvent {
    // Sign in step
    case socialSignInEvent(SocialSignInEvent)
    case bindingPhoneNumberEvent(BindingPhoneNumberEvent)
    case securitySetup(SecuritySetupEvent)
}

public struct CreateWalletFlowContainer {
    let authService: SocialAuthService
    let apiGatewayClient: APIGatewayClient
    let tKeyFacade: TKeyFacade

    public init(authService: SocialAuthService, apiGatewayClient: APIGatewayClient, tKeyFacade: TKeyFacade) {
        self.authService = authService
        self.apiGatewayClient = apiGatewayClient
        self.tKeyFacade = tKeyFacade
    }
}

public enum CreateWalletFlowState: Codable, State, Equatable {
    public typealias Event = CreateWalletFlowEvent
    public typealias Provider = CreateWalletFlowContainer

    public private(set) static var initialState: CreateWalletFlowState = .socialSignIn(.socialSelection)

    // States
    case socialSignIn(SocialSignInState)
    case bindingPhoneNumber(solPrivateKey: String, ethPublicKey: String, deviceShare: String, BindingPhoneNumberState)
    case securitySetup(solPrivateKey: String, ethPublicKey: String, deviceShare: String, SecuritySetupState)

    // Final state
    case finish(CreateWalletFlowResult)

    public func accept(
        currentState: CreateWalletFlowState,
        event: CreateWalletFlowEvent,
        provider: CreateWalletFlowContainer
    ) async throws -> CreateWalletFlowState {
        switch currentState {
        case let .socialSignIn(innerState):
            switch event {
            case let .socialSignInEvent(event):
                let nextInnerState = try await innerState <- (
                    event,
                    .init(tKeyFacade: provider.tKeyFacade, authService: provider.authService)
                )

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case let .successful(solPrivateKey, ethPublicKey, deviceShare):
                        return .bindingPhoneNumber(
                            solPrivateKey: solPrivateKey,
                            ethPublicKey: ethPublicKey,
                            deviceShare: deviceShare,
                            .enterPhoneNumber(
                                initialPhoneNumber: nil,
                                data: .init(
                                    solanaPublicKey: solPrivateKey,
                                    ethereumId: ethPublicKey,
                                    share: deviceShare,
                                    payload: ""
                                )
                            )
                        )
                    case .breakProcess:
                        return .finish(.breakProcess)
                    case let .switchToRestoreFlow(authProvider: authProvider, email: email):
                        return .finish(.switchToRestoreFlow(socialProvider: authProvider, email: email))
                    }
                } else {
                    return .socialSignIn(nextInnerState)
                }
            default:
                throw StateMachineError.invalidEvent
            }
        case let .bindingPhoneNumber(solPrivateKey, ethPublicKey, deviceShare, innerState):
            switch event {
            case let .bindingPhoneNumberEvent(event):
                let nextInnerState = try await innerState <- (event, provider.apiGatewayClient)

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case .success:
                        return .securitySetup(
                            solPrivateKey: solPrivateKey,
                            ethPublicKey: ethPublicKey,
                            deviceShare: deviceShare,
                            SecuritySetupState.initialState
                        )
                    }
                } else {
                    return .bindingPhoneNumber(
                        solPrivateKey: solPrivateKey,
                        ethPublicKey: ethPublicKey,
                        deviceShare: deviceShare,
                        nextInnerState
                    )
                }
            default:
                throw StateMachineError.invalidEvent
            }

        case let .securitySetup(solPrivateKey, ethPublicKey, deviceShare, innerState):
            switch event {
            case let .securitySetup(event):
                let nextInnerState = try await innerState <- (event, ())

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case .success:
                        return .securitySetup(
                            solPrivateKey: solPrivateKey,
                            ethPublicKey: ethPublicKey,
                            deviceShare: deviceShare,
                            SecuritySetupState.initialState
                        )
                    }
                } else {
                    return .securitySetup(
                        solPrivateKey: solPrivateKey,
                        ethPublicKey: ethPublicKey,
                        deviceShare: deviceShare,
                        nextInnerState
                    )
                }
            default:
                throw StateMachineError.invalidEvent
            }

        default: throw StateMachineError.invalidEvent
        }
    }
}

extension CreateWalletFlowState: Step {
    public var step: Float {
        switch self {
        case .socialSignIn:
            return 1
        case .bindingPhoneNumber:
            return 2
        case .securitySetup:
            return 3
        case .finish:
            return 4
        }
    }
}
