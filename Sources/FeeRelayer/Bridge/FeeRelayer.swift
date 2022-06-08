import Foundation
import FeeRelayerBinary

public class FeeRelayerImpl {
    public init() {}
    
    public func sayHello(name: String) -> String? {
        guard let result = greet("test") else {
            return nil
        }
        
        return String(cString: result)
    }
}
