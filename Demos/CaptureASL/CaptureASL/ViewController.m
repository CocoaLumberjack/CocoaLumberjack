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
        case 0  : level = "ASL_LEVEL_EMERG";    break;
        case 1  : level = "ASL_LEVEL_ALERT";    break;
        case 2  : level = "ASL_LEVEL_CRIT";     break;
        case 3  : level = "ASL_LEVEL_ERR";      break;
        case 4  : level = "ASL_LEVEL_WARNING";  break;
        case 5  : level = "ASL_LEVEL_NOTICE";   break;
        case 6  : level = "ASL_LEVEL_INFO";     break;
        case 7  : level = "ASL_LEVEL_DEBUG";    break;
    }
    asl_log(client, NULL, (int)sender.tag, "%s test message %d", level, count++);
}

@end
