//
//  ViewController.m
//  CaptureASL
//
//  Created by Ernesto Rivera on 2014/03/20.
//
//

#import "ViewController.h"
#import <asl.h>

@implementation ViewController
{
    int count;
    aslclient client;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    count = 0;
    client = asl_open(NULL, "CocoaLumberjack.CaptureASL", 0);
}

- (IBAction)log:(id)sender
{
    NSLog(@"ASL test message %d", count++);
}

- (IBAction)asl_log:(UIButton *)sender
{
    char *level = NULL;
    switch (sender.tag)
    {
        case ASL_LEVEL_EMERG   : level = "ASL_LEVEL_EMERG";   break;
        case ASL_LEVEL_ALERT   : level = "ASL_LEVEL_ALERT";   break;
        case ASL_LEVEL_CRIT    : level = "ASL_LEVEL_CRIT";    break;
        case ASL_LEVEL_ERR     : level = "ASL_LEVEL_ERR";     break;
        case ASL_LEVEL_WARNING : level = "ASL_LEVEL_WARNING"; break;
        case ASL_LEVEL_NOTICE  : level = "ASL_LEVEL_NOTICE";  break;
        case ASL_LEVEL_INFO    : level = "ASL_LEVEL_INFO";    break;
        case ASL_LEVEL_DEBUG   : level = "ASL_LEVEL_DEBUG";   break;
    }
    asl_log(client, NULL, (int)sender.tag, "%s test message %d", level, count++);
}

@end
