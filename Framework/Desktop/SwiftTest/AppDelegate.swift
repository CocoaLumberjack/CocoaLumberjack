//
//  AppDelegate.swift
//  SwiftTest
//
//  Created by C.W. Betts on 9/5/14.
//
//

import Cocoa
import CocoaLumberjack

class AppDelegate: NSObject, NSApplicationDelegate {
                            
	@IBOutlet weak var window: NSWindow!


	func applicationDidFinishLaunching(aNotification: NSNotification?) {
        DDLog.addLogger(DDTTYLogger.sharedInstance())
        
        // These don't work
        //DDLogVerbose("Verbose");
        //DDLogInfo("Info");
        //DDLogWarn("Warn");
        //DDLogError("Error");
	}

	func applicationWillTerminate(aNotification: NSNotification?) {
		// Insert code here to tear down your application
	}


}

