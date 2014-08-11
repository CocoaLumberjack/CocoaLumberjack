#import "Stuff.h"
#import "MyLogging.h"


@implementation Stuff

+ (void)doStuff
{
    DDLogError(@"%@: Error", THIS_FILE);
    DDLogWarn(@"%@: Warn", THIS_FILE);
    DDLogInfo(@"%@: Info", THIS_FILE);
    DDLogVerbose(@"%@: Verbose", THIS_FILE);
}

@end
