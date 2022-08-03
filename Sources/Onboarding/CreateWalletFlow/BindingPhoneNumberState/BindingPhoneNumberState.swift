// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

class SomePhoneNumberProvider {}

enum BindingPhoneNumberEvent {
    case enterPhoneNumber(phoneNumber: String)
}

enum BindingPhoneNumberResult: Codable {
    case success
}

enum BindingPhoneNumberState: Codable, State, Equatable {
    typealias Event = BindingPhoneNumberEvent
    typealias Provider = SomePhoneNumberProvider

    case enterPhoneNumber
    
    case enterOTP
    case finish(result: BindingPhoneNumberResult)

    static var initialState: BindingPhoneNumberState = .enterPhoneNumber

    func accept(
        currentState _: BindingPhoneNumberState,
        event _: BindingPhoneNumberEvent,
        provider _: SomePhoneNumberProvider
    ) async throws -> BindingPhoneNumberState {
        <#code#>
    }
}
