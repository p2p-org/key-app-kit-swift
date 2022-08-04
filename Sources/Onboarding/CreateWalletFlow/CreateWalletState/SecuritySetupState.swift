// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public enum SecuritySetupResult: Codable, Equatable {
    case success(pincode: String, withBiometric: Bool)
}

public enum SecuritySetupEvent {
    case setPincode(pincode: String, withBiometric: Bool)
}

public enum SecuritySetupState: Codable, State, Equatable {
    public typealias Event = SecuritySetupEvent
    public typealias Provider = None

    case setupPincode
    case finish(_ result: SecuritySetupResult)

    public private(set) static var initialState: SecuritySetupState = .setupPincode

    public func accept(
        currentState: SecuritySetupState,
        event: Event,
        provider _: Provider
    ) async throws -> SecuritySetupState {
        switch currentState {
        case .setupPincode:
            switch event {
            case let .setPincode(pincode: pincode, withBiometric: withBiometric):
                return .finish(.success(pincode: pincode, withBiometric: withBiometric))
            }
        default:
            throw StateMachineError.invalidEvent
        }
    }
}

extension SecuritySetupState: Step {
    public var step: Float {
        switch self {
        case .setupPincode:
            return 1
        case .finish(_):
            return 2
        }
    }
}