//
//  AppDelegate.swift
//  SwiftTest
//
//  Created by C.W. Betts on 9/5/14.
//
//

import Cocoa
import CocoaLumberjack
import CocoaLumberjackSwift

let ourLogLevel = DDLogLevel.verbose

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet weak var window: NSWindow!
    
	func applicationDidFinishLaunching(_ aNotification: Notification) {
        DDLog.add(DDTTYLogger.sharedInstance)
		
        defaultDebugLevel = .warning

        DDLogVerbose("Verbose");
        DDLogInfo("Info");
        DDLogWarn("Warn");
        DDLogError("Error");
        
        defaultDebugLevel = ourLogLevel
        
        DDLogVerbose("Verbose");
        DDLogInfo("Info");
        DDLogWarn("Warn");
        DDLogError("Error");
        
        defaultDebugLevel = .off
        
        DDLogVerbose("Verbose", level: ourLogLevel);
        DDLogInfo("Info", level: ourLogLevel);
        DDLogWarn("Warn", level: ourLogLevel);
        DDLogError("Error", level: ourLogLevel);
        
        DDLogError("Error \(5)", level: ourLogLevel);
        
        defaultDebugLevel = .verbose
        
        let aDDLogInstance = DDLog()
        aDDLogInstance.add(DDTTYLogger.sharedInstance)
        
        DDLogVerbose("Verbose from aDDLogInstance", ddlog: aDDLogInstance)
        DDLogInfo("Info from aDDLogInstance", ddlog: aDDLogInstance)
        DDLogWarn("Warn from aDDLogInstance", ddlog: aDDLogInstance)
        DDLogError("Error from aDDLogInstance", ddlog: aDDLogInstance)
    }

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
}

