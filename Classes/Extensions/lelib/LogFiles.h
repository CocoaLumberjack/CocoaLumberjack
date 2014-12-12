//
//  LogFiles.h
//  lelib
//
//  Created by Petr on 01.12.13.
//  Copyright (c) 2013,2014 Logentries. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LogFile.h"


@interface LogFiles : NSObject

@property (nonatomic, strong) NSMutableArray* logFiles;

+ (NSString*)logsDirectory;

/*
 Check all files, remove files which are obsolete and rename valid files.
 */
- (void)consolidate;
- (LogFile*)fileToWrite;

- (LogFile*)fileToRead;

- (LogFile*)fileWithNumber:(NSInteger)number;

@end
