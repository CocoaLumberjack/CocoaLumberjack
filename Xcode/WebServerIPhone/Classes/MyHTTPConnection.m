#import "MyHTTPConnection.h"
#import "WebServerIPhoneAppDelegate.h"
#import "HTTPLogging.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "HTTPDynamicFileResponse.h"
#import "GCDAsyncSocket.h"
#import "DDLog.h"
#import "DDFileLogger.h"
#import "WebSocket.h"
#import "WebSocketLogger.h"


@implementation MyHTTPConnection

- (id <DDLogFileManager>)logFileManager
{
	WebServerIPhoneAppDelegate *appDelegate;
	appDelegate = (WebServerIPhoneAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	return appDelegate.fileLogger.logFileManager;
}

- (NSData *)generateIndexData
{
	NSArray *sortedLogFileInfos = [[self logFileManager] sortedLogFileInfos];
	
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setFormatterBehavior:NSDateFormatterBehavior10_4];
	[df setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
	
	NSNumberFormatter *nf = [[[NSNumberFormatter alloc] init] autorelease];
	[nf setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[nf setNumberStyle:NSNumberFormatterDecimalStyle];
	[nf setMinimumFractionDigits:2];
	[nf setMaximumFractionDigits:2];
	
	NSMutableString *response = [NSMutableString stringWithCapacity:1000];
	
	[response appendString:@"<html><head>"];
	[response appendString:@"<style type='text/css'>@import url('styles.css');</style>"];
	[response appendString:@"</head><body>"];
	
	[response appendString:@"<h1>Device Log Files</h1>"];
	
	[response appendString:@"<table cellspacing='2'>"];
	
	for (DDLogFileInfo *logFileInfo in sortedLogFileInfos)
	{
		NSString *fileName = logFileInfo.fileName;
		NSString *fileDate = [df stringFromDate:[logFileInfo creationDate]];
		NSString *fileSize;
		
		unsigned long long sizeInBytes = logFileInfo.fileSize;
		
		double GBs = (double)(sizeInBytes) / (double)(1024 * 1024 * 1024);
		double MBs = (double)(sizeInBytes) / (double)(1024 * 1024);
		double KBs = (double)(sizeInBytes) / (double)(1024);
		
		if(GBs >= 1.0)
		{
			NSString *temp = [nf stringFromNumber:[NSNumber numberWithDouble:GBs]];
			fileSize = [NSString stringWithFormat:@"%@ GB", temp];
		}
		else if(MBs >= 1.0)
		{
			NSString *temp = [nf stringFromNumber:[NSNumber numberWithDouble:MBs]];
			fileSize = [NSString stringWithFormat:@"%@ MB", temp];
		}
		else
		{
			NSString *temp = [nf stringFromNumber:[NSNumber numberWithDouble:KBs]];
			fileSize = [NSString stringWithFormat:@"%@ KB", temp];
		}
		
		NSString *fileLink = [NSString stringWithFormat:@"<a href='/logs/%@'>%@</a>", fileName, fileName];
		
		[response appendFormat:@"<tr><td>%@</td><td>%@</td><td align='right'>%@</td>", fileLink, fileDate, fileSize];
	}
	
	[response appendString:@"</table></body></html>"];
	
	return [response dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)filePathForURI:(NSString *)path
{
	if ([path hasPrefix:@"/logs/"])
	{
		NSString *logsDir = [[self logFileManager] logsDirectory];
		return [logsDir stringByAppendingPathComponent:[path lastPathComponent]];
	}
	
	return [super filePathForURI:path];
}

- (NSString *)wsLocation
{
	NSString *port = [NSString stringWithFormat:@"%hu", [asyncSocket localPort]];
	
	NSString *wsLocation;
	NSString *wsHost = [request headerField:@"Host"];
	
	if (wsHost == nil)
	{
		wsLocation = [NSString stringWithFormat:@"ws://localhost:%@/livelog", port];
	}
	else
	{
		wsLocation = [NSString stringWithFormat:@"ws://%@/livelog", wsHost];
	}
	
	return wsLocation;
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	if ([path isEqualToString:@"/logs.html"])
	{
		NSData *indexData = [self generateIndexData];
		return [[[HTTPDataResponse alloc] initWithData:indexData] autorelease];
	}
	else if ([path isEqualToString:@"/socket.html"])
	{
		// The socket.html file contains a URL template that needs to be completed:
		// 
		// ws = new WebSocket("%%WEBSOCKET_URL%%");
		// 
		// We need to replace "%%WEBSOCKET_URL%%" with whatever URL the server is running on.
		// We can accomplish this easily with the HTTPDynamicFileResponse class,
		// which takes a dictionary of replacement key-value pairs,
		// and performs replacements on the fly as it uploads the file.
		
		NSString *loc = [self wsLocation];
		NSDictionary *replacementDict = [NSDictionary dictionaryWithObject:loc forKey:@"WEBSOCKET_URL"];
		
		return [[[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
		                                            forConnection:self
		                                                separator:@"%%"
		                                    replacementDictionary:replacementDict] autorelease];
	}
	else
	{
		return [super httpResponseForMethod:method URI:path];
	}
}

- (WebSocket *)webSocketForURI:(NSString *)path
{
	if ([path isEqualToString:@"/livelog"])
	{
		// Create the WebSocket
		WebSocket *ws = [[WebSocket alloc] initWithRequest:request socket:asyncSocket];
		
		// Create the WebSocketLogger
		WebSocketLogger *wsLogger = [[WebSocketLogger alloc] initWithWebSocket:ws];
		
		// Memory management:
		// The WebSocket will be retained by the HTTPServer and the WebSocketLogger.
		// The WebSocketLogger will be retained by the logging framework,
		// as it adds itself to the list of active loggers from within its init method.
		
		[wsLogger release];
		return [ws autorelease];
	}
	
	return [super webSocketForURI:path];
}

@end
