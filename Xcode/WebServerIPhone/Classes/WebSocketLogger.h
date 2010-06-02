#import <Foundation/Foundation.h>
#import "DDLog.h"

@class AsyncSocket;


#define WebSocketLoggerDidDieNotification  @"WebSocketLoggerDidDie"

@interface WebSocketLogger : NSObject <DDLogger>
{
	id <DDLogFormatter> formatter;
	
	AsyncSocket *asyncSocket;
	NSThread *connectionThread;
	
	NSData *term;
	
	BOOL isWebSocketOpen;
}

- (id)initWithSocket:(AsyncSocket *)socket;

@end
