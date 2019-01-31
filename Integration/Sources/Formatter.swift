// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2019, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
//   to endorse or promote products derived from this software without specific
//   prior written permission of Deusty, LLC.

import Foundation
import CocoaLumberjackSwift

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
        
        let logLevel: String
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
        
        return formattedLog
    }
}
