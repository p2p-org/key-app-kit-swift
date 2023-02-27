// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

/// State machine that handle a specific consistent state
public protocol StateMachine {
    /// State to be consisted
    associatedtype State: Equatable
    /// Action that modify the state
    associatedtype Action: Equatable
    /// Converting function to convert an action to a style
    func accept(action: Action) async -> State
}
