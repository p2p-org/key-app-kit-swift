// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation

public actor SendInputStateMachine {
    private var stateSubject: CurrentValueSubject<SendInputState, Never>
    
    public var statePublisher: AnyPublisher<SendInputState, Never> { stateSubject.eraseToAnyPublisher() }
    public var currentState: SendInputState { stateSubject.value }
    
    init(initialState: SendInputState) {
        stateSubject = .init(initialState)
    }
    
    func accept(action: SendInputAction) async -> SendInputState {
        await sendInputBusinessLogic(state: currentState, action: action)
    }
}
