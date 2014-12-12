//
//  LogEntriesLogger.h
//  Where's the Beef
//
//  Created by Craig Hughes on 12/12/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "DDLog.h"

@interface LogEntriesLogger : DDAbstractLogger

- (instancetype)initWithLogEntriesToken:(NSString *)token;

@property NSString *logEntriesToken;

@end
