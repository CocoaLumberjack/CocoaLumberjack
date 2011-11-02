This Xcode project demonstrates fine grained logging.  The Lumberjack framework supports much more than simple log levels.  For example, you might want to categorize your log statements according to functionality.  This would allow you to toggle log statements according to the modules you are currently developing.  For example:

DDLogEngine(@"Low oil");
DDLogRadio(@"Switching to FM2");

It could even be more advanced than this. You might have log levels within the separate log statements.  For example:

DDLogEngineWarn(@"Low oil");
DDLogRadioVerbose(@"Switching to FM2");

Then you could change log levels per module.

As you can see, the framework is very flexible. Each project may have different logging requirements, and you can customize the framework to match your needs.

This particular project demonstrates adding two new log statements based on functionality. They represent hypothetical timers which are critical to the application. The implementation of these timers also spans across multiple files, so there is a need to have central control over the log statements.

For more information, see the Wiki article:
https://github.com/robbiehanson/CocoaLumberjack/wiki/FineGrainedLogging