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
        case device
        case custom
        case customDevice
    }

    let option: Option
    let tKeyFacade: TKeyFacade
    let authService: SocialAuthService
}

public enum RestoreSocialState: Codable, State, Equatable {
    public typealias Event = RestoreSocialEvent
    public typealias Provider = RestoreSocialContainer

    case signIn(deviceShare: String, customResult: APIGatewayRestoreWalletResult?)
    case social(result: APIGatewayRestoreWalletResult)
    case notFoundDevice(data: RestoreSocialData, deviceShare: String, customResult: APIGatewayRestoreWalletResult?)
    case notFoundCustom(result: APIGatewayRestoreWalletResult, email: String)
    case notFoundSocial(data: RestoreSocialData, deviceShare: String, customResult: APIGatewayRestoreWalletResult?)
    case expiredSocialTryAgain(
        result: APIGatewayRestoreWalletResult,
        provider: SocialProvider,
        email: String,
        deviceShare: String?
    )
    case finish(RestoreSocialResult)

    public static var initialState: RestoreSocialState = .signIn(deviceShare: "", customResult: nil)

    public func accept(
        currentState: RestoreSocialState,
        event: RestoreSocialEvent,
        provider: RestoreSocialContainer
    ) async throws -> RestoreSocialState {
        switch currentState {
        case let .signIn(deviceShare, customShare):
            switch event {
            case let .signInDevice(socialProvider):
                return try await handleSignInDevice(
                    deviceShare: deviceShare,
                    customResult: customShare,
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

        case let .notFoundCustom(result, _):
            switch event {
            case let .signInCustom(socialProvider):
                return try await handleSignInCustom(result: result, socialProvider: socialProvider, provider: provider)

            case .start:
                return .finish(.start)
            default:
                throw StateMachineError.invalidEvent
            }

        case let .notFoundDevice(data, deviceShare, customShare):
            switch event {
            case let .signInDevice(socialProvider):
                return try await handleSignInDevice(
                    deviceShare: deviceShare,
                    customResult: customShare,
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

        case let .notFoundSocial(data, deviceShare, customShare):
            switch event {
            case let .signInDevice(socialProvider):
                return try await handleSignInDevice(
                    deviceShare: deviceShare,
                    customResult: customShare,
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

        case let .expiredSocialTryAgain(result, socialProvider, _, deviceShare):
            do {
                let state = try await handleSignInCustom(
                    result: result,
                    socialProvider: socialProvider,
                    provider: provider
                )
                if case .notFoundCustom(result, _) = state, let deviceShare = deviceShare {
                    return try await handleSignInDevice(
                        deviceShare: deviceShare,
                        customResult: result,
                        socialProvider: socialProvider,
                        provider: provider
                    )
                } else {
                    return state
                }
            } catch {
                throw error
            }

        case .finish:
            throw StateMachineError.invalidEvent
        }
    }
}

private extension RestoreSocialState {
    func handleSignInDevice(
        deviceShare: String,
        customResult: APIGatewayRestoreWalletResult?,
        socialProvider: SocialProvider,
        provider: RestoreSocialContainer
    ) async throws -> RestoreSocialState {
        let (value, email) = try await provider.authService.auth(type: socialProvider)
        let tokenID = TokenID(value: value, provider: socialProvider.rawValue)

        try await provider.tKeyFacade.initialize()
        let torusKey = try await provider.tKeyFacade.obtainTorusKey(tokenID: tokenID)

        do {
            let result = try await provider.tKeyFacade.signIn(
                torusKey: torusKey,
                deviceShare: deviceShare
            )
            return .finish(.successful(seedPhrase: result.privateSOL, ethPublicKey: result.reconstructedETH))
        } catch let error as TKeyFacadeError {
            let data = RestoreSocialData(torusKey: torusKey, email: email)
            switch error.code {
            case 1009:
                guard let customShareData = customResult else {
                    return .notFoundDevice(data: data, deviceShare: deviceShare, customResult: nil)
                }

                do {
                    let result = try await provider.tKeyFacade.signIn(
                        torusKey: torusKey,
                        customShare: customShareData.encryptedShare,
                        encryptedMnemonic: customShareData.encryptedPayload
                    )
                    return .finish(
                        .successful(seedPhrase: result.privateSOL, ethPublicKey: result.reconstructedETH)
                    )
                } catch {
                    return .notFoundDevice(data: data, deviceShare: deviceShare, customResult: customShareData)
                }
            case 1021:
                return .notFoundSocial(data: data, deviceShare: deviceShare, customResult: customResult)
            default:
                throw error
            }
        } catch {
            throw error
        }
    }

    func handleSignInCustom(
        result: APIGatewayRestoreWalletResult,
        socialProvider: SocialProvider,
        provider: RestoreSocialContainer
    ) async throws -> RestoreSocialState {
        let (value, email) = try await provider.authService.auth(type: socialProvider)
        let tokenID = TokenID(value: value, provider: socialProvider.rawValue)
        do {
            try await provider.tKeyFacade.initialize()
            let torusKey = try await provider.tKeyFacade.obtainTorusKey(tokenID: tokenID)
            let result = try await provider.tKeyFacade.signIn(
                torusKey: torusKey,
                customShare: result.encryptedShare,
                encryptedMnemonic: result.encryptedPayload
            )
            return .finish(.successful(seedPhrase: result.privateSOL, ethPublicKey: result.reconstructedETH))
        } catch let error as TKeyFacadeError {
            switch error.code {
            case 1009, 1021:
                return .notFoundCustom(result: result, email: email)
            default:
                throw error
            }
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
