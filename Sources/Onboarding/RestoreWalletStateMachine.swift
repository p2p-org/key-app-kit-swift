// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public typealias RestoreWalletStateMachine = StateMachine<RestoreWalletState>

public struct RestoreWalletFlowContainer {
    let tKeyFacade: TKeyFacade
    let deviceShare: String?
    let authService: SocialAuthService
    let apiGatewayClient: APIGatewayClient
    let securityStatusProvider: SecurityStatusProvider

    public init(
        tKeyFacade: TKeyFacade,
        deviceShare: String?,
        authService: SocialAuthService,
        apiGatewayClient: APIGatewayClient,
        securityStatusProvider: SecurityStatusProvider
    ) {
        self.tKeyFacade = tKeyFacade
        self.deviceShare = deviceShare
        self.authService = authService
        self.apiGatewayClient = apiGatewayClient
        self.securityStatusProvider = securityStatusProvider
    }
}

public enum RestoreWalletState: Codable, State, Equatable {
    public typealias Event = RestoreWalletEvent
    public typealias Provider = RestoreWalletFlowContainer
    public static var initialState: RestoreWalletState = .restore

    public static func createInitialState(provider: Provider) async -> RestoreWalletState {
        RestoreWalletState.initialState = .restore
        return RestoreWalletState.initialState
    }

    public func accept(
        currentState: RestoreWalletState,
        event: RestoreWalletEvent,
        provider: Provider
    ) async throws -> RestoreWalletState {
        switch currentState {
        case .restore:

            switch event {
            case .signInWithKeychain:
                return .signInKeychain

            case .signInWithSeed:
                return .signInSeed

            case let .signIn(socialProvider, deviceShare):
                let (tokenID, _) = try await provider.authService.auth(type: socialProvider)
                let result = try await provider.tKeyFacade.signIn(tokenID: TokenID(value: tokenID, provider: socialProvider.rawValue), deviceShare: deviceShare)
                return .restoredData(solPrivateKey: result.privateSOL, ethPublicKey: result.reconstructedETH)

            case .enterPhone:
                return .enterPhone

            default:
                throw StateMachineError.invalidEvent
            }
            
        case .enterPhone:
            switch event {
            case .enterPhoneNumber(let phoneNumber):
                try await provider.apiGatewayClient.restoreWallet(solPrivateKey: Data(), phone: phoneNumber, channel: .sms, timestampDevice: Date())

                return .enterOTP(phoneNumber: phoneNumber)

            default:
                throw StateMachineError.invalidEvent
            }
            
        case .enterOTP(let phoneNumber):
            switch event {
            case let .enterOTP(otp):
                let result = try await provider.apiGatewayClient.confirmRestoreWallet(solanaPrivateKey: Data(), phone: phoneNumber, otpCode: otp, timestampDevice: Date())

                return .social(result: result)
            case .resendOTP:
                return currentState
            default:
                throw StateMachineError.invalidEvent
            }

        case let .social(result):
            switch event {
            case let .signIn(socialProvider, customShare):
                let (tokenID, _) = try await provider.authService.auth(type: socialProvider)
                let result = try await provider.tKeyFacade.signIn(tokenID: TokenID(value: tokenID, provider: socialProvider.rawValue), customShare: result.encryptedShare)
                return .restoredData(solPrivateKey: result.privateSOL, ethPublicKey: result.reconstructedETH)

            default:
                throw StateMachineError.invalidEvent
            }

        case let .restoredData(solPrivateKey, ethPublicKey):
            let initial = await SecuritySetupState.createInitialState(provider: provider.securityStatusProvider)

            return .securitySetup(email: "", solPrivateKey: solPrivateKey, ethPublicKey: ethPublicKey, deviceShare: provider.deviceShare ?? "", initial)

        case let .securitySetup(email, solPrivateKey, ethPublicKey, deviceShare, innerState):
            switch event {
            case let .securitySetup(event):
                let nextInnerState = try await innerState <- (event, provider.securityStatusProvider)

                if case let .finish(result) = nextInnerState {
                    switch result {
                    case let .success(_, _):
                        return .restoredData(solPrivateKey: solPrivateKey, ethPublicKey: ethPublicKey)
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
            throw StateMachineError.invalidEvent

        case .signInSeed:
            throw StateMachineError.invalidEvent
        }
    }

    case restore

    case signInKeychain
    case signInSeed

    case enterPhone
    case enterOTP(phoneNumber: String)

    case social(result: RestoreWalletResult)

    case securitySetup(email: String, solPrivateKey: String, ethPublicKey: String, deviceShare: String, SecuritySetupState)

    case restoredData(solPrivateKey: String, ethPublicKey: String)
}

public enum RestoreWalletEvent {
    case signInWithKeychain

    case signInWithSeed

    case signIn(socialProvider: SocialProvider, deviceShare: String)
    case signIn(socialProvider: SocialProvider, customShare: String)

    case enterPhone
    case enterPhoneNumber(phoneNumber: String)
    case enterOTP(opt: String)
    case resendOTP

    case securitySetup(SecuritySetupEvent)

}
