//
//  LogFile.h
//  lelib
//
//  Created by Petr on 01.12.13.
//  Copyright (c) 2013,2014 Logentries. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LOGFILE_BASENAME            @"lelog"

@interface LogFile : NSObject

- (id)initWithNumber:(NSInteger)number;

@property (nonatomic, assign) NSInteger orderNumber;
@property (nonatomic, assign) NSInteger bytesProcessed;

- (NSString*)logPath;

- (BOOL)remove;
- (void)changeOrderNumber:(NSInteger)newOrderNumber;

/*
 Write atomically position into mark file.
 */
- (void)markPosition:(NSInteger)position;

// returns zero if the file does not exist
- (NSUInteger)size;

+ (NSInteger)logFileNumber:(NSString*)filename;
+ (NSInteger)markFileNumber:(NSString*)filename;



@end
