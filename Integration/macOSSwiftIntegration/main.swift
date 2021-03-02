// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2021, Deusty, LLC
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

import Foundation
import CocoaLumberjackSwift

if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
    DDLog.add(DDOSLogger.sharedInstance)
} else if let ttyLogger = DDTTYLogger.sharedInstance {
    DDLog.add(ttyLogger)
}

DDLogVerbose("Verbose")
DDLogInfo("Info")
DDLogWarn("Warn")
DDLogError("Error")
