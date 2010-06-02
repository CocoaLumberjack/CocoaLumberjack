#import <Foundation/Foundation.h>
#import <unistd.h>
#import <asl.h>

#import "DDLog.h"


@interface DDConsoleLogger : NSObject <DDLogger>
{
	aslclient client;
	
	BOOL isRunningInXcode;
	
	NSDateFormatter *dateFormatter;
	
	char *app; // Not null terminated
	char *pid; // Not null terminated
	
	int appLen;
	int pidLen;
	
	id <DDLogFormatter> formatter;
}

+ (DDConsoleLogger *)sharedInstance;

@end
