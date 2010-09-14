#import "WebSocketLogger.h"
#import "AsyncSocket.h"

#define NO_TIMEOUT -1

#define TAG_PREFIX          100
#define TAG_MSG_PLUS_SUFFIX 101


@implementation WebSocketLogger

- (void)dealloc
{
	[connectionThread release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Stuff
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)didOpen
{
	isWebSocketOpen = YES;
	connectionThread = [[NSThread currentThread] retain];
	
	// Add our logger
	[DDLog addLogger:self];
	
	[super didOpen];
}

- (void)didReceiveMessage:(NSString *)msg
{
	NSLog(@"WebSocketLogger:%p didReceiveMessage:%@", self, msg);
}

- (void)sendMessage:(NSString *)msg
{
	if (!isWebSocketOpen) return;
	
	[super sendMessage:msg];
}

- (void)didClose
{
	isWebSocketOpen = NO;
	
	// Remove our logger
	[DDLog removeLogger:self];
	
	[super didClose];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark DDLogger Protocol
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)logMessage:(DDLogMessage *)logMessage
{
	NSString *logMsg = logMessage->logMsg;
	
	if (formatter)
    {
        logMsg = [formatter formatLogMessage:logMessage];
    }
    
	if (logMsg)
	{
		[self performSelector:@selector(sendMessage:) onThread:connectionThread withObject:logMsg waitUntilDone:NO];
	}
}

- (id <DDLogFormatter>)logFormatter
{
    return formatter;
}

- (void)setLogFormatter:(id <DDLogFormatter>)logFormatter
{
    [formatter release];
    formatter = [logFormatter retain];
}

@end
