import SolanaSwift
import OrcaSwapSwift
import FeeRelayerSwift

public protocol SendChooseFeeService {
    func getAvailableWalletsToPayFee(feeInSOL: FeeAmount) async throws -> [Wallet]
}

final class SendChooseFeeServiceImpl: SendChooseFeeService {

    private let orcaSwap: OrcaSwapType
    private let feeRelayer: FeeRelayer
    private let env: UserWalletEnvironments

    init(env: UserWalletEnvironments, feeRelayer: FeeRelayer, orcaSwap: OrcaSwapType) {
        self.env = env
        self.feeRelayer = feeRelayer
        self.orcaSwap = orcaSwap
    }

    public func getAvailableWalletsToPayFee(feeInSOL: FeeAmount) async throws -> [Wallet] {
        try await
            env.wallets
                .filter { ($0.lamports ?? 0) > 0 }
                .asyncMap { wallet -> Wallet? in
                    if wallet.token.address == PublicKey.wrappedSOLMint.base58EncodedString {
                        return (wallet.lamports ?? 0) >= feeInSOL.total ? wallet : nil
                    }

                    let feeAmount = try await self.feeRelayer.feeCalculator.calculateFeeInPayingToken(
                        orcaSwap: self.orcaSwap,
                        feeInSOL: feeInSOL,
                        payingFeeTokenMint: try PublicKey(string: wallet.token.address)
                    )
                    if (feeAmount?.total ?? 0) <= (wallet.lamports ?? 0) {
                        return wallet
                    } else {
                        return nil
                    }
                }
                .compactMap({ $0 })
    }
}
