#import <Foundation/Foundation.h>
#import "HTTPConnection.h"


@interface MyHTTPConnection : HTTPConnection
{
	BOOL isWebSocketRequest;
}

@end
