//
//  ContextFilterAppDelegate.h
//  ContextFilter
//
//  Created by Robbie Hanson on 11/22/10.
//  Copyright 2010 Voalte. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ContextFilterAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *__unsafe_unretained window;
}

@property (unsafe_unretained) IBOutlet NSWindow *window;

@end
