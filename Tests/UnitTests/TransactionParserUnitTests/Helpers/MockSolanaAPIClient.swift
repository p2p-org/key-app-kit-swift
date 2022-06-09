import Foundation
@testable import SolanaSwift

class MockSolanaAPIClient: SolanaAPIClient {
    
    var endpoint: APIEndPoint {
        APIEndPoint.defaultEndpoints.first!
    }
    
    func getAccountInfo<T>(account: String) async throws -> BufferInfo<T>? where T : BufferLayout {
        fatalError()
    }
    
    func getBalance(account: String, commitment: Commitment?) async throws -> UInt64 {
        fatalError()
    }
    
    func getBlockCommitment(block: UInt64) async throws -> BlockCommitment {
        fatalError()
    }
    
    func getBlockTime(block: UInt64) async throws -> Date {
        fatalError()
    }
    
    func getClusterNodes() async throws -> [ClusterNodes] {
        fatalError()
    }
    
    func getBlockHeight() async throws -> UInt64 {
        fatalError()
    }
    
    func getConfirmedBlocksWithLimit(startSlot: UInt64, limit: UInt64) async throws -> [UInt64] {
        fatalError()
    }
    
    func getConfirmedBlock(slot: UInt64, encoding: String) async throws -> ConfirmedBlock {
        fatalError()
    }
    
    func getConfirmedSignaturesForAddress(account: String, startSlot: UInt64, endSlot: UInt64) async throws -> [String] {
        fatalError()
    }
    
    func getEpochInfo(commitment: Commitment?) async throws -> EpochInfo {
        fatalError()
    }
    
    func getFees(commitment: Commitment?) async throws -> Fee {
        .init(feeCalculator: .init(lamportsPerSignature: 5000), feeRateGovernor: nil, blockhash: "GwXLB5biQoCEGPB1auCSoob87GBkiN9bqF8R78nsdSFp", lastValidSlot: 136873719)
    }
    
    func getSignatureStatuses(signatures: [String], configs: RequestConfiguration?) async throws -> [SignatureStatus?] {
        fatalError()
    }
    
    func getSignatureStatus(signature: String, configs: RequestConfiguration?) async throws -> SignatureStatus {
        fatalError()
    }
    
    func getTokenAccountBalance(pubkey: String, commitment: Commitment?) async throws -> TokenAccountBalance {
        fatalError()
    }
    
    func getTokenAccountsByDelegate(pubkey: String, mint: String?, programId: String?, configs: RequestConfiguration?) async throws -> [TokenAccount<AccountInfo>] {
        fatalError()
    }
    
    func getTokenAccountsByOwner(pubkey: String, params: OwnerInfoParams?, configs: RequestConfiguration?) async throws -> [TokenAccount<AccountInfo>] {
        fatalError()
    }
    
    func getTokenLargestAccounts(pubkey: String, commitment: Commitment?) async throws -> [TokenAmount] {
        fatalError()
    }
    
    func getTokenSupply(pubkey: String, commitment: Commitment?) async throws -> TokenAmount {
        fatalError()
    }
    
    func getVersion() async throws -> Version {
        fatalError()
    }
    
    func getVoteAccounts(commitment: Commitment?) async throws -> VoteAccounts {
        fatalError()
    }
    
    func minimumLedgerSlot() async throws -> UInt64 {
        fatalError()
    }
    
    func requestAirdrop(account: String, lamports: UInt64, commitment: Commitment?) async throws -> String {
        fatalError()
    }
    
    func sendTransaction(transaction: String, configs: RequestConfiguration) async throws -> TransactionID {
        fatalError()
    }
    
    func simulateTransaction(transaction: String, configs: RequestConfiguration) async throws -> SimulationResult {
        fatalError()
    }
    
    func setLogFilter(filter: String) async throws -> String? {
        fatalError()
    }
    
    func validatorExit() async throws -> Bool {
        fatalError()
    }
    
    func getMultipleAccounts<T>(pubkeys: [String]) async throws -> [BufferInfo<T>] where T : BufferLayout {
        fatalError()
    }
    
    func getSignaturesForAddress(address: String, configs: RequestConfiguration?) async throws -> [SignatureInfo] {
        fatalError()
    }
    
    func getTransaction(signature: String, commitment: Commitment?) async throws -> TransactionInfo? {
        fatalError()
    }
    
    func batchRequest(with requests: [JSONRPCRequestEncoder.RequestType]) async throws -> [AnyResponse<JSONRPCRequestEncoder.RequestType.Entity>] {
        fatalError()
    }
    
    func request<Entity>(method: String, params: [Encodable]) async throws -> Entity where Entity : Decodable {
        fatalError()
    }
    
    func getRecentBlockhash(commitment: Commitment?) async throws -> String {
        fatalError()
    }
    
    func observeSignatureStatus(signature: String, timeout: Int, delay: Int) -> AsyncStream<TransactionStatus> {
        fatalError()
    }
    
    func getMinimumBalanceForRentExemption(dataLength: UInt64, commitment: Commitment?) async throws -> UInt64 {
        2039280
    }
}
