// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import Combine

class SolendActionServiceMock: SolendActionService {
    var currentAction: AnyPublisher<SolendAction?, Never>

    func clearAction() throws {
        <#code#>
    }

    func depositFee(amount _: UInt64, symbol _: SolendSymbol) async throws -> SolendDepositFee {
        <#code#>
    }

    func deposit(amount _: UInt64, symbol _: SolendSymbol) async throws {
        <#code#>
    }

    func withdraw(amount _: UInt64, symbol _: SolendSymbol) async throws {
        <#code#>
    }
}
