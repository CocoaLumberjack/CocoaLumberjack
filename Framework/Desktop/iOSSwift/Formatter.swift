//
//  Formatter.swift
//  Lumberjack
//
//  Created by C.W. Betts on 10/3/14.
//
//

import Foundation
import CocoaLumberjack.DDDispatchQueueLogFormatter

class Formatter: DDDispatchQueueLogFormatter, DDLogFormatter {
    let threadUnsafeDateFormatter: NSDateFormatter
    
    override init() {
        threadUnsafeDateFormatter = NSDateFormatter()
        threadUnsafeDateFormatter.formatterBehavior = .Behavior10_4
        threadUnsafeDateFormatter.dateFormat = "HH:mm:ss.SSS"
        
        super.init()
    }
    
    override func formatLogMessage(logMessage: DDLogMessage!) -> String {
        let dateAndTime = threadUnsafeDateFormatter.stringFromDate(logMessage.timestamp)
        
        var logLevel: String
        let logFlag = logMessage.flag
        if logFlag & .Error == .Error {
            logLevel = "E"
        } else if logFlag & .Warning == .Warning {
            logLevel = "W"
        } else if logFlag & .Info == .Info {
            logLevel = "I"
        } else if logFlag & .Debug == .Debug {
            logLevel = "D"
        } else if logFlag & .Verbose == .Verbose {
            logLevel = "V"
        } else {
            logLevel = "?"
        }
        
        let formattedLog = "\(dateAndTime) |\(logLevel)| [\(logMessage.fileName) \(logMessage.function)] #\(logMessage.line): \(logMessage.message)"
        
        return formattedLog;
    }
}
