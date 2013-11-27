#import <Foundation/Foundation.h>
#import "DDAbstractDatabaseLogger.h"


@interface CoreDataLogger : DDAbstractDatabaseLogger <DDLogger>
{
  @private
    NSString *logDirectory;
    
    NSManagedObjectModel *managedObjectModel;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectContext *managedObjectContext;
    NSEntityDescription *logEntryEntity;
}

/**
 * Initializes an instance set to save it's CocoaBotLog.sqlite file to the given directory.
 * If the directory doesn't already exist, it is automatically created.
**/
- (id)initWithLogDirectory:(NSString *)logDirectory;

/**
 * Provides access to the thread-safe components of the core data stack.
 * 
 * Please note that NSManagedObjectContext is NOT thread-safe.
 * The managedObjectContext in use by this instance is only to be used on it's private dispatch_queue.
 * You must create your own managedObjectContext for your own use.
**/
@property (strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/**
 * Clears the log by removing the persistentStore from the persistentStoreCoordinator,
 * and deleting the Log.sqlite file from disk.
 * 
 * Important: If you have created your own managedObjectContext for the Log,
 * you MUST reset your context following an invocation of this method!
**/
- (void)clearLog;

@end
