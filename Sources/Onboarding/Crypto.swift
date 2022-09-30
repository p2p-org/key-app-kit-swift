// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import CryptoSwift
import Foundation
import SolanaSwift

enum CryptoError: Error {
    case secureRandomDataError
}

internal enum Crypto {
    struct EncryptedMetadata: Codable {
        let nonce: String
        let metadataCiphered: String

        enum CodingKeys: String, CodingKey {
            case nonce
            case metadataCiphered = "metadata_ciphered"
        }
    }

    private static func extractSymmetricKey(seedPhrase: String) throws -> Data {
        let secretKey = try Ed25519HDKey.derivePath("m/44'/101'/0'/0'", seed: seedPhrase).get().key
        return secretKey
    }

    static func encryptMetadata(seedPhrase: String, data: Data) throws -> EncryptedMetadata {
        let symmetricKey = try extractSymmetricKey(seedPhrase: seedPhrase)
        let iv = AES.randomIV(8)
        let box = try ChaCha20(key: [UInt8](symmetricKey), iv: iv).encrypt([UInt8](data))
        let data = Data(box)

        return EncryptedMetadata(
            nonce: Data(iv).base64EncodedString(),
            metadataCiphered: data.base64EncodedString()
        )
    }

    static func decryptMetadata(seedPhrase: String, encryptedMetadata: EncryptedMetadata) throws -> Data {
        let symmetricKey = try extractSymmetricKey(seedPhrase: seedPhrase)
        
        let iv = [UInt8](Data(base64Encoded: encryptedMetadata.nonce)!)
        let cipher = [UInt8](Data(base64Encoded: encryptedMetadata.metadataCiphered)!)
        let box = try ChaCha20(key: [UInt8](symmetricKey), iv: iv).decrypt(cipher)
        let data = Data(box)
        return data
    }

    private static func secureRandomData(count: Int) throws -> Data {
        var bytes = [Int8](repeating: 0, count: count)

        // Fill bytes with secure random data
        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            count,
            &bytes
        )

        // A status of errSecSuccess indicates success
        if status == errSecSuccess {
            // Convert bytes to Data
            let data = Data(bytes: bytes, count: count)
            return data
        } else {
            // Handle error
            throw CryptoError.secureRandomDataError
        }
    }
}
