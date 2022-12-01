import Foundation
import NameService

extension RecipientSearchServiceImpl {
    /// Search by name
    func searchByName(_ input: String, env: UserWalletEnvironments) async -> RecipientSearchResult {
        do {
            let records: [NameRecord] = try await nameService.getOwners(input)
            let recipients: [Recipient] = records.map { record in
                let (name, domain) = UsernameUtils.splitIntoNameAndDomain(rawName: record.name ?? "")
                
                return .init(
                    address: record.owner,
                    category: .username(name: name, domain: domain),
                    attributes: []
                )
            }
            
            return .ok(recipients)
        } catch {
            debugPrint(error)
            return .nameServiceError(error as NSError)
        }
    }
}
