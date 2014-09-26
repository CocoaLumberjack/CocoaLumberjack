//
//  AppDelegate.swift
//  SwiftTest
//
//  Created by C.W. Betts on 9/5/14.
//
//

import Cocoa
import CocoaLumberjack

let ourLogLevel = DDLogLevel.Verbose

class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet weak var window: NSWindow!
    
	func applicationDidFinishLaunching(aNotification: NSNotification?) {
        DDLog.addLogger(DDTTYLogger.sharedInstance())
		
        SwiftLogMacro(false, level: ourLogLevel, flag: DDLogFlag.Debug, "Hello")
        DDLogVerbose("Verbose");
        DDLogInfo("Info");
        DDLogWarn("Warn");
        DDLogError("Error");
        
        DDLogVerbose("Verbose", level: ourLogLevel);
        DDLogInfo("Info", level: ourLogLevel);
        DDLogWarn("Warn", level: ourLogLevel);
        DDLogError("Error", level: ourLogLevel);
        
        DDLogError("Error %i", level: ourLogLevel, args: 5);
    }

	func applicationWillTerminate(aNotification: NSNotification?) {
		// Insert code here to tear down your application
	}
}

