// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public enum CreateWalletFlowResult: Codable, Equatable {
    case newWallet(CreateWalletData)
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

    public init(
        authService: SocialAuthService,
        apiGatewayClient: APIGatewayClient,
        tKeyFacade: TKeyFacade
    ) {
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
    case bindingPhoneNumber(
        email: String,
        seedPhrase: String,
        ethPublicKey: String,
        deviceShare: String,
        BindingPhoneNumberState
    )
    case securitySetup(
        email: String,
        wallet: OnboardingWallet,
        ethPublicKey: String,
        deviceShare: String,
        SecuritySetupState
    )

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
                    case let .successful(email, seedPhrase, ethPublicKey, deviceShare, customShare, metaData):
                        return .bindingPhoneNumber(
                            email: email,
                            seedPhrase: seedPhrase,
                            ethPublicKey: ethPublicKey,
                            deviceShare: deviceShare,
                            .enterPhoneNumber(
                                initialPhoneNumber: nil,
                                didSend: false,
                                data: .init(
                                    seedPhrase: seedPhrase,
                                    ethereumId: ethPublicKey,
                                    customShare: customShare,
                                    payload: metaData
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
        case let .bindingPhoneNumber(email, seedPhrase, ethPublicKey, deviceShare, innerState):
            switch event {
            case let .bindingPhoneNumberEvent(event):
                let nextInnerState = try await innerState <- (event, provider.apiGatewayClient)

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case .success:
                        return .securitySetup(
                            email: email,
                            wallet: OnboardingWallet(seedPhrase: seedPhrase),
                            ethPublicKey: ethPublicKey,
                            deviceShare: deviceShare,
                            SecuritySetupState.initialState
                        )
                    case .breakProcess:
                        return .finish(.breakProcess)
                    }
                } else {
                    return .bindingPhoneNumber(
                        email: email,
                        seedPhrase: seedPhrase,
                        ethPublicKey: ethPublicKey,
                        deviceShare: deviceShare,
                        nextInnerState
                    )
                }
            default:
                throw StateMachineError.invalidEvent
            }

        case let .securitySetup(email, wallet, ethPublicKey, deviceShare, innerState):
            switch event {
            case let .securitySetup(event):
                let nextInnerState = try await innerState <- (event, .init())

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case let .success(securityData):
                        return .finish(
                            .newWallet(CreateWalletData(
                                deviceShare: deviceShare,
                                wallet: wallet,
                                security: securityData
                            ))
                        )
                    }
                } else {
                    return .securitySetup(
                        email: email,
                        wallet: wallet,
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

extension CreateWalletFlowState: Step, Continuable {
    public var continuable: Bool {
        switch self {
        case let .socialSignIn(innerState):
            return innerState.continuable
        case let .bindingPhoneNumber(_, _, _, _, innerState):
            return innerState.continuable
        case let .securitySetup(_, _, _, _, innerState):
            return innerState.continuable
        case .finish:
            return false
        }
    }

    public var step: Float {
        switch self {
        case let .socialSignIn(innerState):
            return 1 * 100 + innerState.step
        case let .bindingPhoneNumber(_, _, _, _, innerState):
            return 2 * 100 + innerState.step
        case let .securitySetup(_, _, _, _, innerState):
            return 3 * 100 + innerState.step
        case .finish:
            return 4 * 100
        }
    }
}
