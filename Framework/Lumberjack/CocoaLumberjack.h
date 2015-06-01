//
//  CocoaLumberjack.h
//  CocoaLumberjack
//
//  Created by Andrew Mackenzie-Ross on 3/02/2015.
//
//

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
#import <CocoaLUmberjack/DDFileLogger.h>
