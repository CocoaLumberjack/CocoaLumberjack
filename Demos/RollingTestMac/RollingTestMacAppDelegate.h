//
//  RollingTestMacAppDelegate.h
//  RollingTestMac
//
//  CocoaLumberjack Demos
//

#import <Cocoa/Cocoa.h>

@class DDFileLogger;

@interface RollingTestMacAppDelegate : NSObject <NSApplicationDelegate>
{
    DDFileLogger *fileLogger;
    
    NSWindow *__unsafe_unretained window;
}

@property (unsafe_unretained) IBOutlet NSWindow *window;

@end
