### Use Log Level per Logger

If you need a different log level for every logger (i.e. if you have a custom logger like Crashlytics logger that should not log Info or Debug info), you can easily achieve this using the `DDLog.add(_, with:)` method in Swift, or `[DDLog addLogger:withLevel:]` method in Objective C.

#### Swift
```swift
DDLog.add(DDASLLogger.sharedInstance, with: DDLogLevel.info)
DDLog.add(DDTTYLogger.sharedInstance, with: DDLogLevel.debug)
```

#### Objective C
```objective-c
[DDLog addLogger:[DDASLLogger sharedInstance] withLevel:DDLogLevelInfo];
[DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelDebug];
```


You can still use the old method `+addLogger:`, this one uses the `DDLogLevelVerbose` as default, so no log is excluded.

You can retrieve the list of every logger and level associated to DDLog via the `[DDLog allLoggersWithLevel]` method.
