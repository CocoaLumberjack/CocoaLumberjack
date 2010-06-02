#import "MyHTTPServer.h"
#import "MyHTTPConnection.h"
#import "WebSocketLogger.h"


@implementation MyHTTPServer

- (id)init
{
	if((self = [super init]))
	{
		// Initialize an array to hold all the WebSocket connections
		webSockets = [[NSMutableArray alloc] init];
		
		// Register for notifications of closed websocket connections
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(webSocketDidDie:)
													 name:WebSocketLoggerDidDieNotification
												   object:nil];
		
		// Configure our connection class
		[self setConnectionClass:[MyHTTPConnection class]];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[webSockets release];
	[super dealloc];
}

- (void)addWebSocket:(WebSocketLogger *)ws
{
	@synchronized(webSockets)
	{
		[webSockets addObject:ws];
	}
}

- (void)webSocketDidDie:(NSNotification *)notification
{
	// Note: This method is called on the thread/runloop that posted the notification
	
	@synchronized(webSockets)
	{
		[webSockets removeObject:[notification object]];
	}
}

@end
