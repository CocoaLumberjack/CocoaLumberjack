//
//  ViewController.m
//  CaptureASL
//
//  Created by Ernesto Rivera on 2014/03/20.
//
//

#import "ViewController.h"

static int count = 0;

@implementation ViewController

- (IBAction)log:(id)sender
{
    NSLog(@"ASL test message %d", count++);
}

@end
