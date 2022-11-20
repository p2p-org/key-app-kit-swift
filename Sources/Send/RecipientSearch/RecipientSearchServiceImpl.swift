// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import NameService

public class RecipientSearchServiceImpl: RecipientSearchService{
    let nameService: NameService
    
    public init(nameService: NameService) {
        self.nameService = nameService
    }
    
    // TODO: Implement me
    public func search(input: String, env: UserWalletEnvironments) async -> RecipientSearchResult {
        .ok([])
    }
}
