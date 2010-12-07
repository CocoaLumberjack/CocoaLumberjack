#import <Foundation/Foundation.h>
#import "DDLog.h"
#import "WebSocket.h"


@interface WebSocketLogger : DDAbstractLogger <DDLogger>
{
	WebSocket *websocket;
	BOOL isWebSocketOpen;
}

- (id)initWithWebSocket:(WebSocket *)ws;

@end

@interface WebSocketFormatter : NSObject <DDLogFormatter>
{
	NSDateFormatter *dateFormatter;
}

@end
