#import "ContextFilterAppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "MyContextFilter.h"
#import "ThirdPartyFramework.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation ContextFilterAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Our application adopts a "third party framework" which also uses the lumberjack framework.
    // We love this because it greatly improves our ability to observe, debug, and diagnose problems!
    // 
    // Now sometimes we want to see the third party framework log messages in our Xcode console.
    // And sometimes we don't (for whatever reason).
    // 
    // We can accomplish this with the use of log message contexts.
    // Each log message has an associated context.
    // The context itself is simply an integer, and the default context is zero.
    // However, third party frameworks that employ lumberjack will likely use a custom non-zero context.
    // 
    // For example, the CocoaHTTPServer project defines it's own internal log statments:
    // 
    // HTTPLogWarn(@"File not found - %@", filePath);
    // 
    // As part of its logging setup, it defines its own custom logging context:
    // 
    // #define HTTP_LOG_CONTEXT 80
    // 
    // And each HTTPLog message uses this HTTP_LOG_CONTEXT instead of the default context.
    // This means that we can tell if log messages are coming from our code or from the framework.
    // We're going to tap into this ability to filter out log messages from our "third party framework".
    
    
    // We want all log messages (from our code or the third party framework) to show up in the Xcode console.
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // If we want to filter log messages from the third party framework, we can do this:
    
    MyContextFilter *filter = [[MyContextFilter alloc] init];
    
    [[DDTTYLogger sharedInstance] setLogFormatter:filter];
    
    // Now start up a timer to create some fake log messages for this example
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fire:) userInfo:nil repeats:YES];
    
    // Start the third party framework,
    // which will create a similar fake timer.
    
    [ThirdPartyFramework start];
}

- (void)fire:(NSTimer *)timer
{
    DDLogVerbose(@"Log message from our code");
}

@end
