#import <UIKit/UIKit.h>

@class WebServerIPhoneViewController;
@class DDFileLogger;
@class MyHTTPServer;


@interface WebServerIPhoneAppDelegate : NSObject <UIApplicationDelegate>
{
	DDFileLogger *fileLogger;
	
	MyHTTPServer *httpServer;
	
	UIWindow *window;
	WebServerIPhoneViewController *viewController;
}

@property (nonatomic, readonly) DDFileLogger *fileLogger;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet WebServerIPhoneViewController *viewController;

@end

