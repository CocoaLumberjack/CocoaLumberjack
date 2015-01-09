// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2014, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
// to endorse or promote products derived from this software without specific
// prior written permission of Deusty, LLC.

#import "DDFileAndLineNumberFormatter.h"

@implementation DDFileAndLineNumberFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *path = [NSString stringWithCString:logMessage->file encoding:NSASCIIStringEncoding];
    NSString *fileName = [path lastPathComponent];
    return [NSString stringWithFormat:@"%@:%d %@", fileName, logMessage->lineNumber, logMessage->logMsg];
}
@end