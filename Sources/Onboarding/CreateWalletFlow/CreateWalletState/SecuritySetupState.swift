// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public enum SecuritySetupResult: Codable, Equatable {
    case success(pincode: String?, withBiometric: Bool)
}

public enum SecuritySetupEvent {
    case back
    case createPincode
    case confirmPincode(pincode: String)
    case setPincode(pincode: String?, withBiometric: Bool)
}

public enum SecuritySetupState: Codable, State, Equatable {
    public typealias Event = SecuritySetupEvent
    public typealias Provider = SecurityStatusProvider

    case setProtectionLevel
    case createPincode
    case confirmPincode(pincode: String)
    case finish(_ result: SecuritySetupResult)

    public private(set) static var initialState: SecuritySetupState = .setProtectionLevel

    public static func createInitialState(provider: Provider) async -> SecuritySetupState {
        if !provider.isBiometryAvailable {
            SecuritySetupState.initialState = .createPincode
        }
        return SecuritySetupState.initialState
    }

    public func accept(
        currentState: SecuritySetupState,
        event: Event,
        provider _: Provider
    ) async throws -> SecuritySetupState {
        switch currentState {
        case .setProtectionLevel:
            switch event {
            case .createPincode:
                return .createPincode
            case let .setPincode(pincode, withBiometric):
                return .finish(.success(pincode: pincode, withBiometric: withBiometric))
            default:
                throw StateMachineError.invalidEvent
            }
        case .createPincode:
            switch event {
            case let .confirmPincode(pincode):
                return .confirmPincode(pincode: pincode)
            case .back:
                return .setProtectionLevel
            default:
                throw StateMachineError.invalidEvent
            }
        case .confirmPincode:
            switch event {
            case .back:
                return .createPincode
            case .createPincode:
                return .createPincode
            case let .setPincode(pincode, withBiometric):
                return .finish(.success(pincode: pincode, withBiometric: withBiometric))
            default:
                throw StateMachineError.invalidEvent
            }

        default:
            throw StateMachineError.invalidEvent
        }
    }
}

extension SecuritySetupState: Step, Continuable {
    public var continuable: Bool {
        switch self {
        case .confirmPincode(pincode: let pincode):
            return false
        default:
            return true
        }
    }
    
    public var step: Float {
        switch self {
        case .setProtectionLevel:
            return 1
        case .createPincode:
            return 2
        case .confirmPincode:
            return 3
        case .finish:
            return 4
        }
    }
}
