import Foundation

public struct HistoryTransactionResponse: Codable {
    public var id: String
    public var cursor: String?
    public var blockTransactions: [HistoryTransaction]
}

public struct HistoryTransaction: Codable {
    public var txSignature: String
    public var date: Date
    public var status: Status
    public var type: Kind
    public var info: Info
}

public extension HistoryTransaction {
    enum Kind: String, Codable {
        case send
        case receive
        case swap
        case stake = "stake_delegate"
        case unstake
        case createAccount = "create_account"
        case closeAccount = "close_account"
        case burn
        case mint
        case unknown
    }

    enum Status: String, Codable {
        case success
        case failure
    }

    struct Info: Codable {
        var counterparty: Counterparty
        var tokens: [Token]
        var fee: [Fee]
        var swapPrograms: [SwapProgram]
        var voteAccount: String?
    }
}

public extension HistoryTransaction.Info {
    struct Counterparty: Codable {
        var address: String
        var username: String?
    }

    struct Token: Codable {
        var balance: Balance
        var info: Info
    }

    struct Fee: Codable {
        var type: String
        var amount: String
        var payer: String
        var token_price: String
    }

    struct SwapProgram: Codable {
        var address: String
        var name: String?
    }
}

public extension HistoryTransaction.Info.Token {
    struct Balance: Codable {
        var before: String
        var after: String
    }

    struct Info: Codable {
        var swapRole: String?
        var mint: String
        var symbol: String
        var tokenPrice: String
    }
}
