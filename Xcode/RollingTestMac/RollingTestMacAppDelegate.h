#import <Cocoa/Cocoa.h>

@class DDFileLogger;


@interface RollingTestMacAppDelegate : NSObject <NSApplicationDelegate>
{
	DDFileLogger *fileLogger;
	
	NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
