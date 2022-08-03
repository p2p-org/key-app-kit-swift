// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation

public protocol State: Equatable {
    associatedtype Event
    associatedtype Provider

    static var initialState: Self { get }

    func accept(currentState: Self, event: Event, provider: Provider) async throws -> Self
}

public struct AnyEvent<E> {

}

// public protocol StateMachine {
//     associatedtype S: State
//
//     @discardableResult
//     func accept(event: S.Event) async throws -> S
// }

public actor StateMachine<S: State> {
    private nonisolated let stateSubject: CurrentValueSubject<S, Never>

    public nonisolated var currentState: S { stateSubject.value }
    public nonisolated var stateStream: AnyPublisher<S, Never> { stateSubject.eraseToAnyPublisher() }

    private let provider: S.Provider

    public init(initialState: S? = nil, provider: S.Provider) {
        self.provider = provider
        stateSubject = .init(initialState ?? S.initialState)
    }

    @discardableResult
    public func accept(event: S.Event) async throws -> S {
        let state = try await currentState.accept(currentState: stateSubject.value, event: event, provider: provider)
        stateSubject.send(state)
        return state
    }
}

public enum StateMachineError: Error {
    case invalidEvent
}
