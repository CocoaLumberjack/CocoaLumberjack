//
//  OverflowTestMacAppDelegate.h
//  OverflowTestMac
//
//  Created by Robbie Hanson on 5/10/10.
//

#import <Cocoa/Cocoa.h>

@interface OverflowTestMacAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *__unsafe_unretained window;
}

@property (unsafe_unretained) IBOutlet NSWindow *window;

@end
