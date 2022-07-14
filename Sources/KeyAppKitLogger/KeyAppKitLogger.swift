import Foundation

public enum KeyAppKitLoggerLogLevel: String {
    case info
    case error
    case warning
    case debug
}

public protocol KeyAppKitLogger {
    func log(event: String, data: String?, logLevel: KeyAppKitLoggerLogLevel)
}

public class Logger {
    
    private static var loggers: [KeyAppKitLogger] = []
    
    // MARK: -
    
    static let shared = Logger()
    
    private init() {}
    
    // MARK: -
    
    public static func setLoggers(_ loggers: [KeyAppKitLogger]) {
        self.loggers = loggers
    }
    
    public static func log(event: String, message: String?, logLevel: KeyAppKitLoggerLogLevel = .info) {
        loggers.forEach { $0.log(event: event, data: message, logLevel: logLevel) }
    }

}
