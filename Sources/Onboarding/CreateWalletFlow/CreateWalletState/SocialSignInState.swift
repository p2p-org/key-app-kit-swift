// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public enum SocialProvider: String, Codable {
    case apple
    case google
}

public enum SocialSignInResult: Codable, Equatable {
    case successful(solPrivateKey: String, ethPublicKey: String, deviceShare: String)
    case breakProcess
    case switchToRestoreFlow(authProvider: SocialProvider, email: String)
}

public enum SocialSignInEvent {
    case signIn(socialProvider: SocialProvider)
    case signInBack
    case restore(authProvider: SocialProvider, email: String)
}

public protocol SocialAuthService {
    func auth(type: SocialProvider) async throws -> (tokenID: String, email: String)
}

public struct SocialSignInContainer {
    let tKeyFacade: TKeyFacade
    let authService: SocialAuthService
}

public enum SocialSignInState: Codable, State, Equatable {
    public typealias Event = SocialSignInEvent
    public typealias Provider = SocialSignInContainer

    case socialSelection
    case socialSignInAccountWasUsed(signInProvider: SocialProvider, usedEmail: String)
    case socialSignInTryAgain(signInProvider: SocialProvider, usedEmail: String)
    case finish(SocialSignInResult)

    public static var initialState: SocialSignInState = .socialSelection

    public func accept(
        currentState: SocialSignInState,
        event: SocialSignInEvent,
        provider: SocialSignInContainer
    ) async throws -> SocialSignInState {
        switch currentState {
        case .socialSelection:
            return try await socialSelectionEventHandler(currentState: currentState, event: event, provider: provider)
        case .socialSignInAccountWasUsed:
            return try await socialSignInAccountWasUsedHandler(
                currentState: currentState,
                event: event,
                provider: provider
            )
        case .socialSignInTryAgain:
            return try await socialTryAgainEventHandler(currentState: currentState, event: event, provider: provider)
        case .finish:
            throw StateMachineError.invalidEvent
        }
    }

    internal func socialSelectionEventHandler(
        currentState _: Self, event: Event,
        provider: Provider
    ) async throws -> Self {
        switch event {
        case let .signIn(socialProvider):
            let (tokenID, email) = try await provider.authService.auth(type: socialProvider)
            do {
                let result = try await provider.tKeyFacade
                    .signUp(tokenID: .init(value: tokenID, provider: socialProvider.rawValue))
                
                return .finish(
                    .successful(solPrivateKey: result.privateSOL,
                                ethPublicKey: result.reconstructedETH,
                                deviceShare: result.deviceShare)
                )
            } catch let error as TKeyFacadeError {
                switch error.code {
                case 1009:
                    return .socialSignInAccountWasUsed(signInProvider: socialProvider, usedEmail: email)
                case 1666:
                    return .socialSignInTryAgain(signInProvider: socialProvider, usedEmail: email)
                default:
                    throw error
                }
            }
        case .signInBack:
            return .finish(.breakProcess)
        default:
            throw StateMachineError.invalidEvent
        }
    }

    internal func socialTryAgainEventHandler(
        currentState _: Self, event: Event,
        provider: Provider
    ) async throws -> Self {
        switch event {
        case let .signIn(socialProvider):
            let (tokenID, email) = try await provider.authService.auth(type: socialProvider)
            do {
                let result = try await provider
                    .tKeyFacade
                    .signUp(tokenID: .init(value: tokenID, provider: socialProvider.rawValue))

                return .finish(
                    .successful(solPrivateKey: result.privateSOL,
                                ethPublicKey: result.reconstructedETH,
                                deviceShare: result.deviceShare)
                )
            } catch let error as TKeyFacadeError {
                switch error.code {
                case 1009:
                    return .socialSignInAccountWasUsed(signInProvider: socialProvider, usedEmail: email)
                default:
                    throw error
                }
            }
        case .signInBack:
            return .finish(.breakProcess)
        default:
            throw StateMachineError.invalidEvent
        }
    }

    internal func socialSignInAccountWasUsedHandler(
        currentState: Self, event: Event,
        provider: Provider
    ) async throws -> Self {
        switch event {
        case .signIn:
            return try await socialSelectionEventHandler(currentState: currentState, event: event, provider: provider)
        case let .restore(signInProvider, email):
            return .finish(.switchToRestoreFlow(authProvider: signInProvider, email: email))
        case .signInBack:
            return .socialSelection
        }
    }
}

extension SocialSignInState: Step {
    public var step: Float {
        switch self {
        case .socialSelection:
            return 1
        case .socialSignInAccountWasUsed:
            return 2
        case .socialSignInTryAgain:
            return 3
        case .finish:
            return 4
        }
    }
}
