import Foundation
import Jupiter

extension Route {
    public var id: String {
        marketInfos.map(\.id).joined()
    }
}
