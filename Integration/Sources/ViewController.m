//
//  ViewController.m
//  iOSFrameworkIntegration
//
//  Created by Dmitry Lobanov on 16.10.2018.
//  Copyright © 2018 Dmitry Lobanov. All rights reserved.
//

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
    
    [DDLog addLogger:[DDOSLogger sharedInstance]];
    
    DDLogVerbose(@"Verbose");
    DDLogInfo(@"Info");
    DDLogWarn(@"Warn");
    DDLogError(@"Error");
    
    DDLog *aDDLogInstance = [DDLog new];
    [aDDLogInstance addLogger:[DDOSLogger sharedInstance]];
    
    DDLogVerboseToDDLog(aDDLogInstance, @"Verbose from aDDLogInstance");
    DDLogInfoToDDLog(aDDLogInstance, @"Info from aDDLogInstance");
    DDLogWarnToDDLog(aDDLogInstance, @"Warn from aDDLogInstance");
    DDLogErrorToDDLog(aDDLogInstance, @"Error from aDDLogInstance");
}

@end
