
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>


#import <CoreFoundation/CoreFoundation.h>

#import "LeNetworkStatus.h"

@interface LeNetworkStatus () {
    
	SCNetworkReachabilityRef reachabilityRef;
}

- (void)callback;

@end

@implementation LeNetworkStatus

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
    LeNetworkStatus* networkStatus = (__bridge LeNetworkStatus*)info;
    [networkStatus callback];
}

- (void)callback
{
    [self.delegate networkStatusDidChange:self];
}

- (void)start
{
	SCNetworkReachabilityContext context = {0, (__bridge void*)self, NULL, NULL, NULL};
	if (!SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, &context)) return;
    SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
}

- (void)stop
{
	if (reachabilityRef == NULL) return;
    SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
}

- (id)init
{
    self = [super init];
    if (!self) return nil;
    
    struct sockaddr_in addr;
	bzero(&addr, sizeof(addr));
	addr.sin_len = sizeof(addr);
	addr.sin_family = AF_INET;
    
    reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&addr);
    if (reachabilityRef != NULL) [self start];
    
    return self;
}

- (void)dealloc
{
	[self stop];
	if (reachabilityRef != NULL) CFRelease(reachabilityRef);
}

- (BOOL)networkStatusForFlags:(SCNetworkReachabilityFlags)flags
{
	if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) return NO;
	if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) return YES;
	
	if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
		(flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
	{
			if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) return YES;
    }
	
	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) return YES;
    
	return NO;
}

- (BOOL)connected
{
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
	{
        return [self networkStatusForFlags:flags];
	}
    
	return YES;
}
@end
