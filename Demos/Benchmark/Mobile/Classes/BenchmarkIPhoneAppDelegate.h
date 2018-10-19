//
//  BenchmarkIPhoneAppDelegate.h
//  BenchmarkIPhone
//
//  CocoaLumberjack Demos
//

#import <UIKit/UIKit.h>

@class BenchmarkIPhoneViewController;

@interface BenchmarkIPhoneAppDelegate : NSObject <UIApplicationDelegate>
{
    UIWindow *window;
    BenchmarkIPhoneViewController *viewController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet BenchmarkIPhoneViewController *viewController;

@end
