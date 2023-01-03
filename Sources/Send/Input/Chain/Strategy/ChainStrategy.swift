//
//  ChainStrategy.swift
//  Send
//
//  Created by Giang Long Tran on 03.01.2023.
//

import Foundation

protocol ChainStrategy {
    static func validateInput(_ state: SendInputState, _ service: SendInputServices) async -> SendInputState
}
