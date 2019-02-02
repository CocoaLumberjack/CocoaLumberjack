//
//  CoreDataLogger.m
//  CoreDataLogger
//
//  CocoaLumberjack Demos
//

#import "CoreDataLogger.h"
#import "LogEntry.h"

@interface CoreDataLogger (PrivateAPI)
- (void)validateLogDirectory;
- (void)createManagedObjectContext;
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CoreDataLogger

- (id)initWithLogDirectory:(NSString *)aLogDirectory
{
    if ((self = [super init]))
    {
        logDirectory = [aLogDirectory copy];
        
        [self validateLogDirectory];
        [self createManagedObjectContext];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private API
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)validateLogDirectory
{
    // Validate log directory exists or create the directory.
    
    BOOL isDirectory;
    if ([[NSFileManager defaultManager] fileExistsAtPath:logDirectory isDirectory:&isDirectory])
    {
        if (!isDirectory)
        {
            NSLog(@"%@: %@ - logDirectory(%@) is a file!", [self class], THIS_METHOD, logDirectory);
            
            logDirectory = nil;
        }
    }
    else
    {
        NSError *error = nil;
        
        BOOL result = [[NSFileManager defaultManager] createDirectoryAtPath:logDirectory
                                                withIntermediateDirectories:YES
                                                                 attributes:nil
                                                                      error:&error];
        if (!result)
        {
            NSLog(@"%@: %@ - Unable to create logDirectory(%@) due to error: %@",
                  [self class], THIS_METHOD, logDirectory, error);
            
            logDirectory = nil;
        }
    }
}

- (NSString *)logFilePath
{
    return [logDirectory stringByAppendingPathComponent:@"Log.sqlite"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Core Data
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel)
    {
        return managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Log" withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}

- (BOOL)addPersistentStore:(NSError **)errorPtr
{
    if (logDirectory == nil)
    {
        if (errorPtr)
        {
            NSString *errMsg = @"Invalid logDirectory";
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
            
            *errorPtr = [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:userInfo];
        }
        return NO;
    }
    
    NSURL *url = [NSURL fileURLWithPath:[self logFilePath]];
    
    NSPersistentStore *result = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                         configuration:nil
                                                                                   URL:url
                                                                               options:nil
                                                                                 error:errorPtr];
    return (result != nil);
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator)
    {
        return persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom)
    {
        NSLog(@"%@: %@ - No model to generate a store from", [self class], THIS_FILE);
        return nil;
    }
    
    if (logDirectory == nil)
    {
        return nil;
    }
    
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    NSError *error = nil;
    if (![self addPersistentStore:&error])
    {
        NSLog(@"%@: %@ - Error creating persistent store: %@", [self class], THIS_FILE, error);
        
        persistentStoreCoordinator = nil;
    }
    
    return persistentStoreCoordinator;
}

- (void)createManagedObjectContext
{
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator)
    {
        if (managedObjectContext == nil)
        {
            managedObjectContext = [[NSManagedObjectContext alloc] init];
            [managedObjectContext setPersistentStoreCoordinator:coordinator];
            [managedObjectContext setMergePolicy:NSOverwriteMergePolicy];
        }
        
        if (logEntryEntity == nil)
        {
            logEntryEntity = [NSEntityDescription entityForName:@"LogEntry"
                                          inManagedObjectContext:managedObjectContext];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Public API
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)clearLog
{
    dispatch_block_t block = ^{
        
        if (managedObjectContext == nil)
        {
            return;
        }
        
        @autoreleasepool {
        
            NSError *error = nil;
            
            [managedObjectContext reset];
            [persistentStoreCoordinator lock];
            
            NSPersistentStore *store = [[persistentStoreCoordinator persistentStores] lastObject];
            
            if (![persistentStoreCoordinator removePersistentStore:store error:&error])
            {
                NSLog(@"%@: %@ - Error removing persistent store: %@", [self class], THIS_METHOD, error);
            } 
            
            NSString *logFilePath = [self logFilePath];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:logFilePath])
            {
                if (![[NSFileManager defaultManager] removeItemAtPath:logFilePath error:&error])
                {
                    NSLog(@"%@: %@ - Error deleting log file: %@", [self class], THIS_METHOD, error);
                }
            }
            
            if (![self addPersistentStore:&error])
            {
                NSLog(@"%@: %@ - Error creating persistent store: %@", [self class], THIS_FILE, error);
            }
            
            [persistentStoreCoordinator unlock];
        
        }
    };
    
    if (dispatch_get_current_queue() == self.loggerQueue)
        block();
    else
        dispatch_async(self.loggerQueue, block);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark DDLogger
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)db_log:(DDLogMessage *)logMessage
{
    if (managedObjectContext == nil)
    {
        return NO;
    }
    
    LogEntry *logEntry = (LogEntry *)[[NSManagedObject alloc] initWithEntity:logEntryEntity
                                              insertIntoManagedObjectContext:managedObjectContext];
    
    logEntry.context   = @(logMessage->_context);
    logEntry.level     = @(logMessage->_flag);
    logEntry.message   = logMessage->_message;
    logEntry.timestamp = logMessage->_timestamp;
    
    
    return YES;
}

- (void)saveContext
{
    if ([managedObjectContext hasChanges])
    {
        NSError *error = nil;
        if (![managedObjectContext save:&error])
        {
            NSLog(@"%@: Error saving: %@ %@", [self class], error, [error userInfo]);
            
            // Since the save failed, we are forced to dump the log entries.
            // If we don't we risk an ever growing managedObjectContext,
            // as the unsaved changes sit around in RAM until either saved or dumped.
            
            [managedObjectContext rollback];
        }
    }
}

- (void)deleteOldLogEntries:(BOOL)shouldSaveWhenDone
{
    if (_maxAge <= 0.0)
    {
        // Deleting old log entries is disabled.
        // The superclass won't likely call us if this is the case, but we're being cautious.
        return;
    }
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"LogEntry"
                                              inManagedObjectContext:managedObjectContext];
    
    NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:(-1.0 * _maxAge)];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timestamp < %@", maxDate];
    
    NSUInteger batchSize = (_saveThreshold > 0) ? _saveThreshold : 500;
    NSUInteger count = 0;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:batchSize];
    [fetchRequest setPredicate:predicate];
    
    NSArray *oldLogEntries = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
    
    for (LogEntry *logEntry in oldLogEntries)
    {
        [managedObjectContext deleteObject:logEntry];
        
        if (++count >= batchSize)
        {
            [self saveContext];
        }
    }
    
    if (shouldSaveWhenDone)
    {
        [self saveContext];
    }
}

- (void)db_save
{
    [self saveContext];
}

- (void)db_delete
{
    [self deleteOldLogEntries:YES];
}

- (void)db_saveAndDelete
{
    [self deleteOldLogEntries:NO];
    [self saveContext];
}

@end
