#import "DDConsoleLogger.h"
#import <sys/uio.h>


@implementation DDConsoleLogger

static DDConsoleLogger *sharedInstance;

/**
 * The runtime sends initialize to each class in a program exactly one time just before the class,
 * or any class that inherits from it, is sent its first message from within the program. (Thus the
 * method may never be invoked if the class is not used.) The runtime sends the initialize message to
 * classes in a thread-safe manner. Superclasses receive this message before their subclasses.
 *
 * This method may also be called directly (assumably by accident), hence the safety mechanism.
 **/
+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized)
	{
		initialized = YES;
		
		sharedInstance = [[DDConsoleLogger alloc] init];
	}
}

+ (DDConsoleLogger *)sharedInstance
{
	return sharedInstance;
}

- (id)init
{
	if (sharedInstance != nil)
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		// To log to the console, we use the apple system logging facility.
		// A default asl client is provided for the main thread,
		// but background threads need to create their own client.
		
		client = asl_open(NULL, "com.apple.console", 0);
		
		// If we are running the application via Xcode,
		// we want our log messages to have the same look and feel and normal NSLog statements.
		
		isRunningInXcode = isatty(STDERR_FILENO);
		
		if (isRunningInXcode)
		{
			dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
			[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
			
			// Initialze 'app' variable (char *)
			
			NSString *appNStr = [[NSProcessInfo processInfo] processName];
			const char *appCStr = [appNStr UTF8String];
			
			appLen = strlen(appCStr);
			
			app = (char *)malloc(appLen);
			strncpy(app, appCStr, appLen); // Not null terminated
			
			// Initialize 'pid' variable (char *)
			
			NSString *pidNStr = [NSString stringWithFormat:@"%i", (int)getpid()];
			const char *pidCStr = [pidNStr UTF8String];
			
			pidLen = strlen(pidCStr);
			
			pid = (char *)malloc(pidLen);
			strncpy(pid, pidCStr, pidLen); // Not null terminated
		}
	}
	return self;
}

- (void)logMessage:(DDLogMessage *)logMessage
{
	NSString *logMsg = logMessage->logMsg;
	
	if (formatter)
	{
		logMsg = [formatter formatLogMessage:logMessage];
	}
	
	if (logMsg)
	{
		// Can we simply use NSLog? Yes and no.
		// An NSLog message looks like this in Xcode:
		// 
		// 2010-04-29 11:09:05.800 AppName[34209:a0f] Some log message...
		// 
		// The thing to notice is the [<process id>:<thread id>] part.
		// Any NSLog statements from this method would have the thread id of the logging thread.
		// It would not have the proper thread id of the thread that actually issued the DDLog statement.
		// 
		// To solve this problem we have to know a little bit about how NSLog actually works internally.
		// There are three important things to note:
		// 
		// - NSLog uses the Apple System Logging (asl) library to make log messages show up in Console.app.
		// - The Xcode console gets its output by redirecting STDERR.
		// - NSLog issues a separate log statement for Xcode console output.
		// 
		// One can also look at Apple's open source CFUtilities.c file to observe how CFShow works,
		// which does the equivalent of NSLog.
		// 
		// One other quick thing to mention:
		// 
		// It is possible to open an asl_client in such a manner that it also writes to STDERR.
		// And when you issue a log statement through such an asl client,
		// the message shows up in Console.app and also in the Xcode console.
		// However, the log message doesn't look anything like NSLog.
		// Instead it looks something like this:
		// 
		// Thu Apr 29 11:09:05 ComputerName.local AppName[34209] <Notice>: Some log message...
		// 
		// So we duplicate NSLog in the same manner that CFShow works (and NSLog by extension).
		
		
		// Log the message to the Console.app
		
		const char *msg = [logMsg UTF8String];
		
		int aslLogLevel;
		switch (logMessage->logLevel)
		{
			// Note: By default ASL will filter anything above level 5 (Notice).
			// So our mappings shouldn't go above that level.
			
			case 1  : aslLogLevel = ASL_LEVEL_CRIT;    break;
			case 2  : aslLogLevel = ASL_LEVEL_ERR;     break;
			case 3  : aslLogLevel = ASL_LEVEL_WARNING; break;
			default : aslLogLevel = ASL_LEVEL_NOTICE;  break;
		}
		
		asl_log(client, NULL, aslLogLevel, "%s", msg);
		
		// Log the message to the Xcode console (if running via Xcode)
		
		if (isRunningInXcode)
		{
			// The following is a highly optimized verion of file output to std err.
			
			// ts = timestamp
			
			NSString *tsNStr = [dateFormatter stringFromDate:(logMessage->timestamp)];
			
			const char *tsCStr = [tsNStr UTF8String];
			int tsLen = strlen(tsCStr);
			
			// tid = thread id
			// 
			// How many characters do we need for the thread id?
			// logMessage->machThreadID is of type mach_port_t, which is an unsigned int.
			// 
			// 1 hex char = 4 bits
			// 8 hex chars for 32 bit, plus ending '\0' = 9
			
			char tidCStr[9];
			int tidLen = snprintf(tidCStr, 9, "%x", logMessage->machThreadID);
			
			// Here is our format: "%s %s[%i:%s] %s", timestamp, appName, processID, threadID, logMsg
			
			struct iovec v[10];
			
			v[0].iov_base = (char *)tsCStr;
			v[0].iov_len = tsLen;
			
			v[1].iov_base = " ";
			v[1].iov_len = 1;
			
			v[2].iov_base = app;
			v[2].iov_len = appLen;
			
			v[3].iov_base = "[";
			v[3].iov_len = 1;
			
			v[4].iov_base = pid;
			v[4].iov_len = pidLen;
			
			v[5].iov_base = ":";
			v[5].iov_len = 1;
			
			v[6].iov_base = tidCStr;
			v[6].iov_len = MIN(8, tidLen); // snprintf doesn't return what you might think
			
			v[7].iov_base = "] ";
			v[7].iov_len = 2;
			
			v[8].iov_base = (char *)msg;
			v[8].iov_len = strlen(msg);
			
			v[9].iov_base = "\n";
			v[9].iov_len = [logMsg hasSuffix:@"\n"] ? 0 : 1;
			
			writev(STDERR_FILENO, v, 10);
		}
	}
}

- (id <DDLogFormatter>)logFormatter
{
	return formatter;
}

- (void)setLogFormatter:(id <DDLogFormatter>)logFormatter
{
	if (formatter != logFormatter)
	{
		[formatter release];
		formatter = [logFormatter retain];
	}
}

- (NSString *)loggerName
{
	return @"cocoa.lumberjack.consoleLogger";
}

@end
