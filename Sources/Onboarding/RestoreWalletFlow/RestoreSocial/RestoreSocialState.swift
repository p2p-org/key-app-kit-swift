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
        case device(share: String)
        case customResult(result: RestoreWalletResult)
        case customDevice(share: String)
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
    case notFoundDevice(data: RestoreSocialData, deviceShare: String)
    case notFoundCustom(result: RestoreWalletResult, email: String)
    case notFoundSocial(data: RestoreSocialData, deviceShare: String)
    case expiredSocialTryAgain(result: RestoreWalletResult, provider: SocialProvider, email: String, deviceShare: String?)
    case finish(RestoreSocialResult)

    public static var initialState: RestoreSocialState = .signIn(deviceShare: "")

    public func accept(
        currentState: RestoreSocialState,
        event: RestoreSocialEvent,
        provider: RestoreSocialContainer
    ) async throws -> RestoreSocialState {
        switch currentState {
        case let .signIn(deviceShare):
            switch event {
            case let .signInDevice(socialProvider):
                return try await handleSignInDevice(
                    deviceShare: deviceShare,
                    socialProvider: socialProvider,
                    provider: provider
                )
            default:
                throw StateMachineError.invalidEvent
            }

        case let .social(result):
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
            case let .signInCustom(socialProvider):
                return try await handleSignInCustom(result: result, socialProvider: socialProvider, provider: provider)

            case .start:
                return .finish(.start)
            default:
                throw StateMachineError.invalidEvent
            }

        case let .notFoundDevice(data, deviceShare):
            switch event {
            case let .signInDevice(socialProvider):
                return try await handleSignInDevice(
                    deviceShare: deviceShare,
                    socialProvider: socialProvider,
                    provider: provider
                )
            case .start:
                return .finish(.start)
            case .requireCustom:
                return .finish(.requireCustom(result: data))
            default:
                throw StateMachineError.invalidEvent
            }

        case let .notFoundSocial(data, deviceShare):
            switch event {
            case let .signInDevice(socialProvider):
                return try await handleSignInDevice(
                    deviceShare: deviceShare,
                    socialProvider: socialProvider,
                    provider: provider
                )
            case .start:
                return .finish(.start)
            case .requireCustom:
                return .finish(.requireCustom(result: data))
            default:
                throw StateMachineError.invalidEvent
            }

        case let .expiredSocialTryAgain(result, socialProvider, email, deviceShare):
            do {
                return try await handleSignInCustom(result: result, socialProvider: socialProvider, provider: provider)
            }
            catch {
                if let deviceShare = deviceShare {
                    do {
                        return try await handleSignInDevice(
                            deviceShare: deviceShare,
                            socialProvider: socialProvider,
                            provider: provider
                        )
                    } catch {
                        return .notFoundCustom(result: result, email: email)
                    }
                } else {
                    return .notFoundCustom(result: result, email: email)
                }
            }

        case .finish:
            throw StateMachineError.invalidEvent
        }
    }
}

private extension RestoreSocialState {
    func handleSignInDevice(
        deviceShare: String,
        socialProvider: SocialProvider,
        provider: RestoreSocialContainer
    ) async throws -> RestoreSocialState {
        let (value, email) = try await provider.authService.auth(type: socialProvider)
        let tokenID = TokenID(value: value, provider: socialProvider.rawValue)
        do {
            try await provider.tKeyFacade.initialize()
            let result = try await provider.tKeyFacade.signIn(
                tokenID: tokenID,
                deviceShare: deviceShare
            )
            return .finish(.successful(seedPhrase: result.privateSOL, ethPublicKey: result.reconstructedETH))
        } catch let error as TKeyFacadeError {
            let data = RestoreSocialData(tokenID: tokenID, email: email)
            switch error.code {
            case 1009:
                return .notFoundDevice(data: data, deviceShare: deviceShare)
            case 1021:
                return .notFoundSocial(data: data, deviceShare: deviceShare)
            default:
                throw error
            }
        } catch {
            throw error
        }
    }

    func handleSignInCustom(
        result: RestoreWalletResult,
        socialProvider: SocialProvider,
        provider: RestoreSocialContainer
    ) async throws -> RestoreSocialState {
        let (tokenID, email) = try await provider.authService.auth(type: socialProvider)
        do {
            try await provider.tKeyFacade.initialize()
            let result = try await provider.tKeyFacade.signIn(
                tokenID: TokenID(value: tokenID, provider: socialProvider.rawValue),
                customShare: result.encryptedShare,
                encryptedMnemonic: result.encryptedPayload
            )
            return .finish(.successful(seedPhrase: result.privateSOL, ethPublicKey: result.reconstructedETH))
        } catch let _ as TKeyFacadeError {
            return .notFoundCustom(result: result, email: email)
        } catch {
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
        case .notFoundSocial:
            return 5
        case .expiredSocialTryAgain:
            return 6
        case .finish:
            return 7
        }
    }
}
