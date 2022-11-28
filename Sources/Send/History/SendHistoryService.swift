// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import History
import NameService
import SolanaSwift
import TransactionParser

public protocol SendHistoryProvider {
    func getRecipients(_ count: Int) async throws -> [Recipient]
    func save(_ transactions: [Recipient]) async throws
}

public class SendHistoryRemoteMockProvider: SendHistoryProvider {
    let recipients: [Recipient]

    public init(recipients: [Recipient]) { self.recipients = recipients }

    public func getRecipients(
        _: Int
    ) async throws -> [Recipient] { recipients }

    public func save(_: [Recipient]) async throws {}
}

public class SendHistoryRemoteProvider: SendHistoryProvider {
    private let sourceStream: HistoryStreamSource
    private let historyTransactionParser: TransactionParsedRepository
    private let solanaAPIClient: SolanaAPIClient
    private let nameService: NameService

    public init(
        sourceStream: HistoryStreamSource,
        historyTransactionParser: TransactionParsedRepository,
        solanaAPIClient: SolanaAPIClient,
        nameService: NameService
    ) {
        self.sourceStream = sourceStream
        self.historyTransactionParser = historyTransactionParser
        self.solanaAPIClient = solanaAPIClient
        self.nameService = nameService
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
        let parsedTransactions: [ParsedTransaction] = try await getTransactions(count)

        var result: [Recipient] = []

        for parsedTransaction in parsedTransactions {
            guard
                let info = parsedTransaction.info as? TransferInfo,
                info.transferType == .send,
                let address = info.destinationAuthority ?? info.destination?.pubkey,
                !result.contains(where: { $0.address == address })
            else {
                continue
            }

            let rawName = try? await nameService.getName(address)
            let (name, domain) = UsernameUtils.splitIntoNameAndDomain(rawName: rawName ?? "")

            let recipient = Recipient(
                address: address,
                category: rawName != nil ? .username(name: name, domain: domain) : .solanaAddress,
                attributes: [],
                createdData: parsedTransaction.blockTime ?? Date()
            )

            result.append(recipient)
        }

        return result
    }

    public func save(_: [Recipient]) async throws {}
}

public class SendHistoryService: ObservableObject {
    public enum Status {
        case ready
        case loading
    }

    private let statusSubject: CurrentValueSubject<Status, Never> = .init(.loading)
    public var statusPublisher: AnyPublisher<Status, Never> { statusSubject.eraseToAnyPublisher() }

    private let recipientsSubject: CurrentValueSubject<[Recipient], Never> = .init([])
    public var recipientsPublisher: AnyPublisher<[Recipient], Never> { recipientsSubject.eraseToAnyPublisher() }

    private let errorSubject: CurrentValueSubject<Error?, Never> = .init(nil)
    public var errorPublisher: AnyPublisher<Error?, Never> { errorSubject.eraseToAnyPublisher() }

    private let localProvider: SendHistoryProvider
    private var remoteProvider: SendHistoryProvider

    private let fetchCount: Int = 50

    public init(localProvider: SendHistoryProvider, remoteProvider: SendHistoryProvider) {
        self.localProvider = localProvider
        self.remoteProvider = remoteProvider

        Task { await initialize() }
    }

    public func initialize() async {
        do {
            statusSubject.send(.loading)
            defer { statusSubject.send(.ready) }

            let recipients = try await localProvider.getRecipients(fetchCount)
            recipientsSubject.send(recipients)
        } catch {
            debugPrint(error)
            errorSubject.send(error)
        }
    }

    public func synchronize(updateRemoteProvider: SendHistoryProvider? = nil) async {
        do {
            statusSubject.send(.loading)
            defer { statusSubject.send(.ready) }

            if let updatedRemoteProvider = updateRemoteProvider {
                remoteProvider = updatedRemoteProvider
            }

            let recipients = try await remoteProvider.getRecipients(fetchCount)

            recipientsSubject.send(recipients)
            try await localProvider.save(recipients)
        } catch {
            debugPrint(error)
            errorSubject.send(error)
        }
    }
}
