//
//  AppDelegate.m
//  iOSFrameworkIntegration
//
//  Created by Dmitry Lobanov on 16.10.2018.
//  Copyright © 2018 Dmitry Lobanov. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate () @end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UIWindow *window = [UIWindow new];
    window.backgroundColor = [UIColor blackColor];
    self.window = window;
    self.window.rootViewController = [ViewController new];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
