//
//  AppDelegate.swift
//  macOSSwiftIntegration
//
//  Created by Dmitry Lobanov on 16.10.2018.
//  Copyright © 2018 Dmitry Lobanov. All rights reserved.
//

import Cocoa

import CocoaLumberjackSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        DDLog.add(DDTTYLogger.sharedInstance)
        DDLogVerbose("Verbose")
        DDLogInfo("Info")
        DDLogWarn("Warn")
        DDLogError("Error")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

