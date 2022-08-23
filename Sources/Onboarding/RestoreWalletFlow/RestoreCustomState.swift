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
    case requireSocial(result: RestoreWalletResult)
    case noMatch
}

public enum RestoreCustomEvent {
    case enterPhone
    case enterPhoneNumber(phoneNumber: String)
    case enterOTP(otp: String)
    case resendOTP
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
                try await provider.apiGatewayClient.restoreWallet(
                    solPrivateKey: solPrivateKey,
                    phone: phoneNumber,
                    channel: .sms,
                    timestampDevice: Date()
                )
                return .enterOTP(phoneNumber: phoneNumber, solPrivateKey: solPrivateKey, tokenID: tokenID)

            default:
                throw StateMachineError.invalidEvent
            }

        case let .enterOTP(phoneNumber, solPrivateKey, tokenID):
            switch event {
            case .enterOTP(let otp):
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
                    return .finish(result: .requireSocial(result: result))
                }
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
        case .finish:
            return 3
        }
    }
}
