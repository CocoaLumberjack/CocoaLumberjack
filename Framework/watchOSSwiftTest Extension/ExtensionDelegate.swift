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
        DDTTYLogger.sharedInstance.logFormatter = formatter
        DDLog.add(DDTTYLogger.sharedInstance)
        
        DDLogVerbose("Verbose");
        DDLogDebug("Debug");
        DDLogInfo("Info");
        DDLogWarn("Warn");
        DDLogError("Error");
        
        printSomething()
        
        defaultDebugLevel = ddloglevel
        
        printSomething()
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

}
