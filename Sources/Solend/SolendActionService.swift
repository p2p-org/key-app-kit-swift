// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import SolanaSwift

public enum SolendActionStatus: Codable {
    case processing
    case success
    case failed(msg: String)
}

public enum SolendActionType: Codable {
    case deposit
    case withdraw
}

public struct SolendAction: Codable {
    public let type: SolendActionType
    public let transactionID: String
    public internal(set) var status: SolendActionStatus
    public let amount: UInt64
    public let symbol: SolendSymbol
}

public protocol SolendActionService {
    var currentAction: AnyPublisher<SolendAction?, Never> { get }
    func clearAction() throws

    func depositFee(amount: UInt64, symbol: SolendSymbol) async throws -> SolendDepositFee

    func deposit(amount: UInt64, symbol: SolendSymbol) async throws
    func withdraw(amount: UInt64, symbol: SolendSymbol) async throws
}
