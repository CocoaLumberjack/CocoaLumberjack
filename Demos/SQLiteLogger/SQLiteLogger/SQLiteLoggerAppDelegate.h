#import <Cocoa/Cocoa.h>

@class FMDBLogger;


@interface SQLiteLoggerAppDelegate : NSObject <NSApplicationDelegate> {
@private
    FMDBLogger *sqliteLogger;
    NSWindow *__unsafe_unretained window;
}

@property (unsafe_unretained) IBOutlet NSWindow *window;

@end
