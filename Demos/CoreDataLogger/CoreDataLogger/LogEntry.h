//
//  LogEntry.h
//  CoreDataLogger
//
//  CocoaLumberjack Demos
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface LogEntry : NSManagedObject

@property (nonatomic, strong) NSNumber * context;
@property (nonatomic, strong) NSNumber * level;
@property (nonatomic, strong) NSString * message;
@property (nonatomic, strong) NSDate   * timestamp;

@end
