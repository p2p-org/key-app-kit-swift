// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

actor PromiseDispatchTable {
    typealias PromiseID = Int64

    var promiseID: PromiseID = 0
    var promiseDispatchTable: [Int64: CheckedContinuation<Void, Swift.Error>] = .init()

    func register(continuation: CheckedContinuation<Void, Swift.Error>) -> Int64 {
        defer { promiseID = promiseID + 1 }
        promiseDispatchTable[promiseID] = continuation
        return promiseID
    }

    func resolve(for id: PromiseID) {
        promiseDispatchTable[id]?.resume(returning: ())
        promiseDispatchTable.removeValue(forKey: id)
    }

    func resolveWithError(for id: PromiseID, error: Error) {
        promiseDispatchTable[id]?.resume(throwing: error)
        promiseDispatchTable.removeValue(forKey: id)
    }
}