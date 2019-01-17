//
//  CoreDataLoggerAppDelegate.h
//  CoreDataLogger
//
//  CocoaLumberjack Demos
//

#import <Cocoa/Cocoa.h>

@class CoreDataLogger;

@interface CoreDataLoggerAppDelegate : NSObject <NSApplicationDelegate> {
@private
    CoreDataLogger *coreDataLogger;
    NSWindow *__unsafe_unretained window;
}

@property (unsafe_unretained) IBOutlet NSWindow *window;

@end
