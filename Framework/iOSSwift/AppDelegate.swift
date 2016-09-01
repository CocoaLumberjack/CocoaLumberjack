//
//  AppDelegate.swift
//  iOSSwift
//
//  Created by C.W. Betts on 10/3/14.
//
//

import UIKit
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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		// Override point for customization after application launch.
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
        
		return true
	}
}

