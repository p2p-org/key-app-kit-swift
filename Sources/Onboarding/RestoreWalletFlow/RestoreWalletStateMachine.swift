// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift
import TweetNacl

public enum RestoreWalletFlowResult: Codable, Equatable {
    case successful(OnboardingWallet)
    case needHelp
    case breakProcess
}

public typealias RestoreWalletStateMachine = StateMachine<RestoreWalletState>

public struct RestoreWalletFlowContainer {
    let tKeyFacade: TKeyFacade
    let deviceShare: String?
    let authService: SocialAuthService
    let apiGatewayClient: APIGatewayClient
    let icloudAccountProvider: ICloudAccountProvider

    public init(
        tKeyFacade: TKeyFacade,
        deviceShare: String?,
        authService: SocialAuthService,
        apiGatewayClient: APIGatewayClient,
        icloudAccountProvider: ICloudAccountProvider
    ) {
        self.tKeyFacade = tKeyFacade
        self.deviceShare = deviceShare
        self.authService = authService
        self.apiGatewayClient = apiGatewayClient
        self.icloudAccountProvider = icloudAccountProvider
    }
}

public enum RestoreWalletState: Codable, State, Equatable {
    public typealias Event = RestoreWalletEvent
    public typealias Provider = RestoreWalletFlowContainer
    public static var initialState: RestoreWalletState = .restore

    case restore

    case restoreICloud(RestoreICloudState)
    case restoreSeed(RestoreSeedState)
    case restoreSocial(RestoreSocialState, option: RestoreSocialContainer.Option)
    case restoreCustom(RestoreCustomState)

    case securitySetup(
        solPrivateKey: String,
        ethPublicKey: String,
        deviceShare: String,
        SecuritySetupState
    )

    case finished(RestoreWalletFlowResult)

    public func accept(
        currentState: RestoreWalletState,
        event: RestoreWalletEvent,
        provider: Provider
    ) async throws -> RestoreWalletState {
        switch currentState {
        case .restore:

            switch event {
            case let .restoreICloud(event):
                switch event {
                case .signIn:
                    let nextInnerState = try await RestoreICloudState.signIn <- (
                        RestoreICloudEvent.signIn,
                        .init(icloudAccountProvider: provider.icloudAccountProvider)
                    )

                    if case let .chooseWallet(accounts) = nextInnerState {
                        return .restoreICloud(.chooseWallet(accounts: accounts))
                    } else {
                        return .restoreICloud(.signIn)
                    }
                default:
                    throw StateMachineError.invalidEvent
                }

            case let .restoreSeed(event):
                switch event {
                case .signInWithSeed:
                    return .restoreSeed(.signInSeed)
                default:
                    throw StateMachineError.invalidEvent
                }

            case let .restoreCustom(event):
                switch event {
                case .enterPhone:
                    return .restoreCustom(.enterPhone(phone: nil, social: nil))
                default:
                    throw StateMachineError.invalidEvent
                }

            case let .restoreSocial(event):
                switch event {
                case let .signInDevice(socialProvider):
                    return try await handleSignInDeviceEvent(provider: provider, socialProvider: socialProvider, event: event)

                default:
                    throw StateMachineError.invalidEvent
                }

            case .back:
                return .finished(.breakProcess)

            case .start:
                return .finished(.breakProcess)

            default:
                throw StateMachineError.invalidEvent
            }

        case let .restoreSocial(innerState, option):
            switch event {
            case let .restoreSocial(event):
                let nextInnerState = try await innerState <- (
                    event,
                    .init(option: option, tKeyFacade: provider.tKeyFacade, authService: provider.authService)
                )

                if case let .finish(result) = nextInnerState {
                    return try await handleRestoreSocial(provider: provider, result: result)
                } else {
                    return .restoreSocial(nextInnerState, option: option)
                }
            default:
                throw StateMachineError.invalidEvent
            }

        case let .restoreCustom(innerState):
            switch event {
            case let .restoreCustom(event):
                let nextInnerState = try await innerState <- (
                    event,
                    .init(
                        tKeyFacade: provider.tKeyFacade,
                        apiGatewayClient: provider.apiGatewayClient,
                        authService: provider.authService,
                        deviceShare: provider.deviceShare
                    )
                )

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case let .successful(solPrivateKey, ethPublicKey):
                        return .securitySetup(solPrivateKey: solPrivateKey, ethPublicKey: ethPublicKey, deviceShare: "", SecuritySetupState.initialState)
                    case let .requireSocialCustom(result):
                        return .restoreSocial(.social(result: result), option: .second(result: result))
                    case let .requireSocialDevice(socialProvider):
                        return try await handleSignInDeviceEvent(provider: provider, socialProvider: socialProvider, event: .signInDevice(socialProvider: socialProvider))
                    case .help:
                        return .finished(.needHelp)
                    case .start:
                        return .finished(.breakProcess)
                    case let .expiredSocialTryAgain(result, socialProvider, email):
                        let event = RestoreSocialEvent.signInCustom(socialProvider: socialProvider)
                        let innerState = RestoreSocialState.expiredSocialTryAgain(result: result, provider: socialProvider, email: email)
                        let nextInnerState = try await innerState <- (
                            event,
                            .init(option: .second(result: result), tKeyFacade: provider.tKeyFacade, authService: provider.authService)
                        )

                        if case let .finish(result) = nextInnerState {
                            return try await handleRestoreSocial(provider: provider, result: result)
                        } else {
                            return .restoreSocial(nextInnerState, option: .second(result: result))
                        }
                    }
                } else {
                    return .restoreCustom(nextInnerState)
                }

            default:
                throw StateMachineError.invalidEvent
            }

        case let .restoreSeed(innerState):
            switch event {
            case let .restoreSeed(event):
                let nextInnerState = try await innerState <- (
                    event,
                    .init()
                )

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case let .successful(phrase, path):
                        let account = try await Account(
                            phrase: phrase,
                            network: .mainnetBeta,
                            derivablePath: path
                        )
                        return .securitySetup(
                            solPrivateKey: phrase.joined(separator: " "),
                            ethPublicKey: "",
                            deviceShare: "",
                            SecuritySetupState.initialState
                        )
                    case .back:
                        return .restore
                    }
                } else {
                    return .restoreSeed(nextInnerState)
                }

            default:
                throw StateMachineError.invalidEvent
            }

        case let .restoreICloud(innerState):
            switch event {
            case let .restoreICloud(event):
                let nextInnerState = try await innerState <- (
                    event,
                    .init(icloudAccountProvider: provider.icloudAccountProvider)
                )

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case let .successful(account):
                        return .securitySetup(
                            solPrivateKey: account.phrase.joined(separator: " "),
                            ethPublicKey: "",
                            deviceShare: "",
                            SecuritySetupState.initialState
                        )
                    case .back:
                        return .restore
                    }
                }
                else {
                    return .restoreICloud(nextInnerState)
                }

            default:
                throw StateMachineError.invalidEvent
            }

        case let .securitySetup(solPrivateKey, ethPublicKey, deviceShare, innerState):
            switch event {
            case let .securitySetup(event):
                let nextInnerState = try await innerState <- (event, .init())

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case let .success(pincode, isBiometryEnabled):
                        return .finished(.successful(
                            OnboardingWallet(
                                solPrivateKey: solPrivateKey,
                                deviceShare: deviceShare,
                                pincode: pincode,
                                isBiometryEnabled: isBiometryEnabled
                            )))
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

        case .finished:
            throw StateMachineError.invalidEvent
        }
    }

    private func handleRestoreSocial(provider: RestoreWalletFlowContainer, result: RestoreSocialResult) async throws -> RestoreWalletState {
        switch result {
        case let .successful(solPrivateKey, ethPublicKey):
            return .securitySetup(solPrivateKey: solPrivateKey, ethPublicKey: ethPublicKey, deviceShare: "", SecuritySetupState.initialState)
        case .start:
            return .finished(.breakProcess)
        case let .requireCustom(data):
            return .restoreCustom(.enterPhone(phone: nil, social: data))
        }
    }

    private func handleSignInDeviceEvent(provider: RestoreWalletFlowContainer, socialProvider: SocialProvider, event: RestoreSocialEvent) async throws -> RestoreWalletState {
        guard let deviceShare = provider.deviceShare else { throw StateMachineError.invalidEvent }
        let event = RestoreSocialEvent.signInDevice(socialProvider: socialProvider)
        let innerState = RestoreSocialState.signIn(deviceShare: deviceShare)
        let nextInnerState = try await innerState <- (
            event,
            .init(option: .first(deviceShare: deviceShare), tKeyFacade: provider.tKeyFacade, authService: provider.authService)
        )

        if case let .finish(result) = nextInnerState {
            return try await handleRestoreSocial(provider: provider, result: result)
        } else {
            return .restoreSocial(nextInnerState, option: .first(deviceShare: deviceShare))
        }
    }
}

public enum RestoreWalletEvent {
    case back
    case start
    case help

    case restoreSocial(RestoreSocialEvent)
    case restoreCustom(RestoreCustomEvent)
    case restoreSeed(RestoreSeedEvent)
    case restoreICloud(RestoreICloudEvent)
    case securitySetup(SecuritySetupEvent)
}

extension RestoreWalletState: Step, Continuable {
    public var continuable: Bool {
        switch self {
        case .restore:
            return false
        case let .restoreSeed(restoreSeedState):
            return restoreSeedState.continuable
        case let .restoreSocial(restoreSocialState, _):
            return restoreSocialState.continuable
        case let .restoreCustom(restoreCustomState):
            return restoreCustomState.continuable
        case let .restoreICloud(restoreICloudState):
            return restoreICloudState.continuable
        case let .securitySetup(_, _, _, securitySetupState):
            return securitySetupState.continuable
        case .finished:
            return false
        }
    }

    public var step: Float {
        switch self {
        case .restore:
            return 1 * 100
        case let .restoreICloud(restoreICloudState):
            return 3 * 100 + restoreICloudState.step
        case let .restoreSeed(restoreSeedState):
            return 4 * 100 + restoreSeedState.step
        case let .restoreSocial(restoreSocialState, _):
            return 5 * 100 + restoreSocialState.step
        case let .restoreCustom(restoreCustomState):
            return 6 * 100 + restoreCustomState.step
        case let .securitySetup(_, _, _, securitySetupState):
            return 7 * 100 + securitySetupState.step
        case .finished:
            return 8 * 100
        }
    }
}
