#import "WebServerIPhoneAppDelegate.h"
#import "WebServerIPhoneViewController.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"

#import "HTTPServer.h"
#import "MyHTTPConnection.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation WebServerIPhoneAppDelegate

@synthesize fileLogger;

@synthesize window;
@synthesize viewController;


- (void)setupWebServer
{
    // Create server using our custom MyHTTPServer class
    httpServer = [[HTTPServer alloc] init];
    
    // Configure it to use our connection class
    [httpServer setConnectionClass:[MyHTTPConnection class]];
    
    // Set the bonjour type of the http server.
    // This allows the server to broadcast itself via bonjour.
    // You can automatically discover the service in Safari's bonjour bookmarks section.
    [httpServer setType:@"_http._tcp."];
    
    // Normally there is no need to run our server on any specific port.
    // Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
    // However, for testing purposes, it may be much easier if the port doesn't change on every build-and-go.
    [httpServer setPort:12345];
    
    // Serve files from our embedded Web folder
    NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
    [httpServer setDocumentRoot:webPath];
    
    // Start the server (and check for problems)
    
    NSError *error = nil;
    if (![httpServer start:&error])
    {
        DDLogError(@"Error starting HTTP Server: %@", error);
    }
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    // Direct log messages to the console.
    // The log messages will look exactly like a normal NSLog statement.
    // 
    // This is something we may not want to do in a shipping version of the application.
    
//  [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // We also want to direct our log messages to a file.
    // So we're going to setup file logging.
    // 
    // We start by creating a file logger.
    
    fileLogger = [[DDFileLogger alloc] init];
    
    // Configure some sensible defaults for an iPhone application.
    // 
    // Roll the file when it gets to be 512 KB or 24 Hours old (whichever comes first).
    // 
    // Also, only keep up to 4 archived log files around at any given time.
    // We don't want to take up too much disk space.
    
    fileLogger.maximumFileSize = 1024 * 512;    // 512 KB
    fileLogger.rollingFrequency = 60 * 60 * 24; //  24 Hours
    
    fileLogger.logFileManager.maximumNumberOfLogFiles = 4;
    
    // Add our file logger to the logging system.
    
    [DDLog addLogger:fileLogger];
    
    // Now setup our web server.
    // 
    // This will allow us to connect to the device from our web browser.
    // We can then view log files, or view logging in real time as the application runs.
    
    [self setupWebServer];
    
    // This application, by itself, doesn't actually do anthing.
    // It is just a proof of concept or demonstration.
    // But we want to be able to see the application logging something.
    // So we setup a timer to spit out a silly log message.
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(writeLogMessages:)
                                   userInfo:nil
                                    repeats:YES];
    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}


- (void)writeLogMessages:(NSTimer *)aTimer
{
    // Log a message in verbose mode.
    // 
    // Want to disable this log message?
    // Try setting the log level (at the top of this file) to LOG_LEVEL_WARN.
    // After doing this you can leave the log statement below.
    // It will automatically be compiled out (when compiling in release mode where compiler optimizations are enabled).
    
    DDLogVerbose(@"I like cheese");
}

@end
