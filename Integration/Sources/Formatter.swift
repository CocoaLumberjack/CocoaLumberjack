//
//  Formatter.swift
//  Integration
//
//  Created by Dmitry Lobanov on 18.10.2018.
//  Copyright © 2018 CocoaLumberjack. All rights reserved.
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
    
    override func format(message logMessage: DDLogMessage) -> String {
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
        
        let formattedLog = "\(dateAndTime) |\(logLevel)| [\(logMessage.fileName) \(logMessage.function ?? "nil")] #\(logMessage.line): \(logMessage.message)"
        
        return formattedLog;
    }
}
