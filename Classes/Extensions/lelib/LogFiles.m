//
//  LogFiles.m
//  lelib
//
//  Created by Petr on 01.12.13.
//  Copyright (c) 2013,2014 Logentries. All rights reserved.
//

#import "LogFiles.h"
#import "LELog.h"
#import "lelib.h"


#define CACHES_DIRECTORY_BASENAME       @"logentries"

@implementation LogFiles

+ (NSString*)cachesDirectory
{
    NSArray* directories = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    
    if (![directories count]) {
        LE_DEBUG(@"Could not find caches directory.");
        return nil;
    }
    
    NSURL* cachesDirectory = directories[0];
    return [cachesDirectory path];
}

+ (NSString*)logsDirectory
{
    return [[self cachesDirectory] stringByAppendingFormat:@"/%@", CACHES_DIRECTORY_BASENAME];
}

- (LogFile*)fileToWrite
{
    return [self.logFiles lastObject];
}

- (LogFile*)fileToRead
{
    if (![self.logFiles count]) return nil;
    return [self.logFiles objectAtIndex:0];
}

- (LogFile*)fileWithNumber:(NSInteger)number
{
    for (LogFile* logFile in self.logFiles) {
        if (logFile.orderNumber == number) return logFile;
    }
    
    return nil;
}

/* 
 Remove all mark files which does not have it's counterpart.
 */
- (void)consolidateMarks
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    NSArray* contents = [fileManager contentsOfDirectoryAtPath:[[self class] logsDirectory] error:&error];
    if (!contents) {
        LE_DEBUG(@"Can't get contents of logs directory.");
        return;
    }

    for (NSString* filename in contents) {
        NSInteger number = [LogFile markFileNumber:filename];
        if (number < 0) continue; // you are not my type
        LogFile* logFile = [self fileWithNumber:number];
        if (!logFile) {
            
            NSError* l_error = nil;
            NSString* path = [[[self class] logsDirectory] stringByAppendingFormat:@"/%@", filename];
            BOOL r = [fileManager removeItemAtPath:path error:&l_error];
            if (!r) {
                LE_DEBUG(@"Can't remove file '%@' with error %@.", filename, l_error);
            }
        }
    }
}

- (void)consolidate
{
    // if there are no files yet add one
    LogFile* lastLog = [self.logFiles lastObject];
    if (!lastLog) {
        
        LogFile* logFile = [LogFile new];
        logFile.orderNumber = 1;
        [self.logFiles addObject:logFile];
        return;
    }
    
    // if there is more than MAXIMUM_FILE_COUNT files remove first ones and rename the rest
    NSUInteger count = [self.logFiles count];
    NSInteger orderNumber = (NSInteger)(MAXIMUM_FILE_COUNT - count);
    if (orderNumber > 0) orderNumber = 0;
    NSUInteger index = 0;
    while (index < [self.logFiles count]) {
        LogFile* logFile = self.logFiles[index];
        orderNumber++;
        if (orderNumber <= 0) {
            
            BOOL removed = [logFile remove];
            if (removed) {
                [self.logFiles removeObjectAtIndex:index];
            }
            
            continue;
        }
        
        index++;
        if (logFile.orderNumber == orderNumber) continue;
        
        [logFile changeOrderNumber:orderNumber];
    }
    
    [self consolidateMarks];
}

- (BOOL)createDirectory:(NSString*)path
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    BOOL created = [fileManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
    
    if (!created) {
        LE_DEBUG(@"Can't create logentries directory '%@' with error %@", path, error);
    }
    return created;
}

// if the directory does not exists, create it
- (BOOL)checkLogsDirectory
{
    NSString* logsDirectoryPath = [[self class] logsDirectory];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    if (![fileManager fileExistsAtPath:logsDirectoryPath isDirectory:&isDirectory]) {
        return [self createDirectory:logsDirectoryPath];
    } else {
        if (!isDirectory) {
            LE_DEBUG(@"Can't create logentries directory '%@', file with same name already exists.", logsDirectoryPath);
            return NO;
        } else {
            // directory already exists
            return YES;
        }
    }
}

- (id)init
{
    self = [super init];
    if (!self) return nil;
    
    if (![self checkLogsDirectory]) return nil;
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    NSArray* contents = [fileManager contentsOfDirectoryAtPath:[[self class] logsDirectory] error:&error];
    if (!contents) {
        LE_DEBUG(@"Can't get contents of logs directory.");
        return nil;
    }
    
    self.logFiles = [[NSMutableArray alloc] initWithCapacity:[contents count] + 1];
    
    for (NSString* filename in contents) {
        NSInteger number = [LogFile logFileNumber:filename];
        if (number < 0) continue; // you are not my type
        LogFile* logFile = [[LogFile alloc] initWithNumber:number];
        [self.logFiles addObject:logFile];
    }
    
    [self.logFiles sortUsingComparator:^(LogFile* a, LogFile* b) {
        
        if (a.orderNumber < b.orderNumber) return NSOrderedAscending;
        if (a.orderNumber > b.orderNumber) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    return self;
}


@end
