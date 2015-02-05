#import "WebSocketLogger.h"
#import "HTTPLogging.h"


@implementation WebSocketLogger

- (id)initWithWebSocket:(WebSocket *)ws
{
    if ((self = [super init]))
    {
        websocket = ws;
        websocket.delegate = self;
        
        self.logFormatter = [[WebSocketFormatter alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [websocket setDelegate:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark WebSocket delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)webSocketDidOpen:(WebSocket *)ws
{
    // This method is invoked on the websocketQueue
    
    isWebSocketOpen = YES;
    
    // Add our logger
    [DDLog addLogger:self];
}

- (void)webSocketDidClose:(WebSocket *)ws
{
    // This method is invoked on the websocketQueue
    
    isWebSocketOpen = NO;
    
    // Remove our logger
    [DDLog removeLogger:self];
    
    // Post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:WebSocketLoggerDidDieNotification object:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark DDLogger Protocol
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)logMessage:(DDLogMessage *)logMessage
{
    if (logMessage->_context == HTTP_LOG_CONTEXT)
    {
        // Don't relay HTTP log messages.
        // Doing so could essentially cause an endless loop of log messages.
        
        return;
    }
    
    NSString *logMsg = logMessage->_message;
    
    if (_logFormatter)
    {
        logMsg = [_logFormatter formatLogMessage:logMessage];
    }
    
    if (logMsg)
    {
        dispatch_async(websocket.websocketQueue, ^{ @autoreleasepool {
            
            if (isWebSocketOpen)
            {
                [websocket sendMessage:logMsg];
                
            }
        }});
    }
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation WebSocketFormatter

- (id)init
{
    if((self = [super init]))
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *dateAndTime = [dateFormatter stringFromDate:(logMessage->_timestamp)];
    
    NSMutableString *webMsg = [logMessage->_message mutableCopy];
    
    [webMsg replaceOccurrencesOfString:@"<"  withString:@"&lt;"  options:0 range:NSMakeRange(0, [webMsg length])];
    [webMsg replaceOccurrencesOfString:@">"  withString:@"&gt;"  options:0 range:NSMakeRange(0, [webMsg length])];
    [webMsg replaceOccurrencesOfString:@"\n" withString:@"<br/>" options:0 range:NSMakeRange(0, [webMsg length])];
    
    return [NSString stringWithFormat:@"%@ &nbsp;%@", dateAndTime, webMsg];
}


@end
