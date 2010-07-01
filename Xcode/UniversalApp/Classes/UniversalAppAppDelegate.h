//
//  UniversalAppAppDelegate.h
//  UniversalApp
//
//  Created by Robbie Hanson on 7/1/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UniversalAppViewController;

@interface UniversalAppAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UniversalAppViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UniversalAppViewController *viewController;

@end

