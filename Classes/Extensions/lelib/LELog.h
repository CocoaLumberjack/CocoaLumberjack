//
//  LELog.h
//  lelib
//
//  Created by Petr on 25/11/13.
//  Copyright (c) 2013,2014 Logentries. All rights reserved.
//

#import <Foundation/Foundation.h>

/* Obj-C API */

@protocol LELoggableObject <NSObject>

@optional

- (NSString*)leDescription;

@end

@interface LELog : NSObject

+ (LELog*)sharedInstance;

/*
 Appends space separated token to each log message.
 */
@property (atomic, copy) NSString* token;

/*
 When object implements LELoggableObject interface, it logs return value of
 leDescription method. Otherwise, tries to log return value of standard
 description method.
 */
- (void)log:(NSObject*)object;

/*
 Log UIApplicationDidFinishLaunchingNotification, UIApplicationDidBecomeActiveNotification,
 UIApplicationWillEnterForegroundNotification, UIApplicationWillResignActiveNotification,
 UIApplicationWillTerminateNotification.
 */
@property (nonatomic, assign) BOOL logApplicationLifecycleNotifications;

@end



