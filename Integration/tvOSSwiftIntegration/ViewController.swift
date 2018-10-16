//
//  ViewController.swift
//  tvOSSwiftIntegration
//
//  Created by Dmitry Lobanov on 16.10.2018.
//  Copyright © 2018 Dmitry Lobanov. All rights reserved.
//

import UIKit
import CocoaLumberjackSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DDLog.add(DDTTYLogger.sharedInstance)
        DDLogVerbose("Verbose")
        DDLogInfo("Info")
        DDLogWarn("Warn")
        DDLogError("Error")
    }

}

