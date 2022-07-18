// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import JSBridge
import WebKit

public class TKeyJS: TKeyFacade {
    enum Error: Swift.Error {
        case canNotFindJSScript
        case facadeIsNotReady
        case invalidReturnValue
    }

    private let kLibrary: String = "p2pWeb3Auth"

    private let context: JSBContext
    private var facade: JSBValue?
    
    public init(wkWebView: WKWebView) {
        context = JSBContext(wkWebView: wkWebView)
    }

    public func initialize() async throws {
        guard let scriptPath = Bundle.module.path(forResource: "index", ofType: "html") else {
            fatalError(Error.canNotFindJSScript.localizedDescription)
        }

        let request = URLRequest(url: URL(fileURLWithPath: scriptPath))
        try await context.load(request: request)

        facade = JSBValue(in: context, name: "tkeyFacade")
        try await context.evaluate("\(facade!.name) = new \(kLibrary).IosFacade();")
    }

    public func signUp(tokenID: TokenID) async throws -> SignUpResult {
        let facade = try getFacade()
        let value = try await facade.invokeAsyncMethod("triggerSilentSignup", withArguments: [tokenID.value])
        print(try await value.toDictionary())
        guard
            let result = try await value.toDictionary(),
            let privateSOL = result["privateSOL"] as? String,
            let reconstructedETH = result["reconstructedETH"] as? String,
            let deviceShare = result["deviceShare"] as? String
        else { throw Error.invalidReturnValue }

        return .init(
            privateSOL: privateSOL,
            reconstructedETH: reconstructedETH,
            deviceShare: deviceShare
        )
    }

    public func signIn(tokenID: TokenID, deviceShare: String) async throws -> SignInResult {
        let facade = try getFacade()
        let value = try await facade.invokeAsyncMethod(
            "triggerSignInNoCustom",
            withArguments: [tokenID.value, deviceShare]
        )
        guard
            let result = try await value.toDictionary(),
            let privateSOL = result["privateSOL"] as? String,
            let reconstructedETH = result["reconstructedETH"] as? String
        else { throw Error.invalidReturnValue }

        return .init(
            privateSOL: privateSOL,
            reconstructedETH: reconstructedETH
        )
    }

    public func signIn(tokenID: TokenID, withCustomShare _: String) async throws -> SignInResult {
        let facade = try getFacade()
        let value = try await facade.invokeAsyncMethod(
            "triggerSignInNoDevice",
            withArguments: [tokenID.value]
        )
        guard
            let result = try await value.toDictionary(),
            let privateSOL = result["privateSOL"] as? String,
            let reconstructedETH = result["reconstructedETH"] as? String
        else { throw Error.invalidReturnValue }

        return .init(
            privateSOL: privateSOL,
            reconstructedETH: reconstructedETH
        )
    }

    private func getFacade() throws -> JSBValue {
        guard let facade = facade else { throw Error.facadeIsNotReady }
        return facade
    }
}
