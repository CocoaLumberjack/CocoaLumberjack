//
//  FineGrainedLoggingAppDelegate.h
//  FineGrainedLogging
//
//  CococaLumberjack Demos
//

#import <Cocoa/Cocoa.h>

@class TimerOne;
@class TimerTwo;

@interface FineGrainedLoggingAppDelegate : NSObject <NSApplicationDelegate>
{
    TimerOne *timerOne;
    TimerTwo *timerTwo;
    
    NSWindow *__unsafe_unretained window;
}

@property (unsafe_unretained) IBOutlet NSWindow *window;

@end
