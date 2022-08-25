// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public enum RestoreSocialResult: Codable, Equatable {
    case successful(
        solPrivateKey: String,
        ethPublicKey: String
    )
    case notFoundDevice(tokenID: TokenID, email: String?)
    case notFoundCustom(result: RestoreWalletResult, email: String)
}

public enum RestoreSocialEvent {
    case signInDevice(socialProvider: SocialProvider)
    case signInCustom(socialProvider: SocialProvider)
    case back
}

public struct RestoreSocialContainer {
    public enum Option: Equatable, Codable {
        case first(deviceShare: String)
        case second(result: RestoreWalletResult)
    }

    let option: Option
    let tKeyFacade: TKeyFacade
    let authService: SocialAuthService
}

public enum RestoreSocialState: Codable, State, Equatable {
    public typealias Event = RestoreSocialEvent
    public typealias Provider = RestoreSocialContainer

    case signIn(deviceShare: String)
    case social(result: RestoreWalletResult)
    case finish(RestoreSocialResult)

    public static var initialState: RestoreSocialState = .signIn(deviceShare: "")

    public static func createInitialState(provider: RestoreSocialContainer) async -> RestoreSocialState {
        switch provider.option {
        case let .first(deviceShare):
            RestoreSocialState.initialState = .signIn(deviceShare: deviceShare)
        case let .second(result):
            RestoreSocialState.initialState = .social(result: result)
        }
        return RestoreSocialState.initialState
    }

    public func accept(currentState: RestoreSocialState, event: RestoreSocialEvent, provider: RestoreSocialContainer) async throws -> RestoreSocialState {
        switch currentState {
        case let .signIn(deviceShare):
            switch event {
            case let .signInDevice(socialProvider):
                let (value, email) = try await provider.authService.auth(type: socialProvider)
                let tokenID = TokenID(value: value, provider: socialProvider.rawValue)
                do {
                    let result = try await provider.tKeyFacade.signIn(
                        tokenID: tokenID,
                        deviceShare: deviceShare
                    )
                    return .finish(.successful(solPrivateKey: result.privateSOL, ethPublicKey: result.reconstructedETH))
                }
                catch let error as TKeyFacadeError {
                    switch error.code {
                    case 0:
                        return .finish(.notFoundDevice(tokenID: tokenID, email: nil))
                    case 1:
                        return .finish(.notFoundDevice(tokenID: tokenID, email: email))
                    default:
                        throw error
                    }
                }
            default:
                throw StateMachineError.invalidEvent
            }

        case .social(let result):
            switch event {
            case let .signInCustom(socialProvider):
                let (tokenID, email) = try await provider.authService.auth(type: socialProvider)
                do {
                    let result = try await provider.tKeyFacade.signIn(
                        tokenID: TokenID(value: tokenID, provider: socialProvider.rawValue),
                        customShare: result.encryptedShare
                    )
                    return .finish(.successful(solPrivateKey: result.privateSOL, ethPublicKey: result.reconstructedETH))
                }
                catch {
                    return .finish(.notFoundCustom(result: result, email: email))
                }

            case .back:
                throw StateMachineError.invalidEvent

            default:
                throw StateMachineError.invalidEvent

            }

        case .finish:
            throw StateMachineError.invalidEvent
        }
    }
}

extension RestoreSocialState: Step, Continuable {
    public var continuable: Bool { false }

    public var step: Float {
        switch self {
        case .signIn:
            return 1
        case .social:
            return 2
        case .finish:
            return 3
        }
    }
}
