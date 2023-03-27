import Foundation
import SolanaSwift

/// Info of claimable token
public struct ClaimableTokenInfo {
    public let lamports: Lamports
    public let mintAddress: String
}

/// Service that provide needed data for SendViaLink
public protocol SendViaLinkDataService {
    /// Create seed for generating link
    /// - Returns: seed to be added to link
    func createSeed() -> String
    
    /// Generate Solana `KeyPair` from given seed.
    /// - Parameter seed: seed
    /// - Returns: KeyPair for temporary account
    func generateKeyPair(
        seed: String
    ) async throws -> KeyPair
    
    /// Get info of claimable token
    /// - Parameter seed: given seed
    /// - Returns: ClaimableToken's info
    func getClaimableTokenInfo(
        seed: String
    ) async throws -> ClaimableTokenInfo
}

/// Default implementation for `SendViaLinkDataService`
public final class SendViaLinkDataServiceImpl: SendViaLinkDataService {
    
    // MARK: - Constants

    /// Supported character for generating seed
    private let supportedCharacters = #"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_~-"#
    
    // MARK: - Properties

    private let salt: String
    private let passphrase: String
    private let network: Network
    private let derivablePath: DerivablePath
    
    // MARK: - Initializer

    init(
        salt: String,
        passphrase: String,
        network: Network,
        derivablePath: DerivablePath
    ) {
        self.salt = salt
        self.passphrase = passphrase
        self.network = network
        self.derivablePath = derivablePath
    }
    
    // MARK: - Methods

    /// Create seed for generating link
    /// - Returns: seed to be added to link
    public func createSeed() -> String {
        String((0..<16).map{ _ in supportedCharacters.randomElement()! })
    }
    
    /// Generate Solana `KeyPair` from given seed.
    /// - Parameter seed: seed
    /// - Returns: KeyPair for temporary account
    public func generateKeyPair(
        seed: String
    ) async throws -> KeyPair {
        try await KeyPair(
            seed: seed,
            salt: salt,
            passphrase: passphrase,
            network: .mainnetBeta,
            derivablePath: .default
        )
    }
    
    /// Get info of claimable token
    /// - Parameter seed: given seed
    /// - Returns: ClaimableToken's info
    public func getClaimableTokenInfo(
        seed: String
    ) async throws -> ClaimableTokenInfo {
        // Generate keypair from seed
        let keypair = try await generateKeyPair(seed: seed)
        
        // Get last transaction and parse to define the amount and token's mint address if possible
        
        // If history is'nt available, check
        // 1. getBalance > 0 for claiming native SOL
        // 2. getTokensAccountByOwner's first > 0 for claiming SPL Token
        
        // return the ClaimableTokenInfo
        fatalError("Implementing")
    }
}
