#import "WebSocketLogger.h"
#import "AsyncSocket.h"

#define NO_TIMEOUT -1

#define TAG_PREFIX          100
#define TAG_MSG_PLUS_SUFFIX 101


@implementation WebSocketLogger

- (id)initWithSocket:(AsyncSocket *)socket
{
	if((self = [super init]))
	{
		asyncSocket = [socket retain];
		[asyncSocket setDelegate:self];
		
		connectionThread = [[NSThread currentThread] retain];
		
		term = [[NSData alloc] initWithBytes:"\xFF" length:1];
		
		isWebSocketOpen = YES;
		
		// Add our logger
		[DDLog addLogger:self];
		
		// Open the websocket
		[asyncSocket readDataToLength:1 withTimeout:NO_TIMEOUT tag:TAG_PREFIX];
	}
	return self;
}

- (void)dealloc
{
	[asyncSocket setDelegate:nil];
	[asyncSocket release];
	
	[connectionThread release];
	[term release];
	
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Stuff
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)didReceiveMessage:(NSString *)msg
{
	NSLog(@"WebSocketLogger:%p didReceiveMessage:%@", self, msg);
}

- (void)sendMessage:(NSString *)msg
{
	if (!isWebSocketOpen) return;
	
	NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableData *data = [NSMutableData dataWithCapacity:([msgData length] + 2)];
	
	[data appendBytes:"\x00" length:1];
	[data appendData:msgData];
	[data appendBytes:"\xFF" length:1];
	
	[asyncSocket writeData:data withTimeout:NO_TIMEOUT tag:0];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark AsyncSocket Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	if(tag == TAG_PREFIX)
	{
		UInt8 *pFrame = (UInt8 *)[data bytes];
		UInt8 frame = *pFrame;
		
		if(frame <= 0x7F)
		{
			[asyncSocket readDataToData:term withTimeout:NO_TIMEOUT tag:TAG_MSG_PLUS_SUFFIX];
		}
		else
		{
			NSLog(@"WebSocket: Unsupported frame type");
			
			[sock disconnectAfterWriting];
		}
	}
	else
	{
		NSUInteger msgLength = [data length] - 1; // Excluding ending 0xFF frame
		
		NSString *msg = [[NSString alloc] initWithBytes:[data bytes] length:msgLength encoding:NSUTF8StringEncoding];
		
		[self didReceiveMessage:msg];
		
		[msg release];
	}
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	isWebSocketOpen = NO;
	
	// Remove our logger
	[DDLog removeLogger:self];
	
	// Post notification of closed socket so we get properly deallocated.
	// The server is retaining a reference to us.
	[[NSNotificationCenter defaultCenter] postNotificationName:WebSocketLoggerDidDieNotification object:self];
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
