#import <Cocoa/Cocoa.h>

@class CoreDataLogger;


@interface CoreDataLoggerAppDelegate : NSObject <NSApplicationDelegate> {
@private
	CoreDataLogger *coreDataLogger;
	NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
