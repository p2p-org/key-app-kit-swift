import Foundation
import SolanaSwift

public enum JupiterSwapError: Swift.Error, Equatable {
    case amountFromIsZero
    case fromAndToTokenAreEqual

    case notEnoughFromToken
    case inputTooHigh(maxLamports: Lamports) // FIXME: - NativeSOL case
}
