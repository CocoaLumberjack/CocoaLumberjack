#import "WebSocketLogger.h"
#import "HTTPLogging.h"


@implementation WebSocketLogger

- (id)initWithWebSocket:(WebSocket *)ws
{
	if ((self = [super init]))
	{
		websocket = [ws retain];
		websocket.delegate = self;
		
		formatter = [[WebSocketFormatter alloc] init];
		
		// Add our logger
		// 
		// We do this here (as opposed to in webSocketDidOpen:) so the logging framework will retain us.
		// This is important as nothing else is retaining us.
		// It may be a bit hackish, but it's also the simplest solution.
		[DDLog addLogger:self];
	}
	return self;
}

- (void)dealloc
{
	[websocket setDelegate:nil];
	[websocket release];
	
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark WebSocket delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)webSocketDidOpen:(WebSocket *)ws
{
	// This method is invoked on the websocketQueue
	
	isWebSocketOpen = YES;
}

- (void)webSocketDidClose:(WebSocket *)ws
{
	// This method is invoked on the websocketQueue
	
	isWebSocketOpen = NO;
	
	// Remove our logger
	[DDLog removeLogger:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark DDLogger Protocol
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)logMessage:(DDLogMessage *)logMessage
{
	if (logMessage->logContext == HTTP_LOG_CONTEXT)
	{
		// Don't relay HTTP log messages.
		// Doing so could essentially cause an endless loop of log messages.
		
		return;
	}
	
	NSString *logMsg = logMessage->logMsg;
	
	if (formatter)
    {
        logMsg = [formatter formatLogMessage:logMessage];
    }
    
	if (logMsg)
	{
		dispatch_async(websocket.websocketQueue, ^{
			
			if (isWebSocketOpen)
			{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				[websocket sendMessage:logMsg];
				
				[pool release];
			}
		});
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
	NSString *dateAndTime = [dateFormatter stringFromDate:(logMessage->timestamp)];
	
	NSMutableString *webMsg = [[logMessage->logMsg mutableCopy] autorelease];
	
	[webMsg replaceOccurrencesOfString:@"<"  withString:@"&lt;"  options:0 range:NSMakeRange(0, [webMsg length])];
	[webMsg replaceOccurrencesOfString:@">"  withString:@"&gt;"  options:0 range:NSMakeRange(0, [webMsg length])];
	[webMsg replaceOccurrencesOfString:@"\n" withString:@"<br/>" options:0 range:NSMakeRange(0, [webMsg length])];
	
	return [NSString stringWithFormat:@"%@ &nbsp;%@", dateAndTime, webMsg];
}

- (void)dealloc
{
	[dateFormatter release];
	[super dealloc];
}

@end
