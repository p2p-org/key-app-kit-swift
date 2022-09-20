// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation

public class SolendActionServiceMock: SolendActionService {
    public init() {}
    
    public var currentAction: AnyPublisher<SolendAction?, Never> {
        CurrentValueSubject(nil).eraseToAnyPublisher()
    }

    public func clearAction() throws {}

    public func depositFee(amount _: UInt64, symbol _: SolendSymbol) async throws -> SolendDepositFee {
        .init(fee: 0, rent: 0)
    }

    public func deposit(amount _: UInt64, symbol _: SolendSymbol) async throws {}

    public func withdraw(amount _: UInt64, symbol _: SolendSymbol) async throws {}
}
