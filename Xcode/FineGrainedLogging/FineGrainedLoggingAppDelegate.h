#import <Cocoa/Cocoa.h>

@class TimerOne;
@class TimerTwo;


@interface FineGrainedLoggingAppDelegate : NSObject <NSApplicationDelegate>
{
	TimerOne *timerOne;
	TimerTwo *timerTwo;
	
	NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
