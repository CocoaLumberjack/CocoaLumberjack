#import <Foundation/Foundation.h>
#import "DDLog.h"
#import "WebSocket.h"


@interface WebSocketLogger : WebSocket <DDLogger>
{
	id <DDLogFormatter> formatter;
	
	BOOL isWebSocketOpen;
	NSThread *connectionThread;
}

@end
