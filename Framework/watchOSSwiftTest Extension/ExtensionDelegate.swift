//
//  ExtensionDelegate.swift
//  watchOSSwiftTest Extension
//
//  Created by Sinoru on 2015. 8. 19..
//
//

import WatchKit
import CocoaLumberjack
import CocoaLumberjackSwift

let ddloglevel = DDLogLevel.verbose

private func printSomething() {
    DDLogVerbose("Verbose");
    DDLogDebug("Debug");
    DDLogInfo("Info");
    DDLogWarn("Warn");
    DDLogError("Error");
}

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        
        let formatter = Formatter()
        DDTTYLogger.sharedInstance().logFormatter = formatter
        DDLog.add(DDTTYLogger.sharedInstance())
        
        DDLogVerbose("Verbose");
        DDLogDebug("Debug");
        DDLogInfo("Info");
        DDLogWarn("Warn");
        DDLogError("Error");
        
        printSomething()
        
        defaultDebugLevel = ddloglevel
        
        printSomething()
    }
}
