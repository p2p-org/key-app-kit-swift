// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public enum RestoreSocialResult: Codable, Equatable {
    case successful(
        solPrivateKey: String,
        ethPublicKey: String
    )
}

public enum RestoreSocialEvent {
    case signInDevice(socialProvider: SocialProvider)
    case signInCustom(socialProvider: SocialProvider)
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
                let (tokenID, _) = try await provider.authService.auth(type: socialProvider)
                let result = try await provider.tKeyFacade.signIn(
                    tokenID: TokenID(value: tokenID, provider: socialProvider.rawValue),
                    deviceShare: deviceShare
                )
                return .finish(.successful(solPrivateKey: result.privateSOL, ethPublicKey: result.reconstructedETH))
            case .signInCustom:
                throw StateMachineError.invalidEvent
            }

        case .social(let result):
            switch event {
            case .signInDevice:
                throw StateMachineError.invalidEvent

            case let .signInCustom(socialProvider):
                let (tokenID, _) = try await provider.authService.auth(type: socialProvider)
                let result = try await provider.tKeyFacade.signIn(
                    tokenID: TokenID(value: tokenID, provider: socialProvider.rawValue),
                    customShare: result.encryptedShare
                )
                return .finish(.successful(solPrivateKey: result.privateSOL, ethPublicKey: result.reconstructedETH))
            }
        case .finish(let restoreSocialResult):
            throw StateMachineError.invalidEvent
        }
    }
}

extension RestoreSocialState: Step, Continuable {
    public var continuable: Bool { false }

    public var step: Float {
        switch self {
        case .signIn(let deviceShare):
            return 1
        case .social(let result):
            return 2
        case .finish(let restoreSocialResult):
            return 3
        }
    }
}
