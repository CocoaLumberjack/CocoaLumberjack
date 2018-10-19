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

#import <Foundation/Foundation.h>

//! Project version number for CocoaLumberjack.
FOUNDATION_EXPORT double CocoaLumberjackVersionNumber;

//! Project version string for CocoaLumberjack.
FOUNDATION_EXPORT const unsigned char CocoaLumberjackVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <CocoaLumberjack/PublicHeader.h>

// Disable legacy macros
#ifndef DD_LEGACY_MACROS
    #define DD_LEGACY_MACROS 0
#endif

// Core
#import <CocoaLumberjack/DDLog.h>

// Main macros
#import <CocoaLumberjack/DDLogMacros.h>
#import <CocoaLumberjack/DDAssertMacros.h>

// Capture ASL
#import <CocoaLumberjack/DDASLLogCapture.h>

// Loggers
#import <CocoaLumberjack/DDTTYLogger.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDFileLogger.h>
#import <CocoaLumberjack/DDOSLogger.h>

// CLI
#if __has_include(<CocoaLumberjack/CLIColor.h>) && TARGET_OS_OSX
#import <CocoaLumberjack/CLIColor.h>
#endif
