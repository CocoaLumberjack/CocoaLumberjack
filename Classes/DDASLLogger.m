// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2014, Deusty, LLC
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

#import "DDASLLogger.h"
#include <AssertMacros.h>
#import <asl.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

static DDASLLogger *sharedInstance;

@interface DDASLLogger () {
    aslclient _client;
}

@end


@implementation DDASLLogger

+ (instancetype)sharedInstance {
    static dispatch_once_t DDASLLoggerOnceToken;

    dispatch_once(&DDASLLoggerOnceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });

    return sharedInstance;
}

- (id)init {
    if (sharedInstance != nil) {
        return nil;
    }

    if ((self = [super init])) {
        // A default asl client is provided for the main thread,
        // but background threads need to create their own client.

        _client = asl_open(NULL, "com.apple.console", 0);
    }

    return self;
}

- (void)logMessage:(DDLogMessage *)logMessage {
    // Skip captured log messages.
    if (strcmp(logMessage->file, "DDASLLogCapture") == 0) {
        return;
    }

    NSString *logMsg = logMessage->logMsg;

    if (formatter) {
        logMsg = [formatter formatLogMessage:logMessage];
    }

    if (logMsg) {
        const char *msg = [logMsg UTF8String];

        size_t aslLogLevel;
        switch (logMessage->logFlag) {
            // Note: By default ASL will filter anything above level 5 (Notice).
            // So our mappings shouldn't go above that level.
            case LOG_FLAG_ERROR     : aslLogLevel = ASL_LEVEL_CRIT;     break;
            case LOG_FLAG_WARN      : aslLogLevel = ASL_LEVEL_ERR;      break;
            case LOG_FLAG_INFO      : aslLogLevel = ASL_LEVEL_WARNING;  break; // Regular NSLog's level
            case LOG_FLAG_DEBUG     :
            case LOG_FLAG_VERBOSE   :
            default                 : aslLogLevel = ASL_LEVEL_NOTICE;   break;
        }

        static char const *const levels[] = { "0", "1", "2", "3", "4", "5", "6", "7" };

        // NSLog uses the current euid to set the ASL_KEY_READ_UID.
        char readUIDString[16];
        int l = snprintf(readUIDString, sizeof(readUIDString), "%d", geteuid());

        NSAssert(l < sizeof(readUIDString),
                 @"Formatted euid is too long.");
        NSAssert(aslLogLevel < (sizeof(levels) / sizeof(levels[0])),
                 @"Unhandled ASL log level.");

        //TODO handle asl_* failures non-silently?
        aslmsg m = asl_new(ASL_TYPE_MSG);
        if (__builtin_expect(m != NULL, 1)) {
            __Require_noErr_Quiet(asl_set(m, ASL_KEY_LEVEL, levels[aslLogLevel]), asl_msg_done);
            __Require_noErr_Quiet(asl_set(m, ASL_KEY_MSG, msg), asl_msg_done);
            __Require_noErr_Quiet(asl_set(m, ASL_KEY_READ_UID, readUIDString), asl_msg_done);
            asl_send(_client, m);
        asl_msg_done:
            asl_free(m);
        }
    }
}

- (NSString *)loggerName {
    return @"cocoa.lumberjack.aslLogger";
}

@end
