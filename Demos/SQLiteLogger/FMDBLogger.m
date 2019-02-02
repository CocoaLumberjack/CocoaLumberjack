//
//  FMDBLogger.m
//  SQLiteLogger
//
//  CocoaLumberjack Demos
//

#import "FMDBLogger.h"
#import "FMDatabase.h"

@interface FMDBLogger ()
- (void)validateLogDirectory;
- (void)openDatabase;
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface FMDBLogEntry : NSObject {
@public
    NSNumber * context;
    NSNumber * level;
    NSString * message;
    NSDate   * timestamp;
}

- (id)initWithLogMessage:(DDLogMessage *)logMessage;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation FMDBLogEntry

- (id)initWithLogMessage:(DDLogMessage *)logMessage
{
    if ((self = [super init]))
    {
        context   = @(logMessage->_context);
        level     = @(logMessage->_flag);
        message   = logMessage->_message;
        timestamp = logMessage->_timestamp;
    }
    return self;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation FMDBLogger

- (id)initWithLogDirectory:(NSString *)aLogDirectory
{
    if ((self = [super init]))
    {
        logDirectory = [aLogDirectory copy];
        
        pendingLogEntries = [[NSMutableArray alloc] initWithCapacity:_saveThreshold];
        
        [self validateLogDirectory];
        [self openDatabase];
    }
    
    return self;
}


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

- (void)openDatabase
{
    if (logDirectory == nil)
    {
        return;
    }
    
    NSString *path = [logDirectory stringByAppendingPathComponent:@"log.sqlite"];
    
    database = [[FMDatabase alloc] initWithPath:path];
    
    if (![database open])
    {
        NSLog(@"%@: Failed opening database!", [self class]);
        
        database = nil;
        
        return;
    }
    
    NSString *cmd1 = @"CREATE TABLE IF NOT EXISTS logs (context integer, "
                                                       "level integer, "
                                                       "message text, "
                                                       "timestamp double)";
    [database executeUpdate:cmd1];
    if ([database hadError])
    {
        NSLog(@"%@: Error creating table: code(%d): %@",
              [self class], [database lastErrorCode], [database lastErrorMessage]);
        
        database = nil;
    }
    
    NSString *cmd2 = @"CREATE INDEX IF NOT EXISTS timestamp ON logs (timestamp)";
    
    [database executeUpdate:cmd2];
    if ([database hadError])
    {
        NSLog(@"%@: Error creating index: code(%d): %@",
              [self class], [database lastErrorCode], [database lastErrorMessage]);
        
        database = nil;
    }
    
    [database setShouldCacheStatements:YES];
}

#pragma mark AbstractDatabaseLogger Overrides

- (BOOL)db_log:(DDLogMessage *)logMessage
{
    // You may be wondering, how come we don't just do the insert here and be done with it?
    // Is the buffering really needed?
    // 
    // From the SQLite FAQ:
    // 
    // (19) INSERT is really slow - I can only do few dozen INSERTs per second
    // 
    // Actually, SQLite will easily do 50,000 or more INSERT statements per second on an average desktop computer.
    // But it will only do a few dozen transactions per second. Transaction speed is limited by the rotational
    // speed of your disk drive. A transaction normally requires two complete rotations of the disk platter, which
    // on a 7200RPM disk drive limits you to about 60 transactions per second.
    // 
    // Transaction speed is limited by disk drive speed because (by default) SQLite actually waits until the data
    // really is safely stored on the disk surface before the transaction is complete. That way, if you suddenly
    // lose power or if your OS crashes, your data is still safe. For details, read about atomic commit in SQLite.
    // 
    // By default, each INSERT statement is its own transaction. But if you surround multiple INSERT statements
    // with BEGIN...COMMIT then all the inserts are grouped into a single transaction. The time needed to commit
    // the transaction is amortized over all the enclosed insert statements and so the time per insert statement
    // is greatly reduced.
    
    FMDBLogEntry *logEntry = [[FMDBLogEntry alloc] initWithLogMessage:logMessage];
    
    [pendingLogEntries addObject:logEntry];
    
    // Return YES if an item was added to the buffer.
    // Return NO if the logMessage was ignored.
    
    return YES;
}

- (void)db_save
{
    if ([pendingLogEntries count] == 0)
    {
        // Nothing to save.
        // The superclass won't likely call us if this is the case, but we're being cautious.
        return;
    }
    
    BOOL saveOnlyTransaction = ![database inTransaction];
    
    if (saveOnlyTransaction)
    {
        [database beginTransaction];
    }
    
    NSString *cmd = @"INSERT INTO logs (context, level, message, timestamp) VALUES (?, ?, ?, ?)";
    
    for (FMDBLogEntry *logEntry in pendingLogEntries)
    {
        [database executeUpdate:cmd, logEntry->context,
                                     logEntry->level,
                                     logEntry->message,
                                     logEntry->timestamp];
    }
    
    [pendingLogEntries removeAllObjects];
    
    if (saveOnlyTransaction)
    {
        [database commit];
        
        if ([database hadError])
        {
            NSLog(@"%@: Error inserting log entries: code(%d): %@",
                  [self class], [database lastErrorCode], [database lastErrorMessage]);
        }
    }
}

- (void)db_delete
{
    if (_maxAge <= 0.0)
    {
        // Deleting old log entries is disabled.
        // The superclass won't likely call us if this is the case, but we're being cautious.
        return;
    }
    
    BOOL deleteOnlyTransaction = ![database inTransaction];
    
    NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:(-1.0 * _maxAge)];
    
    [database executeUpdate:@"DELETE FROM logs WHERE timestamp < ?", maxDate];
    
    if (deleteOnlyTransaction)
    {
        if ([database hadError])
        {
            NSLog(@"%@: Error deleting log entries: code(%d): %@",
                  [self class], [database lastErrorCode], [database lastErrorMessage]);
        }
    }
}

- (void)db_saveAndDelete
{
    [database beginTransaction];
    
    [self db_delete];
    [self db_save];
    
    [database commit];
    
    if ([database hadError])
    {
        NSLog(@"%@: Error: code(%d): %@",
              [self class], [database lastErrorCode], [database lastErrorMessage]);
    }
}

@end
