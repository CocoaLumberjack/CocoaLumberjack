//
//  DDASLLogCapture.h
//  Lumberjack
//
//  Created by Dario Ahdoot on 3/17/14.
//
//

#import <Foundation/Foundation.h>

@protocol DDLogger;

@interface DDASLLogCapture : NSObject

+ (void)start:(BOOL)isAsynchronous;
+ (void)stop;

@end
