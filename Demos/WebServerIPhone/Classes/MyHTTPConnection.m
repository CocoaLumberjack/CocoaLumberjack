#import "MyHTTPConnection.h"
#import "WebServerIPhoneAppDelegate.h"
#import "HTTPLogging.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "HTTPDynamicFileResponse.h"
#import "GCDAsyncSocket.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "WebSocket.h"
#import "WebSocketLogger.h"


@implementation MyHTTPConnection

static NSMutableSet *webSocketLoggers;

/**
 * The runtime sends initialize to each class in a program exactly one time just before the class,
 * or any class that inherits from it, is sent its first message from within the program. (Thus the
 * method may never be invoked if the class is not used.) The runtime sends the initialize message to
 * classes in a thread-safe manner. Superclasses receive this message before their subclasses.
 *
 * This method may also be called directly (assumably by accident), hence the safety mechanism.
**/
+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // We need some place to store the webSocketLogger instances.
        // So we'll store them here, in a class variable.
        // 
        // We'll also use a simple notification system to release them when they die.
        
        webSocketLoggers = [[NSMutableSet alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(webSocketLoggerDidDie:)
                                                     name:WebSocketLoggerDidDieNotification
                                                   object:nil];
    });
}

+ (void)addWebSocketLogger:(WebSocketLogger *)webSocketLogger
{
    @synchronized(webSocketLoggers)
    {
        [webSocketLoggers addObject:webSocketLogger];
    }
}

+ (void)webSocketLoggerDidDie:(NSNotification *)notification
{
    @synchronized(webSocketLoggers)
    {
        [webSocketLoggers removeObject:[notification object]];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Utilities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the logFileManager, which is a part of the DDFileLogger system.
 * The DDLogFileManager is the subsystem which manages the location and creation of log files.
**/
- (id <DDLogFileManager>)logFileManager
{
    WebServerIPhoneAppDelegate *appDelegate;
    appDelegate = (WebServerIPhoneAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    return appDelegate.fileLogger.logFileManager;
}

/**
 * Dynamic discovery of proper websocket href. 
**/
- (NSString *)wsLocation
{
    NSString *port = [NSString stringWithFormat:@"%hu", [asyncSocket localPort]];
    
    NSString *wsLocation;
    NSString *wsHost = [request headerField:@"Host"];
    
    if (wsHost == nil)
    {
        wsLocation = [NSString stringWithFormat:@"ws://localhost:%@/livelog", port];
    }
    else
    {
        wsLocation = [NSString stringWithFormat:@"ws://%@/livelog", wsHost];
    }
    
    return wsLocation;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark /logs.html
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the response body for requests to "/logs/index.html".
 * 
 * The response is generated dynamically.
 * It returns the list of log files currently on the system, along with their creation date and file size.
**/
- (NSData *)generateIndexData
{
    NSArray *sortedLogFileInfos = [[self logFileManager] sortedLogFileInfos];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setFormatterBehavior:NSDateFormatterBehavior10_4];
    [df setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    [nf setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    [nf setMinimumFractionDigits:2];
    [nf setMaximumFractionDigits:2];
    
    NSMutableString *response = [NSMutableString stringWithCapacity:1000];
    
    [response appendString:@"<html><head>"];
    [response appendString:@"<style type='text/css'>@import url('styles.css');</style>"];
    [response appendString:@"</head><body>"];
    
    [response appendString:@"<h1>Device Log Files</h1>"];
    
    [response appendString:@"<table cellspacing='2'>"];
    
    for (DDLogFileInfo *logFileInfo in sortedLogFileInfos)
    {
        NSString *fileName = logFileInfo.fileName;
        NSString *fileDate = [df stringFromDate:[logFileInfo creationDate]];
        NSString *fileSize;
        
        unsigned long long sizeInBytes = logFileInfo.fileSize;
        
        double GBs = (double)(sizeInBytes) / (double)(1024 * 1024 * 1024);
        double MBs = (double)(sizeInBytes) / (double)(1024 * 1024);
        double KBs = (double)(sizeInBytes) / (double)(1024);
        
        if(GBs >= 1.0)
        {
            NSString *temp = [nf stringFromNumber:[NSNumber numberWithDouble:GBs]];
            fileSize = [NSString stringWithFormat:@"%@ GB", temp];
        }
        else if(MBs >= 1.0)
        {
            NSString *temp = [nf stringFromNumber:[NSNumber numberWithDouble:MBs]];
            fileSize = [NSString stringWithFormat:@"%@ MB", temp];
        }
        else
        {
            NSString *temp = [nf stringFromNumber:[NSNumber numberWithDouble:KBs]];
            fileSize = [NSString stringWithFormat:@"%@ KB", temp];
        }
        
        NSString *fileLink = [NSString stringWithFormat:@"<a href='/logs/%@'>%@</a>", fileName, fileName];
        
        [response appendFormat:@"<tr><td>%@</td><td>%@</td><td align='right'>%@</td>", fileLink, fileDate, fileSize];
    }
    
    [response appendString:@"</table></body></html>"];
    
    return [response dataUsingEncoding:NSUTF8StringEncoding];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark HTTPConnection
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Overrides method in HTTPConnection.
 * 
 * This method is invoked to retrieve the filePath for a given URI.
 * We override it to provide proper mapping for log file paths.
**/
- (NSString *)filePathForURI:(NSString *)path allowDirectory:(BOOL)allowDirectory
{
    if ([path hasPrefix:@"/logs/"])
    {
        NSString *logsDir = [[self logFileManager] logsDirectory];
        return [logsDir stringByAppendingPathComponent:[path lastPathComponent]];
    }
    
    // Fall through
    return [super filePathForURI:path allowDirectory:allowDirectory];
}

/**
 * Overrides method in HTTPConnection.
**/
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    if ([path isEqualToString:@"/logs.html"])
    {
        // Dynamically generate html response with list of available log files
        
        NSData *indexData = [self generateIndexData];
        return [[HTTPDataResponse alloc] initWithData:indexData];
    }
    else if ([path isEqualToString:@"/socket.html"])
    {
        // The socket.html file contains a URL template that needs to be completed:
        // 
        // ws = new WebSocket("%%WEBSOCKET_URL%%");
        // 
        // We need to replace "%%WEBSOCKET_URL%%" with whatever URL the server is running on.
        // We can accomplish this easily with the HTTPDynamicFileResponse class,
        // which takes a dictionary of replacement key-value pairs,
        // and performs replacements on the fly as it uploads the file.
        
        NSString *loc = [self wsLocation];
        NSDictionary *replacementDict = [NSDictionary dictionaryWithObject:loc forKey:@"WEBSOCKET_URL"];
        
        return [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
                                                    forConnection:self
                                                        separator:@"%%"
                                            replacementDictionary:replacementDict];
    }
    
    // Fall through
    return [super httpResponseForMethod:method URI:path];
}

/**
 * Overrides method in HTTPConnection.
**/
- (WebSocket *)webSocketForURI:(NSString *)path
{
    if ([path isEqualToString:@"/livelog"])
    {
        // Create the WebSocket
        WebSocket *webSocket = [[WebSocket alloc] initWithRequest:request socket:asyncSocket];
        
        // Create the WebSocketLogger
        WebSocketLogger *webSocketLogger = [[WebSocketLogger alloc] initWithWebSocket:webSocket];
        
        [[self class] addWebSocketLogger:webSocketLogger];
        return webSocket;
    }
    
    return [super webSocketForURI:path];
}

@end
