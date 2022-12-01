import FeeRelayerSwift
import OrcaSwapSwift
import SolanaSwift
import Foundation

public protocol SendFeeCalculator: AnyObject {
    func load() async throws

    func getFees(
        from wallet: Wallet,
        receiver: String,
        payingTokenMint: String?
    ) async throws -> FeeAmount?

    func getFeesInPayingToken(
        feeInSOL: FeeAmount,
        payingFeeToken: Token
    ) async throws -> FeeAmount?

    // TODO: hide direct usage of ``UsageStatus``
    func getFreeTransactionFeeLimit() async throws -> UsageStatus
}

public class SendFeeCalculatorImpl: SendFeeCalculator {

    private let contextManager: FeeRelayerContextManager
    private let solanaAPIClient: SolanaAPIClient
    private let orcaSwap: OrcaSwapType
    private let feeRelayer: FeeRelayer
    private let feeRelayerAPIClient: FeeRelayerAPIClient

    private let env: UserWalletEnvironments

    public init(
        contextManager: FeeRelayerContextManager,
        env: UserWalletEnvironments,
        orcaSwap: OrcaSwapType,
        feeRelayer: FeeRelayer,
        feeRelayerAPIClient: FeeRelayerAPIClient,
        solanaAPIClient: SolanaAPIClient
    ) {
        self.contextManager = contextManager
        self.env = env
        self.orcaSwap = orcaSwap
        self.feeRelayer = feeRelayer
        self.feeRelayerAPIClient = feeRelayerAPIClient
        self.solanaAPIClient = solanaAPIClient
    }

    // MARK: - Methods

    public func load() async throws {
        _ = try await(
            orcaSwap.load(),
            contextManager.update()
        )
    }

    // MARK: - Fees calculator

    public func getFees(
        from wallet: Wallet,
        receiver: String,
        payingTokenMint: String?
    ) async throws -> FeeAmount? {
        try await load()
        return try await getFeeViaRelayMethod(
            try await contextManager.getCurrentContext(),
            from: wallet,
            receiver: receiver,
            payingTokenMint: payingTokenMint
        )

    }

    public func getFeesInPayingToken(
        feeInSOL: FeeAmount,
        payingFeeToken: Token
    ) async throws -> FeeAmount? {
        if payingFeeToken.address == PublicKey.wrappedSOLMint.base58EncodedString {
            return feeInSOL
        }

        return try await feeRelayer.feeCalculator.calculateFeeInPayingToken(
            orcaSwap: orcaSwap,
            feeInSOL: feeInSOL,
            payingFeeTokenMint: try PublicKey(string: payingFeeToken.address)
        )
    }

    public func getFreeTransactionFeeLimit() async throws -> UsageStatus {
        try await contextManager.getCurrentContext().usageStatus
    }
}

extension SendFeeCalculatorImpl {
    func getFeeViaRelayMethod(
        _ context: FeeRelayerContext,
        from wallet: Wallet,
        receiver: String,
        payingTokenMint: String?
    ) async throws -> FeeAmount? {
        var transactionFee: UInt64 = 0

        // owner's signature
        transactionFee += context.lamportsPerSignature

        // feePayer's signature
        transactionFee += context.lamportsPerSignature

        let isAssociatedTokenUnregister: Bool
        if wallet.token.address == PublicKey.wrappedSOLMint.base58EncodedString {
            isAssociatedTokenUnregister = false
        } else {
            let destinationInfo = try await solanaAPIClient.findSPLTokenDestinationAddress(
                mintAddress: wallet.token.address,
                destinationAddress: receiver
            )
            isAssociatedTokenUnregister = destinationInfo.isUnregisteredAsocciatedToken
        }

        // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
        if isFreeTransactionNotAvailableAndUserIsPayingWithSOL(context, payingTokenMint: payingTokenMint) {
            // subtract the fee payer signature cost
            transactionFee -= context.lamportsPerSignature
        }

        let expectedFee = FeeAmount(
            transaction: transactionFee,
            accountBalances: isAssociatedTokenUnregister ? context.minimumTokenAccountBalance : 0
        )

        // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
        if isFreeTransactionNotAvailableAndUserIsPayingWithSOL(context, payingTokenMint: payingTokenMint) {
            return expectedFee
        }

        return try await feeRelayer.feeCalculator.calculateNeededTopUpAmount(
            context,
            expectedFee: expectedFee,
            payingTokenMint: try? PublicKey(string: payingTokenMint)
        )
    }

    private func getPayingFeeToken(payingFeeWallet: Wallet?) throws -> FeeRelayerSwift.TokenAccount? {
        if let payingFeeWallet = payingFeeWallet {
            guard
                let addressString = payingFeeWallet.pubkey,
                let address = try? PublicKey(string: addressString),
                let mintAddress = try? PublicKey(string: payingFeeWallet.token.address)
            else {
                throw SendFeeCalculatorError.invalidPayingFeeWallet
            }
            return .init(address: address, mint: mintAddress)
        }
        return nil
    }

    private func isFreeTransactionNotAvailableAndUserIsPayingWithSOL(
        _ context: FeeRelayerContext,
        payingTokenMint: String?
    ) -> Bool {
        let expectedTransactionFee = context.lamportsPerSignature * 2
        return payingTokenMint == PublicKey.wrappedSOLMint.base58EncodedString &&
            context.usageStatus.isFreeTransactionFeeAvailable(transactionFee: expectedTransactionFee) == false
    }
}

public enum SendFeeCalculatorError: String, Swift.Error, LocalizedError {
    case invalidPayingFeeWallet = "Paying fee wallet is not valid"
    case unknown = "Unknown error"

    public var errorDescription: String? {
        // swiftlint:disable swiftgen_strings
        NSLocalizedString(rawValue, comment: "")
        // swiftlint:enable swiftgen_strings
    }
}
