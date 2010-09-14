#import <Foundation/Foundation.h>

@class AsyncSocket;


#define WebSocketDidDieNotification  @"WebSocketDidDie"

@interface WebSocket : NSObject
{
	CFHTTPMessageRef request;
	AsyncSocket *asyncSocket;
	
	NSData *term;
	
	BOOL isOpen;
	BOOL isVersion76;
}

+ (BOOL)isWebSocketRequest:(CFHTTPMessageRef)request;

- (id)initWithRequest:(CFHTTPMessageRef)request socket:(AsyncSocket *)socket;

- (void)didOpen;

- (void)sendMessage:(NSString *)msg;
- (void)didReceiveMessage:(NSString *)msg;

- (void)didClose;

@end
