import Foundation
import SolanaSwift

/// Info of claimable token
public struct ClaimableTokenInfo {
    public let lamports: Lamports
    public let mintAddress: String
}

/// Service that provide needed data for SendViaLink
public protocol SendViaLinkDataService {
    /// Create new URL
    /// - Returns: URL to be sent
    func createURL(
        givenSeed: String?
    ) -> URL?
    
    /// Get seed from current link
    /// - Parameter link: link to get seed
    /// - Returns: seed
    func getSeedFromURL(
        _ url: URL
    ) -> String?
    
    /// Generate Solana `KeyPair` from given URL.
    /// - Parameter url: claimable url
    /// - Returns: KeyPair for temporary account
    func generateKeyPair(
        url: URL
    ) async throws -> KeyPair?
    
    /// Get info of claimable token
    /// - Parameter url: given url
    /// - Returns: ClaimableToken's info
    func getClaimableTokenInfo(
        url: URL
    ) async throws -> ClaimableTokenInfo?
}

/// Default implementation for `SendViaLinkDataService`
public final class SendViaLinkDataServiceImpl: SendViaLinkDataService {
    
    // MARK: - Constants

    /// Supported character for generating seed
    private let supportedCharacters = #"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_~-"#
    private let scheme = "https"
    private let seedLength = 16
    
    // MARK: - Properties

    private let salt: String
    private let passphrase: String
    private let network: Network
    private let derivablePath: DerivablePath
    private let host: String
    
    // MARK: - Initializer

    public init(
        salt: String,
        passphrase: String,
        network: Network,
        derivablePath: DerivablePath,
        host: String
    ) {
        self.salt = salt
        self.passphrase = passphrase
        self.network = network
        self.derivablePath = derivablePath
        self.host = host
    }
    
    // MARK: - Methods

    /// Create new URL
    /// - Returns: URL to be sent
    public func createURL(
        givenSeed: String?
    ) -> URL? {
        // validate givenSeed
        if let givenSeed, !isSeedValid(seed: givenSeed) {
            return nil
        }
        
        // restore or create new seed
        let seed = givenSeed ?? String((0..<seedLength).map{ _ in supportedCharacters.randomElement()! })
        
        // generate url
        var urlComponent = URLComponents()
        urlComponent.scheme = scheme
        urlComponent.host = host
        urlComponent.path = "/\(seed)"
        return urlComponent.url
    }
    
    /// Get seed from current link
    /// - Parameter link: link to get seed
    /// - Returns: seed
    public func getSeedFromURL(
        _ url: URL
    ) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.scheme == scheme,
              components.host == host
        else {
            return nil
        }
        
        // get seed
        let seed = String(components.path.dropFirst()) // drop "/"
        
        // assert if seed is valid
        guard isSeedValid(seed: seed) else { return nil }
        
        // return the seed
        return seed
    }
    
    /// Generate Solana `KeyPair` from given URL.
    /// - Parameter url: claimable url
    /// - Returns: KeyPair for temporary account
    public func generateKeyPair(
        url: URL
    ) async throws -> KeyPair? {
        guard let seed = getSeedFromURL(url) else {
            return nil
        }
        return try await KeyPair(
            seed: seed,
            salt: salt,
            passphrase: passphrase,
            network: .mainnetBeta,
            derivablePath: .default
        )
    }
    
    /// Get info of claimable token
    /// - Parameter url: given url
    /// - Returns: ClaimableToken's info
    public func getClaimableTokenInfo(
        url: URL
    ) async throws -> ClaimableTokenInfo? {
        // Generate keypair from seed
        let keypair = try await generateKeyPair(url: url)
        
        // Get last transaction and parse to define the amount and token's mint address if possible
        
        // If history is'nt available, check
        // 1. getBalance > 0 for claiming native SOL
        // 2. getTokensAccountByOwner's first > 0 for claiming SPL Token
        
        // return the ClaimableTokenInfo
        fatalError("Implementing")
    }
    
    // MARK: - Helpers

    public func isSeedValid(seed: String) -> Bool {
        seed.count == seedLength && seed.allSatisfy({ supportedCharacters.contains($0) })
    }
}
