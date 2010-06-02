#import <Foundation/Foundation.h>
#import "HTTPServer.h"

@class WebSocketLogger;


@interface MyHTTPServer : HTTPServer
{
	NSMutableArray *webSockets;
}

- (void)addWebSocket:(WebSocketLogger *)ws;

@end
