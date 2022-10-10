//
// Created by Tran Hai Bac on 07.10.2022.
//
import Foundation
@testable import Onboarding

public class SocialAuthServiceMock: SocialAuthService {

    public func auth(type: SocialProvider) async throws -> (tokenID: String, email: String) {
        (tokenID: "someTokenID", email: "someEmail")
    }

    public func isExpired(token: String) -> Bool {
        token != token
    }
}