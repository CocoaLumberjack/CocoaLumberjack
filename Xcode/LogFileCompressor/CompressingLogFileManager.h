#import <Foundation/Foundation.h>
#import "DDFileLogger.h"


@interface CompressingLogFileManager : DDLogFileManagerDefault
{
	BOOL upToDate;
	BOOL isCompressing;
}

@end
