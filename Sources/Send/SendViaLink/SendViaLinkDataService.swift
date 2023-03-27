import Foundation
import SolanaSwift

/// Info of claimable token
public struct ClaimableTokenInfo {
    public let lamports: Lamports
    public let mintAddress: String
}

/// Error type for SendViaLinkDataService
public enum SendViaLinkDataServiceError: Error {
    case invalidSeed
    case lastTransactionNotFound
}

/// Service that provide needed data for SendViaLink
public protocol SendViaLinkDataService {
    /// Create new URL
    /// - Returns: URL to be sent
    func createURL() -> URL
    
    /// Restore URL from givenSeed
    /// - Parameter givenSeed: the seed given by user
    /// - Returns: URL to be sent
    func restoreURL(
        givenSeed: String
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
    private let supportedCharacters = #"!$'()*+,-.0123456789@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz~"#
    private let scheme = "https"
    private let seedLength = 16
    
    // MARK: - Properties

    private let salt: String
    private let passphrase: String
    private let network: Network
    private let derivablePath: DerivablePath
    private let host: String
    private let solanaAPIClient: SolanaAPIClient
    
    // MARK: - Initializer

    public init(
        salt: String,
        passphrase: String,
        network: Network,
        derivablePath: DerivablePath,
        host: String,
        solanaAPIClient: SolanaAPIClient
    ) {
        self.salt = salt
        self.passphrase = passphrase
        self.network = network
        self.derivablePath = derivablePath
        self.host = host
        self.solanaAPIClient = solanaAPIClient
    }
    
    // MARK: - Methods

    /// Create new URL
    /// - Returns: URL to be sent
    public func createURL() -> URL {
        let newSeed = String((0..<seedLength).map{ _ in supportedCharacters.randomElement()! })
        return restoreURL(givenSeed: newSeed)!
    }
    
    /// Restore URL from givenSeed
    /// - Parameter givenSeed: the seed given by user
    /// - Returns: URL to be sent
    public func restoreURL(
        givenSeed seed: String
    ) -> URL? {
        // validate givenSeed
        if !isSeedValid(seed: seed) {
            return nil
        }
        
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
        guard let keypair = try await generateKeyPair(url: url)
        else {
            throw SendViaLinkDataServiceError.invalidSeed
        }
        
        // Get last transaction and parse to define the amount and token's mint address if possible
        do {
            let claimableTokenInfo = try await getClaimableTokenInfoFromHistory(
                pubkey: keypair.publicKey.base58EncodedString
            )
            return claimableTokenInfo
        }
        
        // If history is'nt available, check
        catch SendViaLinkDataServiceError.lastTransactionNotFound {
            let claimableTokenInfo = try await getClaimableTokenInfoFromBalance(
                pubkey: keypair.publicKey.base58EncodedString
            )
            return claimableTokenInfo
        }
    }
    
    // MARK: - Helpers

    private func isSeedValid(seed: String) -> Bool {
        seed.count == seedLength && seed.allSatisfy({ supportedCharacters.contains($0) })
    }
    
    // MARK: - Get ClaimableToken from history

    private func getClaimableTokenInfoFromHistory(
        pubkey: String
    ) async throws -> ClaimableTokenInfo {
        // get signatures
        let signature = try await solanaAPIClient.getSignaturesForAddress(
            address: pubkey,
            configs: RequestConfiguration(commitment: "recent")
        )
            .first?
            .signature
        
        guard let signature else {
            throw SendViaLinkDataServiceError.lastTransactionNotFound
        }
        
        // get last transaction
        let lastTransaction = try await solanaAPIClient.getTransaction(
            signature: signature,
            commitment: "recent"
        )
        
        guard let lastTransaction else {
            throw SendViaLinkDataServiceError.lastTransactionNotFound
        }
        
        // parse transaction
        return try parseSendViaLinkTransaction(transactionInfo: lastTransaction)
    }
    
    private func parseSendViaLinkTransaction(
        transactionInfo: TransactionInfo
    ) throws -> ClaimableTokenInfo {
        fatalError()
    }
    
    // MARK: - Get ClaimableToken from balance

    private func getClaimableTokenInfoFromBalance(
        pubkey: String
    ) async throws -> ClaimableTokenInfo {
        fatalError()
    }
}
