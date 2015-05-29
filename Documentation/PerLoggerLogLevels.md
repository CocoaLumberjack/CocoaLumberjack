### Use Log Level per Logger

If you need a different log level for every logger (i.e. if you have a custom logger like Crashlytics logger that should not log Info or Debug info), you can easily achieve this using the `[DDLog addLogger:withLevel:]` method.

```objective-c
[DDLog addLogger:[DDASLLogger sharedInstance] withLevel:DDLogLevelInfo];
[DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelDebug];
```

You can still use the old method `+addLogger:`, this one uses the `DDLogLevelVerbose` as default, so no log is excluded.