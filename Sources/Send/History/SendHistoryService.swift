// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import History
import SolanaSwift
import TransactionParser

public protocol SendHistoryProvider {
    func getRecipients(_ count: Int) async throws -> [Recipient]
    func save(_ transactions: [Recipient]) async throws
}

public class SendHistoryRemoteProvider: SendHistoryProvider {
    private let sourceStream: HistoryStreamSource
    private let historyTransactionParser: TransactionParsedRepository
    private let solanaAPIClient: SolanaAPIClient

    public init(
        sourceStream: HistoryStreamSource,
        historyTransactionParser: TransactionParsedRepository,
        solanaAPIClient: SolanaAPIClient
    ) {
        self.sourceStream = sourceStream
        self.historyTransactionParser = historyTransactionParser
        self.solanaAPIClient = solanaAPIClient
    }

    private func getSignatures(count: Int) async throws -> [HistoryStreamSource.Result] {
        var results: [HistoryStreamSource.Result] = []
        while true {
            let firstTrx = try await sourceStream.currentItem()
            guard
                let firstTrx = firstTrx,
                let rawTime = firstTrx.0.blockTime
            else {
                return results
            }

            // Fetch next 1 days
            var timeEndFilter = Date(timeIntervalSince1970: TimeInterval(rawTime))
            timeEndFilter = timeEndFilter.addingTimeInterval(-1 * 60 * 60 * 24 * 1)

            if Task.isCancelled { return [] }
            while let result = try await sourceStream.next(configuration: .init(timestampEnd: timeEndFilter)) {
                let (signatureInfo, _, _) = result

                // Skip duplicated transaction
                if results.contains(where: { $0.0.signature == signatureInfo.signature }) { continue }
                results.append(result)

                if results.count > count {
                    return results
                }
            }
        }
    }

    public func getTransactions(_ count: Int) async throws -> [ParsedTransaction] {
        let signatures = try await getSignatures(count: count)
        let transactions: [TransactionInfo?] = try await solanaAPIClient.batchRequest(
            method: "getTransaction",
            params: signatures.map { [$0.signatureInfo.signature, RequestConfiguration(encoding: "jsonParsed")] }
        )

        var parsedTransactions: [ParsedTransaction] = []

        for trxInfo in transactions {
            guard let trxInfo = trxInfo else { continue }
            guard let (signature, account, symbol) = signatures
                .first(where: { (signatureInfo: SignatureInfo, _, _) in
                    signatureInfo.signature == trxInfo.transaction.signatures.first
                }) else { continue }

            parsedTransactions.append(
                await historyTransactionParser.parse(
                    signatureInfo: signature,
                    transactionInfo: trxInfo,
                    account: account,
                    symbol: symbol
                )
            )
        }

        return parsedTransactions
    }

    public func getRecipients(_ count: Int) async throws -> [Recipient] {
        let parsedTransactions = try await getTransactions(count)

        return parsedTransactions
            .map(\.info)
            .compactMap { $0 as? TransferInfo }
            .filter { $0.transferType == .send && $0.destination?.pubkey != nil }
            .map { (info: TransferInfo) in
                Recipient(
                    address: info.destinationAuthority ?? info.destination!.pubkey!,
                    category: .solanaAddress,
                    attributes: []
                )
            }
    }

    public func save(_: [Recipient]) async throws {}
}

public class SendHistoryService: ObservableObject {
    public enum Status {
        case ready
        case loading
    }

    @Published public private(set) var status: Status = .loading
    @Published public private(set) var recipients: [Recipient] = []
    @Published public private(set) var error: Error? = nil

    private let localProvider: SendHistoryProvider
    private var remoteProvider: SendHistoryProvider

    private let fetchCount: Int = 50

    public init(localProvider: SendHistoryProvider, remoteProvider: SendHistoryProvider) {
        self.localProvider = localProvider
        self.remoteProvider = remoteProvider

        Task { await initialize() }
    }

    func initialize(updateRemoteProvider: SendHistoryProvider? = nil) async {
        do {
            status = .loading
            defer { status = .ready }

            if let updatedRemoteProvider = updateRemoteProvider {
                remoteProvider = updatedRemoteProvider
            }

            recipients = try await localProvider.getRecipients(fetchCount)
        } catch {
            debugPrint(error)
            self.error = error
        }
    }

    public func synchronize() async {
        do {
            status = .loading
            defer { status = .ready }

            recipients = try await remoteProvider.getRecipients(fetchCount)
            try await localProvider.save(recipients)
        } catch {
            debugPrint(error)
            self.error = error
        }
    }
}
