#import <Cocoa/Cocoa.h>

@class DDFileLogger;


@interface LogFileCompressorAppDelegate : NSObject <NSApplicationDelegate>
{
    DDFileLogger *fileLogger;
    
    NSWindow *__unsafe_unretained window;
}

@property (unsafe_unretained) IBOutlet NSWindow *window;

@end
