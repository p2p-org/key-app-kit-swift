//
// Created by Giang Long Tran on 04.05.2022.
//

import Foundation
import SolanaSwift

extension SolanaAPIClient {
  /// Get account information.
  ///
  /// - Parameters:
  ///   - account: the address of account. If it's nil then the function will return nil immediately.
  ///   - anotherAccount: the second address of account, in case when first ``account`` address can't be solved. Throw exception if can't retrieve address.
  /// - Returns: ``BufferInfo``
  /// - Throws: ``Error.other`` if account can't be solved.
  func getAccountInfo<T: DecodableBufferLayout>(
    account: String?,
    or anotherAccount: String?
  ) async throws -> BufferInfo<T>? {
    guard let account = account else { return nil }
    
    let accountInfo: BufferInfo<T>? = try? await getAccountInfo(account: account)
    if let accountInfo = accountInfo {
      return accountInfo
    } else if let anotherAccount = anotherAccount {
      return try await getAccountInfo(account: anotherAccount)
    } else {
      throw SolanaSDK.Error.other("Could not retrieve account info")
    }
  }
}

