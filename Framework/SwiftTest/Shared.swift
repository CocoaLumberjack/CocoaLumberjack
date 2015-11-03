//
//  Shared.swift
//  Lumberjack
//
//  Created by Kevin Ballard on 11/3/15.
//
//

import CocoaLumberjack
#if os(OSX)
import CocoaLumberjackSwift
#endif

func sharedLogTest() {
    DDLogVerbose("sharedLogTest test message", level: .Verbose)
}
