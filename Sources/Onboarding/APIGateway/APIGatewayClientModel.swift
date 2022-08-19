// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

struct APIGatewayRegisterWalletParams: Codable {
    let solanaPublicKey: String
    let ethereumAddress: String
    let phone: String
    let channel: String
    let signature: String
    let timestampDevice: String

    enum CodingKeys: String, CodingKey {
        case solanaPublicKey = "solana_pubkey"
        case ethereumAddress = "ethereum_id"
        case phone
        case channel
        case signature
        case timestampDevice = "timestamp_device"
    }
}

struct APIGatewayConfirmRegisterWalletParams: Codable {
    let solanaPublicKey: String
    let ethereumAddress: String
    let encryptedShare: String
    let encryptedPayload: String
    let phone: String
    let phoneConfirmationCode: String
    let signature: String
    let timestampDevice: String

    enum CodingKeys: String, CodingKey {
        case solanaPublicKey = "solana_pubkey"
        case ethereumAddress = "ethereum_id"
        case phone
        case phoneConfirmationCode = "phone_confirmation_code"
        case encryptedShare = "encrypted_share"
        case encryptedPayload = "encrypted_payload"
        case signature
        case timestampDevice = "timestamp_device"
    }
}

struct APIGatewayRestoreWalletParams: Codable {
    let restoreId: String
    let phone: String
    let appHash: String
    let channel: String
    let signature: String
    let timestampDevice: String

    enum CodingKeys: String, CodingKey {
        case restoreId = "restore_id"
        case phone
        case appHash = "app_hash"
        case channel
        case signature
        case timestampDevice = "timestamp_device"
    }
}

struct APIGatewayConfirmRestoreWalletParams: Codable {
    let restoreId: String
    let phone: String
    let phoneConfirmationCode: String
    let signature: String
    let timestampDevice: String

    enum CodingKeys: String, CodingKey {
        case restoreId = "restore_id"
        case phone
        case phoneConfirmationCode = "phone_confirmation_code"
        case signature
        case timestampDevice = "timestamp_device"
    }
}

struct APIGatewayClientResult: Codable {
    let status: Bool
}

struct APIGatewayClientConfirmRestoreWalletResult: Codable {
    let status: Bool
    let solanaPublicKey: String
    let ethereumAddress: String

    /// Base64 encoded share
    let share: String

    /// Base64 encoded share
    let payload: String

    enum CodingKeys: String, CodingKey {
        case status
        case solanaPublicKey = "solana_pubkey"
        case ethereumAddress = "ethereum_id"
        case share
        case payload
    }
}
