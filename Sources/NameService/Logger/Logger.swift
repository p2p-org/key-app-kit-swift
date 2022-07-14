import Foundation

public enum NameServiceLoggerLogLevel: String {
    case info
    case error
    case warning
    case debug
}

public protocol NameServiceLogger {
    func log(event: String, data: String?, logLevel: NameServiceLoggerLogLevel)
}

public class Logger {
    
    private static var loggers: [NameServiceLogger] = []
    
    // MARK: -
    
    static let shared = Logger()
    
    private init() {}
    
    // MARK: -
    
    public static func setLoggers(_ loggers: [NameServiceLogger]) {
        self.loggers = loggers
    }
    
    public static func log(event: String, message: String?, logLevel: NameServiceLoggerLogLevel = .info) {
        loggers.forEach { $0.log(event: event, data: message, logLevel: logLevel) }
    }

}
