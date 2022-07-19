// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public protocol State {
    associatedtype Event
    static var initialState: Self { get }

    func accept(currentState: Self, event: Event) async throws -> Self
}

public actor StateMachine<S: State> {
    private(set) var currentState: S

    init(initialState: S?) {
        currentState = initialState ?? S.initialState
    }

    func accept(event: S.Event) async throws -> S {
        let state = try await currentState.accept(currentState: currentState, event: event)
        currentState = state
        return state
    }
}

public enum StateMachineError: Error {
    case invalidEvent
}