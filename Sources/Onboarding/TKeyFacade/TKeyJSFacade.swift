// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import JSBridge
import WebKit

public class TKeyJSFacade: TKeyFacade {
    enum Error: Swift.Error {
        case canNotFindJSScript
        case facadeIsNotReady
        case invalidReturnValue
    }

    private let kLibrary: String = "p2pWeb3Auth"

    private let context: JSBContext
    private var facadeClass: JSBValue?

    public init(wkWebView: WKWebView? = nil) {
        context = JSBContext(wkWebView: wkWebView)
    }

    public func initialize() async throws {
        let scriptPath = getSDKPath()
        let request = URLRequest(url: URL(fileURLWithPath: scriptPath))
        try await context.load(request: request)
        facadeClass = try await context.this.valueForKey("\(kLibrary).IosFacade")
    }
    
    private func getSDKPath() -> String {
        #if SWIFT_PACKAGE
            guard let scriptPath = Bundle.module.path(forResource: "index", ofType: "html") else {
                fatalError(Error.canNotFindJSScript.localizedDescription)
            }
        #else
            guard let scriptPath = Bundle(for: TKeyJSFacade.self).path(forResource: "index", ofType: "html") else {
                fatalError(Error.canNotFindJSScript.localizedDescription)
            }
        #endif
        
        return scriptPath
    }
    
    private func getFacade(configuration: [String: Any]) async throws -> JSBValue {
        let library = try getLibrary()
        return try await library.invokeNew(withArguments: [configuration])
    }

    public func signUp(tokenID: TokenID) async throws -> SignUpResult {
        let facade = try await getFacade(configuration: ["type": "signup", "useNewEth": false])
        let value = try await facade.invokeAsyncMethod("triggerSilentSignup", withArguments: [tokenID.value])
        
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
        let facade = try await getFacade(configuration: [:])
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
        let facade = try await getFacade(configuration: [:])
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
    
    func getLibrary() throws -> JSBValue {
        guard let library = facadeClass else {
            throw Error.facadeIsNotReady
        }
        return library
    }
}
