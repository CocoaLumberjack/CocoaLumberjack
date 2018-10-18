//
//  ViewController.swift
//  iOSSwiftIntegration
//
//  Created by Dmitry Lobanov on 17.10.2018.
//  Copyright © 2018 Dmitry Lobanov. All rights reserved.
//

import UIKit
import CocoaLumberjackSwift

let ddloglevel = DDLogLevel.verbose

private func printSomething() {
    DDLogVerbose("Verbose")
    DDLogDebug("Debug")
    DDLogInfo("Info")
    DDLogWarn("Warn")
    DDLogError("Error")
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let formatter = Formatter()
        DDTTYLogger.sharedInstance.logFormatter = formatter
        DDLog.add(DDTTYLogger.sharedInstance)
        
        DDLogVerbose("Verbose")
        DDLogDebug("Debug")
        DDLogInfo("Info")
        DDLogWarn("Warn")
        DDLogError("Error")
        
        printSomething()
        
        dynamicLogLevel = ddloglevel
        
        DDLogVerbose("Verbose")
        DDLogDebug("Debug")
        DDLogInfo("Info")
        DDLogWarn("Warn")
        DDLogError("Error")
        
        DDLogVerbose("Verbose", level: ddloglevel)
        DDLogDebug("Debug", level: ddloglevel)
        DDLogInfo("Info", level: ddloglevel)
        DDLogWarn("Warn", level: ddloglevel)
        DDLogError("Error", level: ddloglevel)
        
        printSomething()
    }
}

