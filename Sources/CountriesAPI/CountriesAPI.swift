import Foundation

public protocol CountriesAPI {
    func fetchCountries() async throws -> Countries
}

public final class CountriesAPIImpl: CountriesAPI {
    public init() {}

    public func fetchCountries() async throws -> Countries {
        try await Task {
            let b: Bundle
            #if SWIFT_PACKAGE
            b = Bundle.module
            #else
            b = Bundle(for: Self.self)
            #endif
            let url = b.url(forResource: "countries_2", withExtension: "json")!
            try Task.checkCancellation()
            let data = try Data(contentsOf: url)
            let countries = try JSONDecoder().decode(Countries.self, from: data)
                .filter { !$0.dialCode.isEmpty }
                .filter { $0.status == .assigned || $0.status == .userAssigned }
            try Task.checkCancellation()
            return countries
        }.value
    }
}
