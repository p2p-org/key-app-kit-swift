// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import CryptoKit
import Foundation
import SolanaSwift

enum CryptoError: Error {
    case secureRandomDataError
}

internal enum Crypto {
    struct EncryptedMetadata: Codable {
        let nonce: String
        let metadataCiphered: String
        let tag: String

        enum CodingKeys: String, CodingKey {
            case nonce
            case metadataCiphered = "metadata_ciphered"
            case tag
        }
    }

    private static func extractSymmetricKey(seedPhrase: String) throws -> SymmetricKey {
        let secretKey = try Ed25519HDKey.derivePath("m/44'/101'/0'/0'", seed: seedPhrase).get().key
        return SymmetricKey(data: secretKey)
    }

    static func encryptMetadata(seedPhrase: String, data: Data) throws -> EncryptedMetadata {
        let symmetricKey = try extractSymmetricKey(seedPhrase: seedPhrase)
        let box = try ChaChaPoly.seal(data, using: symmetricKey)

        return EncryptedMetadata(
            nonce: Data(box.nonce).base64EncodedString(),
            metadataCiphered: box.ciphertext.base64EncodedString(),
            tag: box.tag.base64EncodedString()
        )
    }

    static func decryptMetadata(seedPhrase: String, encryptedMetadata: EncryptedMetadata) throws -> Data {
        let symmetricKey = try extractSymmetricKey(seedPhrase: seedPhrase)
        let box = try ChaChaPoly.SealedBox(
            nonce: try .init(data: Data(base64Encoded: encryptedMetadata.nonce)!),
            ciphertext: Data(base64Encoded: encryptedMetadata.metadataCiphered)!,
            tag: Data(base64Encoded: encryptedMetadata.tag)!
        )

        return try ChaChaPoly.open(box, using: symmetricKey)
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
