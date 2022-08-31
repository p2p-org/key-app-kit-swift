// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

public struct RestoreWalletData: Codable, Equatable {
    public let wallet: OnboardingWallet
    public let security: SecurityData
}
