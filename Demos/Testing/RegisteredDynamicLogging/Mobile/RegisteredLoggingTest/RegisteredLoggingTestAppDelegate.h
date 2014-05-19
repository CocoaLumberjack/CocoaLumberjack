#import <UIKit/UIKit.h>

@class RegisteredLoggingTestViewController;


@interface RegisteredLoggingTestAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet RegisteredLoggingTestViewController *viewController;

@end
