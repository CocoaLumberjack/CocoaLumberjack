// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2024, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
//   to endorse or promote products derived from this software without specific
//   prior written permission of Deusty, LLC.

#import "DDSampleFileManager.h"

@interface DDSampleFileManager ()

@property (nonatomic) NSString *header;

@end

@implementation DDSampleFileManager

- (instancetype)initWithLogFileHeader:(NSString *)header {
    self = [super initWithLogsDirectory:[NSTemporaryDirectory() stringByAppendingString:[NSUUID UUID].UUIDString]];
    if (self) {
        _header = header;
    }
    return self;
}

- (instancetype)initWithLogsDirectory:(NSString *)logsDirectory {
    return [self initWithLogFileHeader:nil];
}

- (NSString *)logFileHeader {
    return _header;
}

- (void)didArchiveLogFile:(NSString *)logFilePath wasRolled:(BOOL)wasRolled {
    _archivedLogFilePath = logFilePath;
}

- (NSString *)newLogFileName {
    if (self.customLogFileName) {
        return self.customLogFileName;
    }

    return [super newLogFileName];
}

- (BOOL)isLogFile:(NSString *)fileName {
    if (self.customLogFileName) {
        return [self.customLogFileName isEqualToString:fileName];
    }

    return [super isLogFile:fileName];
}

@end
