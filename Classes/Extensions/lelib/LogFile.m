//
//  LogFile.m
//  lelib
//
//  Created by Petr on 01.12.13.
//  Copyright (c) 2013,2014 Logentries. All rights reserved.
//

#import "LogFile.h"
#import "LogFiles.h"
#import "lelib.h"

#define NAME_NUMBER_LENGTH          10
#define LOG_EXTENSION               @".log"
#define MARK_EXTENSION              @".mark"

@implementation LogFile

/*
 Pads file number with zeroes up tu NAME_NUMBER_LENGTH.
 */

+ (NSString*)filename:(NSInteger)orderNumber
{
    NSString* number = [NSString stringWithFormat:@"%ld", (long)orderNumber];
    NSInteger space = (NSInteger)(NAME_NUMBER_LENGTH - [number length]);
    NSMutableString* string = [NSMutableString stringWithCapacity:NAME_NUMBER_LENGTH];
    while (space > 0) {
        [string appendString:@"0"];
        space--;
    }
    
    [string appendString:number];
    return string;
}

+ (NSString*)logFilename:(NSInteger)orderNumber
{
    return [[self filename:orderNumber] stringByAppendingString:LOG_EXTENSION];
}

+ (NSString*)markFilename:(NSInteger)orderNumber
{
    return [[self filename:orderNumber] stringByAppendingString:MARK_EXTENSION];
}

+ (NSString*)logPath:(NSInteger)orderNumber
{
    return [[LogFiles logsDirectory] stringByAppendingFormat:@"/%@", [self logFilename:orderNumber]];
}

- (NSString*)logPath
{
    return [[self class] logPath:self.orderNumber];
}

+ (NSString*)markPath:(NSInteger)orderNumber
{
    return [[LogFiles logsDirectory] stringByAppendingFormat:@"/%@", [self markFilename:orderNumber]];
}

- (NSString*)markPath
{
    return [[self class] markPath:self.orderNumber];
}

- (BOOL)remove
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* logPath = [self logPath];

    NSError* error = nil;
    BOOL deleted;
    
    deleted = [fileManager removeItemAtPath:logPath error:&error];
    if (!deleted) {
        LE_DEBUG(@"Can't remove file at path '%@' with error %@", logPath, error);
        return NO;
    }
    
    NSString* markPath = [self markPath];
    if ([fileManager fileExistsAtPath:markPath]) {
        error = nil;
        deleted = [fileManager removeItemAtPath:markPath error:&error];
        if (!deleted) {
            LE_DEBUG(@"Can't remove file at path '%@' with error %@", logPath, error);
        }
    }
    
    return YES;
}

- (void)changeOrderNumber:(NSInteger)newOrderNumber
{
    NSString* oldLogPath = [[self class] logPath:self.orderNumber];
    NSString* oldMarkPath = [[self class] markPath:self.orderNumber];
    NSString* newLogPath = [[self class] logPath:newOrderNumber];
    NSString* newMarkPath = [[self class] markPath:newOrderNumber];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];

    // it is neccessary to remove old mark (which should not exist, but we need to be sure)
    if ([fileManager fileExistsAtPath:newMarkPath]) {
        NSError* error = nil;
        BOOL removed = [fileManager removeItemAtPath:newMarkPath error:&error];
        if (!removed) {
            LE_DEBUG(@"Can't remove file at path '%@' with error %@", newMarkPath, error);
            return;
        }
    }

    NSError* error = nil;
    BOOL moved = [fileManager moveItemAtPath:oldLogPath toPath:newLogPath error:&error];
    
    if (!moved) {
        LE_DEBUG(@"Can't move file from path '%@' to path '%@' with error %@", oldLogPath, newLogPath, error);
        return;
    }

    self.orderNumber = newOrderNumber; //changed after rename

    if ([fileManager fileExistsAtPath:oldMarkPath]) {
    
        NSError* l_error = nil;
        moved = [fileManager moveItemAtPath:oldMarkPath toPath:newMarkPath error:&l_error];
    
        if (!moved) {
            LE_DEBUG(@"Can't move file from path '%@' to path '%@' with error %@", oldMarkPath, newMarkPath, l_error);
        }
    }
}

- (NSUInteger)size
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    NSString* path = [self logPath];
    
    if (![fileManager fileExistsAtPath:path]) return 0;
    
    NSError* error = nil;
    NSDictionary *attributes = [fileManager attributesOfItemAtPath: path error: &error];
    if (!attributes) {
        LE_DEBUG(@"Can't get file '%@' attributes with error %@", path, error);
    }
    UInt32 result = (UInt32)[attributes fileSize];
    return result;
    
}

- (void)loadMark
{
    NSString* path = [self markPath];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        self.bytesProcessed = 0;
        return;
    }
    
    NSError* error = nil;
    NSString* mark = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:&error];
    if (error) {
        LE_DEBUG(@"Can't read mark file");
        self.bytesProcessed = 0;
        return;
    }

    self.bytesProcessed = [mark integerValue];
}

- (id)initWithNumber:(NSInteger)number
{
    self = [self init];
    if (!self) return nil;

    self.orderNumber = number;
    [self loadMark];
 
    return self;
}

+ (NSInteger)filePrefix:(NSString*)filename
{
    NSUInteger index = 0;
    NSUInteger length = [filename length];
    if (!length) return -1; // empty or nil  filename
    unsigned short c = [filename characterAtIndex:index++];
    while (index < length && '0' <= c && c <= '9') c = [filename characterAtIndex:index++];
    
     // we need a dot fter digits
    if (index == length) return -1;
    if (c != '.') return -1;
    
    NSString* number = [filename substringToIndex:index];
    return [number integerValue];
}

+ (NSInteger)numberForFile:(NSString*)filename withExtension:(NSString*)extension
{
    NSInteger number = [self filePrefix:filename];
    if (number < 0) return -1;
    
    // we know that there is a dot
    NSRange r = [filename rangeOfString:@"."];
    NSString* rest = [filename substringFromIndex:r.location];
    if (![rest isEqualToString:extension]) return -1;
    return number;
}

+ (NSInteger)logFileNumber:(NSString*)filename
{
    return [self numberForFile:filename withExtension:LOG_EXTENSION];
}

+ (NSInteger)markFileNumber:(NSString*)filename
{
    return [self numberForFile:filename withExtension:MARK_EXTENSION];
}

- (void)markPosition:(NSInteger)position
{
    NSString* markString = [NSString stringWithFormat:@"%ld", (long)position];
    NSString* markPath = [self markPath];
    NSError* error = nil;
    BOOL r = [markString writeToFile:markPath atomically:YES encoding:NSASCIIStringEncoding error:&error];
    if (!r) {
        LE_DEBUG(@"Error marking read position to file '%@'", error);
    }
    self.bytesProcessed = position;
}


@end
