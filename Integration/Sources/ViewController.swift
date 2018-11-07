// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2018, Deusty, LLC
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

        if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
            if let logger = DDOSLogger.sharedInstance {
                logger.logFormatter = formatter
                DDLog.add(logger)
            }
        } else {
            if let logger = DDTTYLogger.sharedInstance {
                logger.logFormatter = formatter
                DDLog.add(logger)
            }
        }
        
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
