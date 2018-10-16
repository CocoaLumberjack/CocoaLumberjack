//
//  InterfaceController.swift
//  watchOSSwiftIntegration Extension
//
//  Created by Dmitry Lobanov on 16.10.2018.
//  Copyright © 2018 Dmitry Lobanov. All rights reserved.
//

import WatchKit
import Foundation
//import CocoaLumberjackSwift

class InterfaceController: WKInterfaceController {

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didAppear() {
        super.didAppear()
        //        DDLog.add(DDTTYLogger.sharedInstance)
        //        DDLogVerbose("Verbose")
        //        DDLogInfo("Info")
        //        DDLogWarn("Warn")
        //        DDLogError("Error")
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
