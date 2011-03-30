#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LogEntry : NSManagedObject

@property (nonatomic, retain) NSNumber * context;
@property (nonatomic, retain) NSNumber * level;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSDate   * timestamp;

@end
