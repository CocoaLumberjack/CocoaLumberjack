#import "AppDelegate.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <CocoaLumberjack/DDDispatchQueueLogFormatter.h>

// Log levels: 0-off, 1-error, 2-warn, 3-info, 4-verbose
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;


@implementation AppDelegate
{
    dispatch_queue_t downloadingQueue;
    dispatch_queue_t parsingQueue;
    dispatch_queue_t processingQueue;
}

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if (NO)
    {
        // See what log statements look like *BEFORE* using DispatchQueueLogFormatter :(
    }
    else
    {
        // See what log statements look like *AFTER* using DispatchQueueLogFormatter :)
        
        DDDispatchQueueLogFormatter *formatter = [[DDDispatchQueueLogFormatter alloc] init];
        formatter.minQueueLength = 4;
        formatter.maxQueueLength = 0;
        
        [formatter setReplacementString:@"downloading" forQueueLabel:@"downloadingQueue"];
        [formatter setReplacementString:@"parsing"     forQueueLabel:@"parsingQueue"];
        [formatter setReplacementString:@"processing"  forQueueLabel:@"processingQueue"];
        
        [[DDTTYLogger sharedInstance] setLogFormatter:formatter];
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
    
    [NSThread detachNewThreadSelector:@selector(backgroundThread:) toTarget:self withObject:nil];
}

- (void)backgroundThread:(id)ignore
{
    @autoreleasepool {
        
        [[NSThread currentThread] setName:@"MyBgThread"];
        
        int i;
        for (i = 0; i < 5; i++)
        {
            DDLogVerbose(@"Some log statement");
        }
    }
}

@end
