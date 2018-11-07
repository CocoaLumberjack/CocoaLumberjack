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

#import "ViewController.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)) {
        [DDLog addLogger:[DDOSLogger sharedInstance]];
    } else {
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
    }
    
    DDLogVerbose(@"Verbose");
    DDLogInfo(@"Info");
    DDLogWarn(@"Warn");
    DDLogError(@"Error");
    
    DDLog *aDDLogInstance = [DDLog new];
    if (@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)) {
        [aDDLogInstance addLogger:[DDOSLogger sharedInstance]];
    } else {
        [aDDLogInstance addLogger:[DDTTYLogger sharedInstance]];
    }
    
    DDLogVerboseToDDLog(aDDLogInstance, @"Verbose from aDDLogInstance");
    DDLogInfoToDDLog(aDDLogInstance, @"Info from aDDLogInstance");
    DDLogWarnToDDLog(aDDLogInstance, @"Warn from aDDLogInstance");
    DDLogErrorToDDLog(aDDLogInstance, @"Error from aDDLogInstance");
}

@end
