import SolanaSwift
import OrcaSwapSwift
import FeeRelayerSwift

public protocol SendChooseFeeService {
    func getAvailableWalletsToPayFee(feeInSOL: FeeAmount) async throws -> [Wallet]
}

public final class SendChooseFeeServiceImpl: SendChooseFeeService {

    private let orcaSwap: OrcaSwapType
    private let feeRelayer: FeeRelayer
    private let wallets: [Wallet]
    private let context: RelayContext?

    public init(wallets: [Wallet], feeRelayer: FeeRelayer, orcaSwap: OrcaSwapType, context: RelayContext?) {
        self.wallets = wallets
        self.feeRelayer = feeRelayer
        self.orcaSwap = orcaSwap
        self.context = context
    }

    public func getAvailableWalletsToPayFee(feeInSOL: FeeAmount) async throws -> [Wallet] {
        var filteredWallets = wallets.filter { ($0.lamports ?? 0) > 0 }
        var feeWallets = [Wallet]()
        for element in filteredWallets {
            if element.token.address == PublicKey.wrappedSOLMint.base58EncodedString && (element.lamports ?? 0) >= feeInSOL.total {
                feeWallets.append(element)
                continue
            }
            if element.isNativeSOL, !isValidNative(wallet: element, feeInSOL: feeInSOL) {
                continue
            }
            do {
                let feeAmount = try await self.feeRelayer.feeCalculator.calculateFeeInPayingToken(
                    orcaSwap: self.orcaSwap,
                    feeInSOL: feeInSOL,
                    payingFeeTokenMint: try PublicKey(string: element.token.address)
                )
                if (feeAmount?.total ?? 0) <= (element.lamports ?? 0) {
                    feeWallets.append(element)
                }
            }
            catch let error {
                if (error as? FeeRelayerError) != FeeRelayerError.swapPoolsNotFound {
                    throw error
                }
            }
        }
        
        return feeWallets
    }

    private func isValidNative(wallet: Wallet, feeInSOL: FeeAmount) -> Bool {
        guard let context = context else { return false }
        let leftAmount = (Int64(wallet.lamports ?? 0) - Int64(feeInSOL.total))
        return leftAmount >= Int64(context.minimumRelayAccountBalance) || leftAmount == .zero
    }
}
