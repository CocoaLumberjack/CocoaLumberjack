_Getting started with the lumberjack framework._

***

There are 3 steps to getting started with the logging framework:

1.  Add the lumberjack files to your project.
2.  Configure the framework.
3.  Convert your NSLog statements to use the Lumberjack macros

### Add LumberJack to your project

#### CocoaPods

```ruby
platform :ios, '5.0'
pod 'CocoaLumberjack'
```

#### Manual installation

	git submodule add git@github.com:CocoaLumberjack/CocoaLumberjack.git

* Drag `CocoaLumberjack/Framework/{Desktop/Mobile}/Lumberjack.xcodeproj` into your project
* In your App target Build Settings
	* Add to 'User Header Search Paths' `$(BUILD_ROOT)/../IntermediateBuildFilesPath/UninstalledProducts/include`
	* Set 'Always Search User Paths' to YES
* In your App target Build Phases
	* Add CocoaLumberjack static library target to 'Target Dependencies'
	* Add `libCocoaLumberjack.a` to 'Link Binary With Libraries'
* Include the framework in your source files with 

```objective-c
#import <CocoaLumberjack/CocoaLumberjack.h>
```

### Configure the framework

One of first things you'll want to do in your application is configure the logging framework. This is normally done in the applicationDidFinishLaunching method.

A couple lines of code is all you need to get started:

```objective-c
[DDLog addLogger:[DDASLLogger sharedInstance]];
[DDLog addLogger:[DDTTYLogger sharedInstance]];
```

This will add a pair of "loggers" to the logging framework. In other words, your log statements will be sent to the Console.app and the Xcode console (just like a normal NSLog).

Part of the power of the logging framework is its flexibility. If you also wanted your log statements to be written to a file, then you could add and configure a file logger:

```objective-c
fileLogger = [[DDFileLogger alloc] init];
fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
fileLogger.logFileManager.maximumNumberOfLogFiles = 7;

[DDLog addLogger:fileLogger];
```

The above code tells the application to keep a week's worth of log files on the system.

### Convert your NSLog statements to DDLog

The DDLog header file defines the macros that you will use to replace your NSLog statements. Essentially they look like this:

```objective-c
// Convert from this:
NSLog(@"Broken sprocket detected!");
NSLog(@"User selected file:%@ withSize:%u", filePath, fileSize);

// To this:
DDLogError(@"Broken sprocket detected!");
DDLogVerbose(@"User selected file:%@ withSize:%u", filePath, fileSize);
```

As you can see, the **DDLog macros have the exact same syntax as NSLog**.

So all you need to do is decide which log level each NSLog statement belongs to. By default, there are 5 options available:

-   DDLogError
-   DDLogWarn
-   DDLogInfo
-   DDLogDebug
-   DDLogVerbose

(You can also [customize the levels or the level names](CustomLogLevels.md). Or you can [add fine-grained control on top of or instead of simple levels](FineGrainedLogging.md).)

Which log level you choose per NSLog statement depends, of course, on the severity of the message.

These tie into the log level just as you would expect

-   If you set the log level to DDLogLevelError, then you will only see Error statements.
-   If you set the log level to DDLogLevelWarn, then you will only see Error and Warn statements.
-   If you set the log level to DDLogLevelInfo, you'll see Error, Warn and Info statements.
-   If you set the log level to DDLogLevelDebug, you'll see Error, Warn, Info and Debug statements.
-   If you set the log level to DDLogLevelVerbose, you'll see all DDLog statements.
-   If you set the log level to DDLogLevelOff, you won't see any DDLog statements.

Where do I set the log level? Do I have to use a single log level for my entire project?

Of course not! We all know what it's like to debug or add new features. You want verbose logging just for the part that you're currently working on. The lumberjack framework gives you per file debugging control. So you can change the log level on just that file you're editing.

(Of course there are many other advanced options, such as a global log level, per xcode configuration levels, per logger levels, etc. But we'll get to that in another article.)

Here's all it takes to convert your log statements:

```objective-c
// CONVERT FROM THIS

#import "Sprocket.h"

@implementation Sprocket

- (void)someMethod
{
    NSLog(@"Meet George Jetson");
}

@end

// TO THIS

#import "Sprocket.h"
#import "CocoaLumberjack.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@implementation Sprocket

- (void)someMethod
{
    DDLogVerbose(@"Meet George Jetson");
}

@end
```

Notice that the log level is declared as a constant. This means that DDLog statements above the log level threshold will be compiled out of your project (when your compiler has optimisations turned on, as it would for your release build).

### Automatic Reference Counting (ARC)

The latest versions of Lumberjack use ARC. If you're not using ARC in your project, learn how to properly flag the Lumberjack files as ARC in your Xcode project on the [ARC](ARC.md) page.

### Learn More about Lumberjack

This is just the tip of the iceberg.

Find out how to:

-   [Automatically use different log levels for your debug vs release builds](XcodeTricks.md)
-   [Tailor the log levels to suite your needs](CustomLogLevels.md)
-   [Filter logs based on logger settings](PerLoggerLogLevels.md)
-   [Write your own custom formatters](CustomFormatters.md)
-   [Write your own custom loggers](CustomLoggers.md)
-   [And more...](README.md)
