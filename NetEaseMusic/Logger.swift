//
//  Logger.swift
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import Darwin
import UIKit

internal protocol Logport {}
internal extension Logport {
    
    /// Get the current class the logger.
    var logger: Logger {
        return type(of: self).logger
    }
    
    /// Get the current class the logger.
    static var logger: Logger {
        return Logger(class: self)
    }
}

internal extension NSObjectProtocol {
    
    /// Get the current class the logger
    var logger: Logger {
        return type(of: self).logger
    }
    
    /// Get the current class the logger
    static var logger: Logger {
        return Logger(class: self)
    }
}

internal let logger = Logger()
internal class Logger {
    
    internal enum Priority: Int, CustomStringConvertible, Comparable {
        
        /// The ALL has the lowest possible rank and is intended to turn on all logging.
        case all
        /// The TRACE Level designates finer-grained informational events than the DEBUG
        case trace
        /// The DEBUG Level designates fine-grained informational events that are most useful to debug an application.
        case debug
        /// The INFO level designates informational messages that highlight the progress of the application at coarse-grained level.
        case info
        /// The WARN level designates potentially harmful situations.
        case warn
        /// The ERROR level designates error events that might still allow the application to continue running.
        case error
        /// The FATAL level designates very severe error events that will presumably lead the application to abort.
        case fatal
        /// The OFF has the highest possible rank and is intended to turn off logging.
        case off
        
        ///
        /// A textual representation of this instance.
        ///
        /// Instead of accessing this property directly, convert an instance of any
        /// type to a string by using the `String(describing:)` initializer. For
        ///
        internal var description: String {
            switch self {
            case .all: return "ALL"
            case .trace: return "TRACE"
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warn: return "WARN"
            case .error: return "ERROR"
            case .fatal: return "FATAL"
            case .off: return "OFF"
            }
        }
        
        ///
        /// Returns a Boolean value indicating whether the value of the first
        /// argument is less than that of the second argument.
        ///
        /// This function is the only requirement of the `Comparable` protocol. The
        /// remainder of the relational operator functions are implemented by the
        /// standard library for any type that conforms to `Comparable`.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        ///
        internal static func <(lhs: Logger.Priority, rhs: Logger.Priority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
        ///
        /// Create priority with name
        ///
        /// - Parameters:
        ///   - name: the priority string name
        ///
        internal init?(name: String) {
            switch name.uppercased() {
            case "ALL": self = .all
            case "TRACE": self = .trace
            case "DEBUG": self = .debug
            case "INFO": self = .info
            case "WARN": self = .warn
            case "ERROR": self = .error
            case "FATAL": self = .fatal
            case "OFF": self = .off
            default: return nil
            }
        }
    }
    
    internal class Log {
        
        internal init(`class`: String, priority: Priority) {
            self.class = `class`
            self.priority = priority
        }
        internal let `class`: String
        internal let `priority`: Priority
        
        internal var date: Date = .init()
        internal var line: Int = 0
        
        internal var thread: mach_port_t = 0
        internal var synchronous: Bool = false
        
        internal var fileName: String = ""
        internal var file: String = "" {
            willSet {
                fileName = (newValue as NSString).lastPathComponent
            }
        }
        
        internal var method: String = ""
        internal var message: String = ""
    }
    internal class Layout {
        ///
        /// Create a forrmater.
        ///
        /// - Parameter format: %[algin][min].[max][command]{attachment}
        ///
        internal init(pattern: String) {
            // Create a regular expression parsing.
            let length = pattern.lengthOfBytes(using: .utf8)
            let regex = try? NSRegularExpression(pattern: "%(-?\\d*(?:\\.\\d+)?)([cCdDFlLmMnprt])(?:(?<=d)\\{([^}]+)\\})?")
            // Fetch matching results.
            let format = NSMutableString(string: pattern)
            let results = regex?.matches(in: pattern, options: .withoutAnchoringBounds, range: .init(location: 0, length: length)) ?? []
            // Convert result to node.
            // Note: Must be from the front after processing order
            _format = format
            _nodes = results.reversed().map {
                // Get sub string.
                func substr(_ str: NSString, with range: NSRange) -> String? {
                    guard range.location != NSNotFound else {
                        return nil
                    }
                    return str.substring(with: range)
                }
                // 0: all, 1:limit, 2:cmd: 3:att
                let node = Node()
                
                // Get base.
                node.format = substr(format, with: $0.range) ?? ""
                node.command = substr(format, with: $0.range(at: 2)) ?? ""
                // Get attachment.
                node.attachment = substr(format, with: $0.range(at: 3))
                
                // Update the format.
                format.replaceCharacters(in: $0.range, with: "%\(substr(format, with: $0.range(at: 1)) ?? "")S")
                
                return node
            }.reversed()
        }
        /// Use the log format string.
        internal func format(with log: Log) -> String {
            // The format string, note: that you should hold the array to use pointer
            let parameters = _nodes.map({ $0.format(with: log) + "\0\0" })
            // Convert a string to CVarArg.
            return .init(format: (_format as String), arguments: parameters.map {
                return ($0 as NSString).cString(using: String.Encoding.utf16.rawValue)!
            })
        }
        
        private let _format: NSString
        private let _nodes: Array<Node>
        
        private class Node {
            
            var format: String = ""
            var command: String = ""
            var attachment: String?
            
            func format(with log: Log) -> String {
                switch command {
                    
                case "r":
                    // The number of milliseconds the output takes from application startup to output the log information.
                    return "\(ProcessInfo().systemUptime)"
                    
                case "t":
                    // Output the thread name that produced the log event.
                    return "\(log.thread)"
                    
                case "d":
                    // Get the log date, if no specify output format default with ISO8601.
                    guard let dateFormat = attachment else {
                        return type(of: self).formatter.string(from: log.date)
                    }
                    let formatter = DateFormatter()
                    formatter.dateFormat = dateFormat
                    return formatter.string(from: log.date)
                    
                case "D":
                    // Get the deveice info.
                    return "\(type(of: self).machine)/\(UIDevice.current.systemVersion)"

                case "p":
                    // Get the log priority info.
                    return log.priority.description
                    
                case "m":
                    // Get the current log contents.
                    return log.message
                    
                case "n":
                    // Output a carriage newline characters, Windows platform is "\r\n", Unix platform is "\n".
                    return "\n"
                    
                case "F":
                    // The name of the file when log generated.
                    return log.fileName
                    
                case "L":
                    // The line number of the file when log generated.
                    return "\(log.line)"
                    
                case "C", "c":
                    // The class description when log generated.
                    return log.class
                    
                case "M":
                    // The method description when log generated.
                    return log.method
                    
                case "l":
                    // The location when log generated.
                    // It equivalent "%C.%M(%F:%L)"
                    return "\(log.class).\(log.method) at \(log.fileName):\(log.line)"
                    
                default:
                    // Unknow paramters.
                    return "<Unknow>"
                }
            }
            
            /// Generate the default date formatter.
            static var formatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss,SSS"
                return formatter
            }()
            
            /// Get the current machine model.
            static var machine: String = {
                var info = utsname()
                uname(&info)
                let machine = NSString(bytes: &info.machine,
                                       length: MemoryLayout.size(ofValue: info.machine),
                                       encoding: String.Encoding.utf8.rawValue)
                
                // Delete the redundant \0.
                return (machine?.utf8String).map {
                    return String(cString: $0)
                } ?? "Unknow"
            }()
        }
    }
    internal class Writeable {
        
        internal init(class: String, priority: Priority) {
            _class = `class`
            _priority = `priority`
        }
        
        // This is the most generic printing method.
        internal func write(_ items: Any..., method: String = #function, file: String = #file, line: Int = #line, synchronous: Bool = false) {
            _write(items, method: method, file: file, line: line, synchronous: synchronous)
        }
        
        private func _write(_ items: [Any], method: String, file: String, line: Int, synchronous: Bool) {
            // Collect the log information.
            let log = Log(class: _class, priority: _priority)
            log.thread = mach_thread_self()
            log.synchronous = synchronous
            log.file = file
            log.line = line
            log.method = method
            log.message = items.reduce(nil) {
                $0?.appending(", \($1)") ?? "\($1)"
            } ?? ""
            // Output.
            Logger.appender.forEach {
                // Check the output priority.
                guard log.priority >= $0.threshold else {
                    return
                }
                $0.write(log)
            }
        }
        
        private var _class: String
        private var _priority: Priority
    }
    internal class Appender {
        
        /// Create a empty appender.
        internal init(name: String, pattern: String = "%m%n", threshold: Priority = .all) {
            self.name = name
            self.pattern = pattern
            self.threshold = threshold
        }
        
        /// Create a appender for encoded data.
        internal init?(coder: NSCoder) {
            // Read the appender the name.
            guard let name = coder.decodeObject(forKey: "name") as? String else {
                return nil
            }
            // Read the appender the pattern.
            guard let pattern = coder.decodeObject(forKey: "pattern") as? String else {
                return nil
            }
            // Read the appender the threshold.
            guard let threshold = Priority(name: coder.decodeObject(forKey: "threshold") as? String ?? "") else {
                return nil
            }
            // Configure.
            self.name = name
            self.pattern = pattern
            self.threshold = threshold
        }
        
        /// Dispatch a log task.
        internal func dispatch(_ parameter: Logger.Log, task: @escaping () -> Void) {
            switch parameter.synchronous  {
            case true:
                self.tasks.sync(execute: task)

            case false:
                self.tasks.async(execute: task)
            }
        }
        
        /// Write a log mssage to descriptor.
        internal func write(_ parameter: Logger.Log) {
            // Generate log message content.
            self.dispatch(parameter) {
                self.write(self.layout.format(with: parameter))
            }
        }
        
        /// Write a log mssage to descriptor.
        internal func write(_ contents: String) {
            // Notiing
        }
        
        
        /// The appender name.
        internal let name: String
        /// The appender pattern , default is "%m%n".
        internal let pattern: String
        /// The appender threshold, default is Priority.all.
        internal let threshold: Priority
        
        
        /// The appender tasks queue.
        internal lazy var tasks: DispatchQueue = resuable(label: "logger.appender.\(self.name)", qos: .background)

        /// Creating a layout is a very resource consuming
        internal lazy var layout: Layout = Layout(pattern: self.pattern)
        
        
        /// Write log messages to descriptor.
        internal class Stream: Appender {
            
            /// Create a appender with descriptor.
            init(descriptor: Int32, name: String, pattern: String = "%m%n", threshold: Priority = .all) {
                self.descriptor = descriptor
                super.init(name: name, pattern: pattern, threshold: threshold)
            }
            
            /// Write a log contents to descriptor.
            override func write(_ contents: String) {
                // Write the log message to descriptor.
                Darwin.write(self.descriptor, contents, contents.lengthOfBytes(using: .utf8))
                
                // Synchronize descriptor data to the device.
                Darwin.fsync(self.descriptor)
            }
            
            /// This is a opened descriptor.
            var descriptor: Int32
        }
        
        /// Write log messages to console.
        internal class Console: Stream {
            
            // Create a appender with stdout descriptor.
            init(threshold: Priority = .all) {
                super.init(descriptor: fileno(stdout), name: "stdout", pattern: "[%-5p] %C.%M: %m%n", threshold: threshold)
            }
            
            /// Dispatch a log task.
            override func dispatch(_ parameter: Logger.Log, task: @escaping () -> Void) {
                #if DEBUG
                self.tasks.sync(execute: task)
                #else
                super.dispatch(parameter, task: task)
                #endif
            }

        }
        
        /// Write log messages to file.
        internal class File: Stream {
            
            /// Create a appender with specified file.
            internal init(file: String = "verbose.log", threshold: Priority = .all) {
                // Create a file in temporary.
                let file = fopen("\(NSTemporaryDirectory())/\(file)", "w")
                
                self.file = file
                super.init(descriptor: fileno(file), name: "file", pattern: "%d [%-5p] %l: %m%n", threshold: threshold)
            }
            
            /// Clear all opened resources.
            deinit {
                // Close a opened file.
                self.file.map {
                    _ = fclose($0)
                }
            }
            
            var file: UnsafeMutablePointer<FILE>?
        }
        
        /// Write log messages to remote server.
        internal class Remote: Stream {
            
            // Create a appender with specified server.
            internal init(server: String, port: Int, threshold: Priority = .all) {
                var address = sockaddr_in()
                
                address.sin_family = sa_family_t(AF_INET)
                address.sin_addr.s_addr = inet_addr(server)
                address.sin_port = in_port_t(port).bigEndian
                
                self.address = address
                super.init(descriptor: socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP), name: "remote", pattern: "%d %D [%-5p] %l: %m%n", threshold: threshold)
            }
            
            /// Clear all opened resources.
            deinit {
                // Close a opened socket.
                guard descriptor > 0 else {
                    return
                }
                close(descriptor)
            }
            
            /// Write a log mssage to descriptor.
            override func write(_ contents: String) {
                // Network access must be initiated first.
                auth()
                
                // If the conversion fails, no writes are allowed.
                guard let ptr = (contents as NSString).utf8String else {
                    return
                }
                
                // Send data to the remote server.
                withUnsafeBytes(of: &address) {
                    
                    // Gets the address.
                    let size = $0.count
                    let address = $0.bindMemory(to: sockaddr.self)
                    
                    // Gets the contents pointer and length.
                    let length = strlen(ptr)
                    
                    var sent = 0
                    while sent < length {
                        // Incremental send data to remore.
                        let count = sendto(descriptor, ptr.advanced(by: sent), min(.init(length) - .init(sent), 1024), 0, address.baseAddress, .init(size))
                        
                        // Check if it has been written successfully.
                        guard count > 0 else {
                            return
                        }
                        
                        sent += count
                    }
                }
            }
            
            // Request network access auth.
            func auth() {
                guard !authed else {
                    return
                }
                authed = true
                
                // Send a http request.
                URLSession.shared.dataTask(with: URL(string: "http://baidu.com")!).resume()
            }


            var authed: Bool = false
            var address: sockaddr_in
        }
    }
    
    fileprivate init() {
        _name = ""
    }
    fileprivate init(class: Any.Type) {
        _name = "\(`class`)"
    }
    
    fileprivate let _name: String
    fileprivate func _logger(_ priority: Priority) -> Writeable? {
        // The level is enabled?
        guard priority >= Logger.threshold else {
            return nil
        }
        // Generate a bridge object.
        return Writeable(class: _name, priority: priority)
    }
    
    internal var trace: Writeable? {
        return _logger(.trace)
    }
    internal var debug: Writeable? {
        return _logger(.debug)
    }
    internal var info: Writeable? {
        return _logger(.info)
    }
    internal var warning: Writeable? {
        return _logger(.warn)
    }
    internal var error: Writeable? {
        return _logger(.error)
    }
    internal var fatal: Writeable? {
        return _logger(.fatal)
    }
    
    internal static var threshold: Priority = Logger.appender.reduce(.off) {
        guard $1.threshold < $0 else {
            return $0
        }
        return $1.threshold
    }
    
    #if DEBUG
    internal static var appender: Array<Appender> = [
        Appender.File(threshold: .debug),
        Appender.Console(threshold: .all),
        //Appender.Remote(server: "114.215.139.138", port: 514, threshold: .all),
    ]
    #else
    internal static var appender: Array<Appender> = [
        Appender.File(threshold: .debug),
        Appender.Console(threshold: .info),
        Appender.Remote(server: "114.215.139.138", port: 514, threshold: .all),
    ]
    #endif
}

/// Writeer
fileprivate var handler = NSGetUncaughtExceptionHandler()
fileprivate var handlers = Dictionary<Int32, (Int32) -> ()>()
fileprivate func resuable(label: String, qos: DispatchQoS = .default) -> DispatchQueue {
    // Lock the funcation.
    objc_sync_enter(DispatchQueue.self)
    defer {
        objc_sync_exit(DispatchQueue.self)
    }

    // Create a mapper for queue.
    let ptr = UnsafeRawPointer(bitPattern: ~0x69236523)!
    let queues = (objc_getAssociatedObject(DispatchQueue.self, ptr) as? NSMutableDictionary) ?? {
        let queues = NSMutableDictionary(capacity: 8)
        objc_setAssociatedObject(DispatchQueue.self, ptr, queues, .OBJC_ASSOCIATION_RETAIN)
        
//        // Set Objective-C Object Exception Handler.
//        handler = NSGetUncaughtExceptionHandler()
//        NSSetUncaughtExceptionHandler {
//            // Collect the expection information.
//            let symobls = $0.callStackSymbols as NSArray
//            let reason = $0.reason ?? "Unknow reason"
//            let name = $0.name.rawValue
//
//            // Output exception information.
//            Logger(class: Logger.self).fatal?.write("\nname: \(name)\nreason: \(reason)\nstack: \(symobls)\n", method: "uncaughtExceptionHandler", synchronous: true)
//            
//            // Move to next handler.
//            handler?($0)
//        }
//        
//        // Set Unix Signal Exception Handler.
//        [SIGHUP, SIGINT, SIGQUIT, SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE].forEach {
//            handlers[$0] = signal($0) {
//                // Collect stack information.
//                let reason = String(cString: strsignal($0))
//                let buffer = UnsafeMutableBufferPointer<UnsafeRawPointer>.allocate(capacity: 1024)
//                let count = backtrace(buffer, buffer.count)
//                let symobls = backtrace_symbols(buffer, count).map { buffer in
//                    return NSArray(array: (0 ..< count).map {
//                        return String(cString: buffer[$0])
//                    })
//                } ?? []
//                
//                // Output exception information.
//                Logger(class: Logger.self).fatal?.write("\nreason: \(reason)\nsymobls: \(symobls)\n", method: "uncaughtSignalExceptionHandler", synchronous: true)
//
//                // Move to next handler.
//                handlers[$0]?($0)
//                signal($0, SIG_DFL)
//                handlers[$0] = nil
//            }
//        }
        
        return queues
    }()

    // The queue is created?
    if let object = queues[label] as? DispatchQueue {
        return object
    }
    
    // Generate an new queue.
    let object = DispatchQueue(label: label, qos: qos)
    queues[label] = object
    return object
}

// Forward Declaration.
@_silgen_name("backtrace") fileprivate func backtrace(_ array: UnsafeMutableBufferPointer<UnsafeRawPointer>, _ size: Int) -> Int
@_silgen_name("backtrace_symbols") fileprivate func backtrace_symbols(_ array: UnsafeMutableBufferPointer<UnsafeRawPointer>, _ size: Int) -> UnsafeBufferPointer<UnsafePointer<Int8>>?
