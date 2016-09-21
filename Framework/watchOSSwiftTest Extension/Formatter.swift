//
//  Formatter.swift
//  Lumberjack
//
//  Created by C.W. Betts on 10/3/14.
//
//

import Foundation
import CocoaLumberjack.DDDispatchQueueLogFormatter

class Formatter: DDDispatchQueueLogFormatter {
    let threadUnsafeDateFormatter: DateFormatter
    
    override init() {
        threadUnsafeDateFormatter = DateFormatter()
        threadUnsafeDateFormatter.formatterBehavior = .behavior10_4
        threadUnsafeDateFormatter.dateFormat = "HH:mm:ss.SSS"
        
        super.init()
    }
    
    override func format(message logMessage: DDLogMessage!) -> String {
        let dateAndTime = threadUnsafeDateFormatter.string(from: logMessage.timestamp)
        
        var logLevel: String
        let logFlag = logMessage.flag
        if logFlag.contains(.error) {
            logLevel = "E"
        } else if logFlag.contains(.warning){
            logLevel = "W"
        } else if logFlag.contains(.info) {
            logLevel = "I"
        } else if logFlag.contains(.debug) {
            logLevel = "D"
        } else if logFlag.contains(.verbose) {
            logLevel = "V"
        } else {
            logLevel = "?"
        }
        
        let formattedLog = "\(dateAndTime) |\(logLevel)| [\(logMessage.fileName) \(logMessage.function)] #\(logMessage.line): \(logMessage.message)"
        
        return formattedLog;
    }
}
