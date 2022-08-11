// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public typealias RestoreWalletStateMachine = StateMachine<RestoreWalletState>

public enum RestoreWalletState: Codable, State, Equatable {
    public typealias Event = RestoreWalletEvent
    public typealias Provider = TKeyFacade
    public static var initialState: RestoreWalletState = .signIn

    public static func createInitialState(provider: Provider) async -> RestoreWalletState {
        return RestoreWalletState.initialState
    }

    public func accept(
        currentState: RestoreWalletState,
        event: RestoreWalletEvent,
        provider: Provider
    ) async throws -> RestoreWalletState {
        switch currentState {
        case .signIn:
            switch event {
            case let .signInWithDeviceShare(tokenID, deviceShare):
                let result = try await provider.signIn(tokenID: .init(value: tokenID, provider: "apple"), deviceShare: deviceShare)
                return .restoredData(solPrivateKey: result.privateSOL, ethPublicKey: result.reconstructedETH)
            case let .signInWithCustomShare(tokenID):
                let result = try await provider.signIn(tokenID: .init(value: tokenID, provider: "apple"), withCustomShare: "")
                return .restoredData(solPrivateKey: result.privateSOL, ethPublicKey: result.reconstructedETH)
            }
        case .restoredData:
            return currentState
        }
    }
    
    case signIn
    case restoredData(solPrivateKey: String, ethPublicKey: String)
}

public enum RestoreWalletEvent {
    case signInWithDeviceShare(tokenID: String, deviceShare: String)
    case signInWithCustomShare(tokenID: String)
}
