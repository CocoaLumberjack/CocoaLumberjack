Taking advantage of logging contexts.

# Introduction

Logging contexts allow you to define a particular context for a log message. This context is simply an integer that is transmitted to the logging framework along with the log message. Thus, you are free to define a context however you want.

Contexts can be used in a wide variety of ways. Here are a few examples.

Example 1:

Some applications are rather modular, and can easily be broken into several logical components. If each separate component of the application uses a different logging context, then it would be easy for the logging framework to detect which log messages are coming from which components. What you do with such information is entirely up to you. Perhaps you want to format them differently. Or perhaps you want to use a filter, such that only log messages from your widget component get saved to disk. The sky is the limit.

Example 2:

You are developing a framework for other developers to use in their application. Being a forward-thinking engineer, you wish to include exemplary logging. This will allow others to quickly learn how your framework operates (less questions), as well as easily diagnose and debug any problems they might encounter (more free patches). So you use Lumberjack, and ensure that your log messages have a custom context. This will allow application developers to easily manage the log statements coming from your framework.

# Details

Every log message that goes through the Lumberjack framework is turned into a DDLogMessage object. This object contains all kinds of juicy information:

```objective-c
@interface DDLogMessage : NSObject
{
    int logLevel;
    int logFlag;
    int logContext;
    NSString *logMsg;
    NSDate *timestamp;
    const char *file;
    const char *function;
    int lineNumber;
    mach_port_t machThreadID;
#if GCD_MAYBE_AVAILABLE
    char *queueLabel;
#endif
    // ...
}
```

You can use all this information to customize the format of your log messages. For more information, see the [[Custom Formatters | CustomFormatters]] page.

You'll also notice there is a "logContext" variable. Now, by default, the log context of every message is zero. However, this can easily be customized.

Example 2 above mentioned using Lumberjack in third party frameworks. A great example of this is the [CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer) project. This open-source library provides an embeddable and customizable HTTP server for Mac and iOS applications. Since the project is sizable, it includes extensive logging which enables its functionality to be very transparent for those using the project. Debugging a complex problem becomes a lot easier when you can crank up the log level and see exactly how HTTP requests are coming into the system and being processed.

The HTTP server project then defines its own log messages, using a custom context:

```objective-c
#define HTTP_LOG_CONTEXT 80

#define HTTPLogError(frmt, ...)     SYNC_LOG_OBJC_MAYBE(httpLogLevel, LOG_FLAG_ERROR,   HTTP_LOG_CONTEXT, frmt, ##__VA_ARGS__)
#define HTTPLogWarn(frmt, ...)     ASYNC_LOG_OBJC_MAYBE(httpLogLevel, LOG_FLAG_WARN,    HTTP_LOG_CONTEXT, frmt, ##__VA_ARGS__)
#define HTTPLogInfo(frmt, ...)     ASYNC_LOG_OBJC_MAYBE(httpLogLevel, LOG_FLAG_INFO,    HTTP_LOG_CONTEXT, frmt, ##__VA_ARGS__)
#define HTTPLogDebug(frmt, ...)     ASYNC_LOG_OBJC_MAYBE(httpLogLevel, LOG_FLAG_DEBUG,  HTTP_LOG_CONTEXT, frmt, ##__VA_ARGS__)
#define HTTPLogVerbose(frmt, ...)  ASYNC_LOG_OBJC_MAYBE(httpLogLevel, LOG_FLAG_VERBOSE, HTTP_LOG_CONTEXT, frmt, ##__VA_ARGS__)
```

*You may notice how easy it is to define your own custom log functions. For more information see the [[Custom Log Levels | CustomLogLevels]] page. If you want to get really advanced, see the [[Fine Grained Logging | FineGrainedLogging]] page.*

Now HTTP log messages are clearly identifiable in the code:

```objective-c
HTTPLogError(@"File not found - %@", filePath);
```

And further, each HTTP log message is identifiable outside the framework because every HTTP log message has a logging context of ` HTTP_LOG_CONTEXT `.