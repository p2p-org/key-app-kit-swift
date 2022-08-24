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
    case noMatch
    case start
    case help
}

public enum RestoreCustomEvent {
    case enterPhone
    case enterPhoneNumber(phoneNumber: String)
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
    let deviceShare: String?
}

public enum RestoreCustomState: Codable, State, Equatable {
    public typealias Event = RestoreCustomEvent
    public typealias Provider = RestoreCustomContainer

    case enterPhone(tokenID: TokenID?)
    case enterOTP(phoneNumber: String, solPrivateKey: Data, tokenID: TokenID?)
    case otpNotDeliveredRequireSocial(phoneNumber: String)
    case otpNotDelivered(phoneNumber: String)
    case finish(result: RestoreCustomResult)

    public static var initialState: RestoreCustomState = .enterPhone(tokenID: nil)

    public static func createInitialState(provider _: Provider) async -> RestoreCustomState {
        RestoreCustomState.initialState
    }

    public func accept(
        currentState: RestoreCustomState,
        event: RestoreCustomEvent,
        provider: RestoreCustomContainer
    ) async throws -> RestoreCustomState {

        switch currentState {
        case let .enterPhone(tokenID):
            switch event {
            case .enterPhoneNumber(let phoneNumber):
                let solPrivateKey = try NaclSign.KeyPair.keyPair().secretKey
                do {
                    try await provider.apiGatewayClient.restoreWallet(
                        solPrivateKey: solPrivateKey,
                        phone: phoneNumber,
                        channel: .sms,
                        timestampDevice: Date()
                    )
                    return .enterOTP(phoneNumber: phoneNumber, solPrivateKey: solPrivateKey, tokenID: tokenID)
                }
                catch let error as APIGatewayError {
                    switch error._code {
                    case -32058, -32700, -32600, -32601, -32602, -32603, -32052:
                        throw error
                    case -32050:
                        throw error // retry
                    case -32054:
                        if let deviceShare = provider.deviceShare {
                            return .otpNotDeliveredRequireSocial(phoneNumber: phoneNumber)
                        }
                        else {
                            return .otpNotDelivered(phoneNumber: phoneNumber)
                        }
                    case -32053:
                        throw error
                    default:
                        throw error
                    }
                }

            default:
                throw StateMachineError.invalidEvent
            }

        case let .enterOTP(phoneNumber, solPrivateKey, tokenID):
            switch event {
            case .enterOTP(let otp):
                do {
                    let result = try await provider.apiGatewayClient.confirmRestoreWallet(
                        solanaPrivateKey: solPrivateKey,
                        phone: phoneNumber,
                        otpCode: otp,
                        timestampDevice: Date()
                    )

                    if let tokenID = tokenID, let deviceShare = provider.deviceShare {
                        return try await restore(with: tokenID, customShare: result.encryptedShare, deviceShare: deviceShare, tKey: provider.tKeyFacade)
                    }
                    else if let deviceShare = provider.deviceShare {
                        let finalResult = try await provider.tKeyFacade.signIn(deviceShare: deviceShare, customShare: result.encryptedShare)
                        return .finish(result: .successful(solPrivateKey: finalResult.privateSOL, ethPublicKey: finalResult.reconstructedETH))
                    }
                    else {
                        return .finish(result: .requireSocialCustom(result: result))
                    }
                }
                catch let error as APIGatewayError {
                    switch error._code {
                    case -32700, -32600, -32601, -32602, -32603, -32052:
                        throw error
                    case -32050:
                        throw error // retry 3
                    case -32061: //Invalid value of OTP. Please try again to input correct value of OTP
                        throw error
                    case -32053:
                        throw error //"Please wait 10 min and will ask for new OTP"
                    default:
                        throw error
                    }
                }
            default:
                throw StateMachineError.invalidEvent
            }

        case let .otpNotDeliveredRequireSocial(phone):
            switch event {
            case .back:
                return .enterPhone(tokenID: nil)
            case let .requireSocial(provider):
                return .finish(result: .requireSocialDevice(provider: provider))
            case .help:
                return .finish(result: .help)
            case .start:
                return .finish(result: .start)
            default:
                throw StateMachineError.invalidEvent
            }

        case .otpNotDelivered:
            switch event {
            case .help:
                return .finish(result: .help)
            case .back:
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
                return .finish(result: .noMatch)
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
        case .otpNotDeliveredRequireSocial:
            return 3
        case .otpNotDelivered:
            return 4
        case .finish:
            return 5
        }
    }
}
