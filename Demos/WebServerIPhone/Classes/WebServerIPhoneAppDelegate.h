//
//  WebServerIPhoneAppDelegate.h
//  WebServerIPhone
//
//  CocoaLumberjack Demos
//

#import <UIKit/UIKit.h>

@class WebServerIPhoneViewController;
@class DDFileLogger;
@class HTTPServer;

@interface WebServerIPhoneAppDelegate : NSObject <UIApplicationDelegate>
{
    DDFileLogger *fileLogger;
    
    HTTPServer *httpServer;
    
    UIWindow *window;
    WebServerIPhoneViewController *viewController;
}

@property (nonatomic, readonly) DDFileLogger *fileLogger;

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet WebServerIPhoneViewController *viewController;

@end
