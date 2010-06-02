#import <UIKit/UIKit.h>

@class BenchmarkIPhoneViewController;


@interface BenchmarkIPhoneAppDelegate : NSObject <UIApplicationDelegate>
{
	UIWindow *window;
	BenchmarkIPhoneViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet BenchmarkIPhoneViewController *viewController;

@end

