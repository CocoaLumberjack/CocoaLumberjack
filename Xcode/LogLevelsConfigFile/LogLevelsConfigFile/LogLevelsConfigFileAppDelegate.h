//
//  LogLevelsConfigFileAppDelegate.h
//  LogLevelsConfigFile
//
//  Created by Robbie Hanson on 6/18/11.
//  Copyright 2011 Voalte. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LogLevelsConfigFileAppDelegate : NSObject <NSApplicationDelegate> {
@private
	NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
