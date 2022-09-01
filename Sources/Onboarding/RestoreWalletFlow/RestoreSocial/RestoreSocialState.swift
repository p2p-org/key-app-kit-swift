// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public enum RestoreSocialResult: Codable, Equatable {
    case successful(
        seedPhrase: String,
        ethPublicKey: String
    )
    case start
    case requireCustom(result: RestoreSocialData?)
}

public enum RestoreSocialEvent {
    case signInDevice(socialProvider: SocialProvider)
    case signInCustom(socialProvider: SocialProvider)
    case back
    case start
    case requireCustom
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
    case notFoundDevice(data: RestoreSocialData, code: Int, deviceShare: String)
    case notFoundCustom(result: RestoreWalletResult, email: String)
    case expiredSocialTryAgain(result: RestoreWalletResult, provider: SocialProvider, email: String)
    case finish(RestoreSocialResult)

    public static var initialState: RestoreSocialState = .signIn(deviceShare: "")

    public func accept(currentState: RestoreSocialState, event: RestoreSocialEvent, provider: RestoreSocialContainer) async throws -> RestoreSocialState {
        switch currentState {
        case let .signIn(deviceShare):
            switch event {
            case let .signInDevice(socialProvider):
                return try await handleSignInDevice(deviceShare: deviceShare, socialProvider: socialProvider, provider: provider)
            default:
                throw StateMachineError.invalidEvent
            }

        case .social(let result):
            switch event {
            case let .signInCustom(socialProvider):
                return try await handleSignInCustom(result: result, socialProvider: socialProvider, provider: provider)

            case .back:
                throw StateMachineError.invalidEvent

            default:
                throw StateMachineError.invalidEvent

            }

        case let .notFoundCustom(result, email):
            switch event {
            case .signInCustom(let socialProvider):
                return try await handleSignInCustom(result: result, socialProvider: socialProvider, provider: provider)

            case .start:
                return .finish(.start)
            default:
                throw StateMachineError.invalidEvent
            }

        case let .notFoundDevice(data, code, deviceShare):
            switch event {
            case .signInDevice(let socialProvider):
                return try await handleSignInDevice(deviceShare: deviceShare, socialProvider: socialProvider, provider: provider)
            case .start:
                return .finish(.start)
            case .requireCustom:
                return .finish(.requireCustom(result: data))
            default:
                throw StateMachineError.invalidEvent
            }

        case let .expiredSocialTryAgain(result, socialProvider, email):
            do {
                return try await handleSignInCustom(result: result, socialProvider: socialProvider, provider: provider)
            }
            catch {
                if case let .first(share) = provider.option {
                    do {
                        return try await handleSignInDevice(deviceShare: share, socialProvider: socialProvider, provider: provider)
                    }
                    catch {
                        return .notFoundCustom(result: result, email: email)
                    }
                }
                else {
                    return .notFoundCustom(result: result, email: email)
                }
            }

        case .finish:
            throw StateMachineError.invalidEvent
        }
    }
}

private extension RestoreSocialState {
    func handleSignInDevice(deviceShare: String, socialProvider: SocialProvider, provider: RestoreSocialContainer) async throws -> RestoreSocialState {
        let (value, email) = try await provider.authService.auth(type: socialProvider)
        let tokenID = TokenID(value: value, provider: socialProvider.rawValue)
        do {
            let result = try await provider.tKeyFacade.signIn(
                tokenID: tokenID,
                deviceShare: deviceShare
            )
            return .finish(.successful(seedPhrase: result.privateSOL, ethPublicKey: result.reconstructedETH))
        }
        catch let error as TKeyFacadeError {
            switch error.code {
            case 1009, 1019:
                return .notFoundDevice(
                    data: RestoreSocialData(tokenID: tokenID, email: email),
                    code: error.code,
                    deviceShare: deviceShare
                )
            default:
                throw error
            }
        }
        catch {
            throw error
        }
    }

    func handleSignInCustom(result: RestoreWalletResult, socialProvider: SocialProvider, provider: RestoreSocialContainer) async throws -> RestoreSocialState {
        let (tokenID, email) = try await provider.authService.auth(type: socialProvider)
        do {
            let result = try await provider.tKeyFacade.signIn(
                tokenID: TokenID(value: tokenID, provider: socialProvider.rawValue),
                customShare: result.encryptedShare
            )
            return .finish(.successful(seedPhrase: result.privateSOL, ethPublicKey: result.reconstructedETH))
        }
        catch let error as TKeyFacadeError {
            return .notFoundCustom(result: result, email: email)
        }
        catch {
            throw error
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
        case .notFoundCustom:
            return 3
        case .notFoundDevice:
            return 4
        case .expiredSocialTryAgain:
            return 5
        case .finish:
            return 6
        }
    }
}
