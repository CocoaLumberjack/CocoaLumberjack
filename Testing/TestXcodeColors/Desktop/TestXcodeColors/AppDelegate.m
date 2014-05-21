#import "AppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface AppDelegate ()
- (void)demoColorTags;
@end

#pragma mark -

@implementation AppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // Standard lumberjack initialization
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // And we're going to enable colors
    
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    
    // Check out default colors:
    // Error : Red
    // Warn  : Orange
    
    DDLogError(@"Paper jam");
    DDLogWarn(@"Toner is low");
    DDLogInfo(@"Warming up printer (pre-customization)");
    DDLogVerbose(@"Intializing protcol x26 (pre-customization)");
    
    // Now let's do some customization:
    // Info  : Pink
    
  #if TARGET_OS_IPHONE
    UIColor *pink = [UIColor colorWithRed:(255/255.0) green:(58/255.0) blue:(159/255.0) alpha:1.0];
  #else
    NSColor *pink = [NSColor colorWithCalibratedRed:(255/255.0) green:(58/255.0) blue:(159/255.0) alpha:1.0];
  #endif
    
    [[DDTTYLogger sharedInstance] setForegroundColor:pink backgroundColor:nil forFlag:LOG_FLAG_INFO];
    
    DDLogInfo(@"Warming up printer (post-customization)");
    
    // Verbose: Gray
    
  #if TARGET_OS_IPHONE
    UIColor *gray = [UIColor grayColor];
  #else
    NSColor *gray = [NSColor grayColor];
  #endif
    
    [[DDTTYLogger sharedInstance] setForegroundColor:gray backgroundColor:nil forFlag:LOG_FLAG_VERBOSE];
    
    DDLogVerbose(@"Intializing protcol x26 (post-customization)");
    
    // Now let's get crazy
    
    [self demoColorTags];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Lumberjack is extermely flexible.
 * 
 * Below we're going to make a straight NSLog replacement that prints in color.
 * We're also going to demonstrate that log levels are not a requirement to use Lumberjack.
**/

static NSString *const PurpleTag = @"PurpleTag";

#define DDLogPurple(frmt, ...) LOG_OBJC_TAG_MACRO(NO, 0, 0, 0, PurpleTag, frmt, ##__VA_ARGS__)


- (void)demoColorTags
{
  #if TARGET_OS_IPHONE
    UIColor *purple = [UIColor colorWithRed:(64/255.0) green:(0/255.0) blue:(128/255.0) alpha:1.0];
  #else
    NSColor *purple = [NSColor colorWithCalibratedRed:(64/255.0) green:(0/255.0) blue:(128/255.0) alpha:1.0];
  #endif
    
    [[DDTTYLogger sharedInstance] setForegroundColor:purple backgroundColor:nil forTag:PurpleTag];
    
    DDLogPurple(@"I'm a purple log message.");
}

@end
