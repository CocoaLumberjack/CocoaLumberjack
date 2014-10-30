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

let ourLogLevel = DDLogLevel.Verbose

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet weak var window: NSWindow!
    
	func applicationDidFinishLaunching(aNotification: NSNotification?) {
        DDLog.addLogger(DDTTYLogger.sharedInstance())
		
        DDLogVerbose("Verbose");
        DDLogInfo("Info");
        DDLogWarn("Warn");
        DDLogError("Error");
        
        defaultDebugLevel = ourLogLevel
        
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

