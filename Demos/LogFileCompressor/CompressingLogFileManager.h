#import <Foundation/Foundation.h>
#import <CocoaLumberjack/DDFileLogger.h>


@interface CompressingLogFileManager : DDLogFileManagerDefault
{
    BOOL upToDate;
    BOOL isCompressing;
}

@end
