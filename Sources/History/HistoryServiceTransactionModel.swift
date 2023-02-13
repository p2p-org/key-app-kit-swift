import Foundation

public struct HistoryTransactionResponse: Codable {
//    public var id: String
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
        var counterparty: Counterparty?
        var tokens: [Token]?
        var fee: [Fee]
        var swapPrograms: [SwapProgram]?
        var voteAccount: VoteAccount?

        enum CodingKeys: String, CodingKey {
            case counterparty
            case tokens
            case fee
            case swapPrograms = "swap_programs"
            case voteAccount = "vote_account"
        }
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

        enum CodingKeys: String, CodingKey {
            case balance = "tokens_balance"
            case info = "tokens_info"
        }
    }

    struct Fee: Codable {
        var type: String
        var amount: String
        var payer: String
        var tokenPrice: String

        enum CodingKeys: String, CodingKey {
            case type = "fee_type"
            case amount = "fee_amount"
            case payer = "fee_payer"
            case tokenPrice = "fee_token_price"
        }
    }

    struct SwapProgram: Codable {
        var address: String
        var name: String?

        enum CodingKeys: String, CodingKey {
            case address = "swap_program_address"
            case name = "swap_program_name"
        }
    }

    struct VoteAccount: Codable {
        var name: String?
        var address: String

        enum CodingKeys: String, CodingKey {
            case name = "name"
            case address = "address"
        }
    }
}

public extension HistoryTransaction.Info.Token {
    struct Balance: Codable {
        var before: String
        var after: String

        enum CodingKeys: String, CodingKey {
            case before = "balance_before"
            case after = "balance_after"
        }
    }

    struct Info: Codable {
        var swapRole: String?
        var mint: String
        var symbol: String?
        var tokenPrice: String
    }
}
