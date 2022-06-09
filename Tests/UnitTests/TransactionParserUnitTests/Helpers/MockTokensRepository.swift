import Foundation
import SolanaSwift

struct MockTokensRepository: SolanaTokensRepository {
    func getTokensList(useCache: Bool) async throws -> Set<Token> {
        let string = #"[{"chainId":101,"address":"2FPyTwcZLUg1MDrwsyoP4D6s1tM7hAkHYRjkNb5w6Pxk","symbol":"soETH","name":"Wrapped Ethereum (Sollet)","decimals":6,"logoURI":"https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/2FPyTwcZLUg1MDrwsyoP4D6s1tM7hAkHYRjkNb5w6Pxk/logo.png","tags":["wrapped-sollet","ethereum"],"extensions":{"bridgeContract":"https://etherscan.io/address/0xeae57ce9cc1984f202e15e038b964bb8bdf7229a","coingeckoId":"ethereum","serumV3Usdc":"4tSvZvnbyzHXLMTiFonMyxZoHmFqau1XArcRCVHLZ5gX","serumV3Usdt":"7dLVkUfBVfCGkFhSXDCq1ukM9usathSgS716t643iFGF"}},{"chainId":101,"address":"BLwTnYKqf7u4qjgZrrsKeNs2EzWkMLqVCu6j8iHyrNA3","symbol":"BOP","name":"Boring Protocol","decimals":8,"logoURI":"https://raw.githubusercontent.com/boringprotocol/brand-assets/main/boplogo.png","tags":["security-token","utility-token"],"extensions":{"coingeckoId":"boring-protocol","serumV3Usdc":"7MmPwD1K56DthW14P1PnWZ4zPCbPWemGs3YggcT1KzsM","twitter":"https://twitter.com/BoringProtocol","website":"https://boringprotocol.io"}}]"#
        let array = try! JSONDecoder().decode([Token].self, from: string.data(using: .utf8)!)
        return Set<Token>(array)
    }
}
