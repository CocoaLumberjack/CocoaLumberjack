#import <Cocoa/Cocoa.h>

@class FMDBLogger;


@interface SQLiteLoggerAppDelegate : NSObject <NSApplicationDelegate> {
@private
	FMDBLogger *sqliteLogger;
	NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
