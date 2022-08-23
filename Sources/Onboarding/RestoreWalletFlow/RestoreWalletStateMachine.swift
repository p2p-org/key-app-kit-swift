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
    let securityStatusProvider: SecurityStatusProvider
    let icloudAccountProvider: ICloudAccountProvider

    public init(
        tKeyFacade: TKeyFacade,
        deviceShare: String?,
        authService: SocialAuthService,
        apiGatewayClient: APIGatewayClient,
        securityStatusProvider: SecurityStatusProvider,
        icloudAccountProvider: ICloudAccountProvider
    ) {
        self.tKeyFacade = tKeyFacade
        self.deviceShare = deviceShare
        self.authService = authService
        self.apiGatewayClient = apiGatewayClient
        self.securityStatusProvider = securityStatusProvider
        self.icloudAccountProvider = icloudAccountProvider
    }
}

public enum RestoreWalletState: Codable, State, Equatable {
    public typealias Event = RestoreWalletEvent
    public typealias Provider = RestoreWalletFlowContainer
    public static var initialState: RestoreWalletState = .restore

    public static func createInitialState(provider _: Provider) async -> RestoreWalletState {
        RestoreWalletState.initialState = .restore
        return RestoreWalletState.initialState
    }

    case restore
    case restoreNotFoundDevice(tokenID: TokenID, email: String?)
    case restoreNotFoundCustom(result: RestoreWalletResult, email: String)
    
    case signInKeychain(accounts: [ICloudAccount])
    case signInSeed

    case restoreSocial(RestoreSocialState, option: RestoreSocialContainer.Option)
    case restoreCustom(RestoreCustomState)

    case noMatch

    case securitySetup(
        email: String,
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
            case .signInWithKeychain:
                let rawAccounts = try await provider.icloudAccountProvider.getAll()
                var accounts: [ICloudAccount] = []
                for rawAccount in rawAccounts {
                    accounts
                        .append(try await .init(
                            name: rawAccount.name,
                            phrase: rawAccount.phrase,
                            derivablePath: rawAccount.derivablePath
                        ))
                }
                return .signInKeychain(accounts: accounts)

            case .signInWithSeed:
                return .signInSeed

            case let .restoreCustom(event):
                switch event {
                case .enterPhone:
                    return .restoreCustom(.enterPhone(tokenID: nil))
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

        case let .restoreNotFoundDevice(tokenID, email):
            switch event {

            case let .restoreCustom(event):
                switch event {
                case .enterPhone:
                    return .restoreCustom(.enterPhone(tokenID: tokenID))
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

            case .start:
                return .finished(.breakProcess)

            default:
                throw StateMachineError.invalidEvent
            }
            
        case let .restoreNotFoundCustom(result, email):
            switch event {

            case let .restoreSocial(event):
                let innerState = RestoreSocialState.social(result: result)
                switch event {
                case let .signInCustom(socialProvider):
                    let nextInnerState = try await innerState <- (
                        event,
                        .init(option: .second(result: result), tKeyFacade: provider.tKeyFacade, authService: provider.authService)
                    )

                    if case let .finish(result) = nextInnerState {
                        return try await handleRestoreSocial(provider: provider, result: result)
                    } else {
                        return .restoreNotFoundCustom(result: result, email: email)
                    }

                default:
                    throw StateMachineError.invalidEvent
                }

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
                    .init(tKeyFacade: provider.tKeyFacade, apiGatewayClient: provider.apiGatewayClient, deviceShare: provider.deviceShare)
                )

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case let .successful(solPrivateKey, ethPublicKey):
                        let initial = await SecuritySetupState.createInitialState(provider: provider.securityStatusProvider)
                        return .securitySetup(email: "", solPrivateKey: solPrivateKey, ethPublicKey: ethPublicKey, deviceShare: "", initial)
                    case let .requireSocial(result):
                        return .restoreSocial(.social(result: result), option: .second(result: result))
                    case .noMatch:
                        return .noMatch
                    }
                } else {
                    return .restoreCustom(nextInnerState)
                }

            default:
                throw StateMachineError.invalidEvent
            }

        case let .securitySetup(email, solPrivateKey, ethPublicKey, deviceShare, innerState):
            switch event {
            case let .securitySetup(event):
                let nextInnerState = try await innerState <- (event, provider.securityStatusProvider)

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case let .success(pincode, withBiometric):
                        return .finished(.successful(OnboardingWallet(
                            solPrivateKey: solPrivateKey,
                            deviceShare: deviceShare,
                            pincode: pincode ?? "000000",
                            useBiometric: withBiometric)
                        ))
                    }
                } else {
                    return .securitySetup(
                        email: email,
                        solPrivateKey: solPrivateKey,
                        ethPublicKey: ethPublicKey,
                        deviceShare: deviceShare,
                        nextInnerState
                    )
                }
            default:
                throw StateMachineError.invalidEvent
            }

        case .signInKeychain:
            switch event {
            case let .restoreICloudAccount(account):
                let account = try await Account(
                    phrase: account.phrase.components(separatedBy: " "),
                    network: .mainnetBeta,
                    derivablePath: account.derivablePath
                )
                return .securitySetup(
                    email: "",
                    solPrivateKey: Base58.encode(account.secretKey),
                    ethPublicKey: "",
                    deviceShare: "",
                    await SecuritySetupState.createInitialState(provider: provider.securityStatusProvider)
                )
            case let .back:
                return .restore
            default:
                throw StateMachineError.invalidEvent
            }

        case .signInSeed:
            throw StateMachineError.invalidEvent

        case .noMatch:
            switch event {
            case .start:
                return .finished(.breakProcess)
            case .help:
                return .finished(.needHelp)
            default:
                throw StateMachineError.invalidEvent
            }

        case let .finished(result):
            throw StateMachineError.invalidEvent
        }
    }

    private func handleRestoreSocial(provider: RestoreWalletFlowContainer, result: RestoreSocialResult) async throws -> RestoreWalletState {
        switch result {
        case let .successful(solPrivateKey, ethPublicKey):
            let initial = await SecuritySetupState.createInitialState(provider: provider.securityStatusProvider)
            return .securitySetup(email: "", solPrivateKey: solPrivateKey, ethPublicKey: ethPublicKey, deviceShare: "", initial)
        case let .notFoundDevice(tokenID, email):
            return .restoreNotFoundDevice(tokenID: tokenID, email: email)
        case let .notFoundCustom(result, email):
            return .restoreNotFoundCustom(result: result, email: email)
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

    // Icloud flow
    case signInWithKeychain
    case restoreICloudAccount(account: ICloudAccount)

    case signInWithSeed

    case restoreSocial(RestoreSocialEvent)
    case restoreCustom(RestoreCustomEvent)

    case securitySetup(SecuritySetupEvent)
}

extension RestoreWalletState: Step, Continuable {
    public var continuable: Bool {
        switch self {
        case .restore:
            return false
        case .restoreNotFoundDevice:
            return false
        case .restoreNotFoundCustom:
            return false
        case .signInKeychain:
            return false
        case .signInSeed:
            return false
        case let .restoreSocial(restoreSocialState, _):
            return restoreSocialState.continuable
        case let .restoreCustom(restoreCustomState):
            return restoreCustomState.continuable
        case let .securitySetup(_, _, _, _, securitySetupState):
            return securitySetupState.continuable
        case .finished:
            return false
        case .noMatch:
            return false
        }
    }

    public var step: Float {
        switch self {
        case .restore:
            return 1 * 100
        case .restoreNotFoundDevice:
            return 2 * 100
        case .restoreNotFoundCustom:
            return 3 * 100
        case .signInKeychain:
            return 4 * 100
        case .signInSeed:
            return 5 * 100
        case let .restoreSocial(restoreSocialState, _):
            return 6 * 100 + restoreSocialState.step
        case let .restoreCustom(restoreCustomState):
            return 7 * 100 + restoreCustomState.step
        case let .securitySetup(_, _, _, _, securitySetupState):
            return 8 * 100 + securitySetupState.step
        case .noMatch:
            return 9 * 100
        case .finished:
            return 10 * 100
        }
    }
}

