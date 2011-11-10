#import "AppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DispatchQueueLogFormatter.h"

// Log levels: 0-off, 1-error, 2-warn, 3-info, 4-verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation AppDelegate
{
	dispatch_queue_t downloadingQueue;
	dispatch_queue_t parsingQueue;
	dispatch_queue_t processingQueue;
}

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	if (YES)
	{
		// Log statements *AFTER* DispatchQueueLogFormatter
		
		DispatchQueueLogFormatter *formatter = [[DispatchQueueLogFormatter alloc] init];
		formatter.queueLength = 17;
		formatter.rightAlign = NO;
		
		[formatter setReplacementString:@"main"              forQueueLabel:@"com.apple.main-thread"];
		[formatter setReplacementString:@"global-background" forQueueLabel:@"com.apple.root.background-priority"];
		[formatter setReplacementString:@"global-low"        forQueueLabel:@"com.apple.root.low-priority"];
		[formatter setReplacementString:@"global-default"    forQueueLabel:@"com.apple.root.default-priority"];
		[formatter setReplacementString:@"global-high"       forQueueLabel:@"com.apple.root.high-priority"];
		
		[formatter setReplacementString:@"downloading" forQueueLabel:@"downloadingQueue"];
		[formatter setReplacementString:@"parsing"     forQueueLabel:@"parsingQueue"];
		[formatter setReplacementString:@"processing"  forQueueLabel:@"processingQueue"];
		
		[[DDTTYLogger sharedInstance] setLogFormatter:formatter];
	}
	else
	{
		// Log statements *BEFORE* DispatchQueueLogFormatter
	}
	
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
	DDLogVerbose(@"Starting queues");
	
	downloadingQueue = dispatch_queue_create("downloadingQueue", NULL);
	parsingQueue     = dispatch_queue_create("parsingQueue", NULL);
	processingQueue  = dispatch_queue_create("processingQueue", NULL);
	
	dispatch_block_t blockA = ^{
		DDLogVerbose(@"Some log statement");
	};
	dispatch_block_t blockB = ^{
		DDLogVerbose(@"Some log statement");
	};
	dispatch_block_t blockC = ^{
		DDLogVerbose(@"Some log statement");
	};
	
	int i, count = 5;
	
	for (i = 0; i < count; i++)
	{
		dispatch_async(downloadingQueue, blockA);
		dispatch_async(parsingQueue,     blockB);
		dispatch_async(processingQueue,  blockC);
	}
	
	dispatch_queue_t bgq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
	dispatch_queue_t lgq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	dispatch_queue_t dgq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_queue_t hgq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	
	dispatch_block_t blockD = ^{
		DDLogVerbose(@"Some log statement");
	};
	
	for (i = 0; i < count; i++)
	{
		dispatch_async(bgq, blockD);
		dispatch_async(lgq, blockD);
		dispatch_async(dgq, blockD);
		dispatch_async(hgq, blockD);
	}
}

@end
