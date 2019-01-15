//
//  UniversalAppAppDelegate.h
//  UniversalApp
//
//  CocoaLumberjack Demos
//

#import <UIKit/UIKit.h>

@class UniversalAppViewController;

@interface UniversalAppAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UniversalAppViewController *viewController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UniversalAppViewController *viewController;

@end

