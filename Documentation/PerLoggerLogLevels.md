### Use Log Level per Logger

If you need a different log level for every logger (i.e. if you have a custom logger like Crashlytics logger that should not log Info or Debug info), you can easily achieve this using the `DDLog` `+addLogger:withLogLevel:` method.

```objective-c
[DDLog addLogger:[DDASLLogger sharedInstance] withLogLevel:LOG_LEVEL_INFO];
[DDLog addLogger:[DDTTYLogger sharedInstance] withLogLevel:LOG_LEVEL_DEBUG];
```

You can still use the old method `+addLogger:`, this one uses the LOG_LEVEL_VERBOSE as default, so no log is excluded.