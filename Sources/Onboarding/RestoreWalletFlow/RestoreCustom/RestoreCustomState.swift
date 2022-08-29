// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift
import TweetNacl

public typealias RestoreCustomChannel = APIGatewayChannel

public enum RestoreCustomResult: Codable, Equatable {
    case successful(
        solPrivateKey: String,
        ethPublicKey: String
    )
    case requireSocialCustom(result: RestoreWalletResult)
    case requireSocialDevice(provider: SocialProvider)
    case expiredSocialTryAgain(result: RestoreWalletResult, provider: SocialProvider, email: String)
    case start
    case help
}

public enum RestoreCustomEvent {
    case enterPhone
    case enterPhoneNumber(phone: String)
    case enterOTP(otp: String)
    case resendOTP
    case requireSocial(provider: SocialProvider)
    case help
    case start
    case back
}

public struct RestoreCustomContainer {
    let tKeyFacade: TKeyFacade
    let apiGatewayClient: APIGatewayClient
    let authService: SocialAuthService
    let deviceShare: String?
}

public enum RestoreCustomState: Codable, State, Equatable {
    public typealias Event = RestoreCustomEvent
    public typealias Provider = RestoreCustomContainer

    case enterPhone(phone: String?, social: RestoreSocialData?)
    case enterOTP(phone: String, solPrivateKey: Data, social: RestoreSocialData?, attempt: Wrapper<Int>)
    case otpNotDeliveredTrySocial(phone: String)
    case otpNotDelivered(phone: String)
    case noMatch
    case tryAnother(wrongNumber: String, trySocial: Bool)
    case expiredSocialTryAgain(result: RestoreWalletResult, social: RestoreSocialData)
    case broken(code: Int)
    case block(until: Date, social: RestoreSocialData?, reason: PhoneFlowBlockReason)
    case finish(result: RestoreCustomResult)

    public static var initialState: RestoreCustomState = .enterPhone(phone: nil, social: nil)

    public func accept(
        currentState: RestoreCustomState,
        event: RestoreCustomEvent,
        provider: RestoreCustomContainer
    ) async throws -> RestoreCustomState {

        switch currentState {
        case let .enterPhone(phone, social):
            switch event {
            case .enterPhoneNumber(let phone):
                let solPrivateKey = try NaclSign.KeyPair.keyPair().secretKey
                return try await sendOTP(phone: phone, solPrivateKey: solPrivateKey, social: social, attempt: .init(0), provider: provider)

            default:
                throw StateMachineError.invalidEvent
            }

        case .enterOTP(let phone, let solPrivateKey, let social, var attempt):
            switch event {
            case .enterOTP(let otp):
                do {
                    let result = try await provider.apiGatewayClient.confirmRestoreWallet(
                        solanaPrivateKey: solPrivateKey,
                        phone: phone,
                        otpCode: otp,
                        timestampDevice: Date()
                    )

                    if let tokenID = social?.tokenID, !provider.authService.isExpired(token: tokenID.value), let deviceShare = provider.deviceShare {
                        return try await restore(with: tokenID, customShare: result.encryptedShare, deviceShare: deviceShare, tKey: provider.tKeyFacade)
                    }
                    else if let deviceShare = provider.deviceShare {
                        do {
                            let finalResult = try await provider.tKeyFacade.signIn(deviceShare: deviceShare, customShare: result.encryptedShare)
                            return .finish(result: .successful(solPrivateKey: finalResult.privateSOL, ethPublicKey: finalResult.reconstructedETH))
                        }
                        catch {
                            if let social = social, provider.authService.isExpired(token: social.tokenID.value) {
                                return .expiredSocialTryAgain(result: result, social: social)
                            }
                            else {
                                return .noMatch
                            }
                        }
                    }
                    else {
                        return .finish(result: .requireSocialCustom(result: result))
                    }
                }
                catch let error as APIGatewayError {
                    switch error._code {
                    case -32700, -32600, -32601, -32602, -32603, -32052:
                        return .broken(code: error.rawValue)
                    case -32053:
                        return .block(until: Date() + blockTime, social: social, reason: .blockEnterOTP)
                    default:
                        throw error
                    }
                }

            case .resendOTP:
                if attempt.value == 4 {
                    return .block(
                        until: Date() + blockTime,
                        social: social,
                        reason: .blockEnterOTP
                    )
                }
                attempt.value = attempt.value + 1
                return try await sendOTP(phone: phone, solPrivateKey: solPrivateKey, social: social, attempt: attempt, provider: provider)
                
            case .back:
                return .enterPhone(phone: phone, social: social)

            default:
                throw StateMachineError.invalidEvent

            }

        case let .otpNotDeliveredTrySocial(phone):
            switch event {
            case .back:
                return .enterPhone(phone: nil, social: nil)
            case let .requireSocial(provider):
                return .finish(result: .requireSocialDevice(provider: provider))
            case .help:
                return .finish(result: .help)
            case .start:
                return .finish(result: .start)
            default:
                throw StateMachineError.invalidEvent
            }

        case .otpNotDelivered, .broken, .noMatch:
            switch event {
            case .help:
                return .finish(result: .help)
            case .back, .start:
                return .finish(result: .start)
            default:
                throw StateMachineError.invalidEvent
            }

        case let .tryAnother(wrongNumber, trySocial):
            switch event {
            case .enterPhone:
                return .enterPhone(phone: nil, social: nil)
            case .requireSocial(let provider):
                if trySocial {
                    return .finish(result: .requireSocialDevice(provider: provider))
                }
                else {
                    throw StateMachineError.invalidEvent
                }
            case .start:
                return .finish(result: .start)
            default:
                throw StateMachineError.invalidEvent
            }

        case let .block(until, social, reason):
            switch event {
            case .start:
                return .finish(result: .start)
            case .enterPhone:
                guard Date() > until else { throw StateMachineError.invalidEvent }
                return .enterPhone(phone: nil, social: social)
            default:
                throw StateMachineError.invalidEvent
            }

        case let .expiredSocialTryAgain(result, social):
            switch event {
            case .requireSocial(let provider):
                return .finish(result: .expiredSocialTryAgain(result: result, provider: provider, email: social.email))
            case .start:
                return .finish(result: .start)
            default:
                throw StateMachineError.invalidEvent
            }

        case .finish(let result):
            switch event {
            default:
                throw StateMachineError.invalidEvent
            }
        }
    }

    private func restore(with tokenID: TokenID, customShare: String, deviceShare: String, tKey: TKeyFacade) async throws -> RestoreCustomState {
        do {
            let finalResult = try await tKey.signIn(tokenID: tokenID, customShare: customShare)
            return .finish(result: .successful(solPrivateKey: finalResult.privateSOL, ethPublicKey: finalResult.reconstructedETH))
        }
        catch {
            do {
                let finalResult = try await tKey.signIn(deviceShare: deviceShare, customShare: customShare)
                return .finish(result: .successful(solPrivateKey: finalResult.privateSOL, ethPublicKey: finalResult.reconstructedETH))
            }
            catch {
                return .noMatch
            }
        }
    }

    private func sendOTP(phone: String, solPrivateKey: Data, social: RestoreSocialData?, attempt: Wrapper<Int>, provider: RestoreCustomContainer) async throws -> RestoreCustomState {
        do {
            try await provider.apiGatewayClient.restoreWallet(
                solPrivateKey: solPrivateKey,
                phone: phone,
                channel: .sms,
                timestampDevice: Date()
            )
            return .enterOTP(phone: phone, solPrivateKey: solPrivateKey, social: social, attempt: attempt)
        }
        catch let error as APIGatewayError {
            switch error._code {
            case -32058, -32700, -32600, -32601, -32602, -32603, -32052:
                return .broken(code: error.rawValue)
            case -32060:
                return .tryAnother(wrongNumber: phone, trySocial: provider.deviceShare != nil)
            case -32054:
                if let deviceShare = provider.deviceShare {
                    return .otpNotDeliveredTrySocial(phone: phone)
                }
                else {
                    return .otpNotDelivered(phone: phone)
                }
            case -32053:
                return .block(until: Date() + blockTime, social: social, reason: .blockEnterPhoneNumber)

            default:
                throw error
            }
        }
    }
}

extension RestoreCustomState: Step, Continuable {
    public var continuable: Bool { true }

    public var step: Float {
        switch self {
        case .enterPhone:
            return 1
        case .enterOTP:
            return 2
        case .otpNotDeliveredTrySocial:
            return 3
        case .otpNotDelivered:
            return 4
        case .noMatch:
            return 5
        case .broken:
            return 6
        case .tryAnother:
            return 7
        case .block:
            return 8
        case .expiredSocialTryAgain:
            return 9
        case .finish:
            return 10
        }
    }
}
