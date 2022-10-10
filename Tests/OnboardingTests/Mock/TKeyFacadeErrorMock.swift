//
// Created by Tran Hai Bac on 07.10.2022.
//

import Foundation
@testable import Onboarding

struct TKeyFacadeErrorMock: TKeyFacade {
    let errorCode: Int

    func initialize() async throws {
    }

    func signUp(tokenID: TokenID, privateInput: String) async throws -> SignUpResult {
        throw TKeyFacadeError(name: "", code: errorCode, message: "", original: "")
    }

    func signIn(tokenID: TokenID, deviceShare: String) async throws -> SignInResult {
        throw TKeyFacadeError(name: "", code: errorCode, message: "", original: "")
    }

    func signIn(tokenID: TokenID, customShare: String, encryptedMnemonic: String) async throws -> SignInResult {
        throw TKeyFacadeError(name: "", code: errorCode, message: "", original: "")
    }

    func signIn(deviceShare: String, customShare: String, encryptedMnemonic: String) async throws -> SignInResult {
        throw TKeyFacadeError(name: "", code: errorCode, message: "", original: "")
    }


}
