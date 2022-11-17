// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public enum RecipientSearchResult: Equatable {
    case ok([Recipient])
    case invalidInput
    
    /// Condition: No response from name service
    case solanaServiceError(_ error: NSError)
    
    /// Condition: recipient's token account and user's RenBTC balance = 0
    // case notEnoughRenBTC(recipient: Recipient)
    
    /// Condition: recipient's token account address and user's token balance = 0 (include renBTC)
    case missingUserToken(recipient: Recipient)
    
    /// Condition: recipient's wallet address without funds and user doesn't have token to pay creation account fee.
    case insufficientUserFunds
}

public protocol RecipientSearchService: AnyObject {
    func search(input: String, state: UserWalletState) async -> RecipientSearchResult
}
