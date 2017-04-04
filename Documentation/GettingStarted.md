_Getting started with the CocoaLumberjack framework._

***

There are 3 steps to getting started with the logging framework:

1.  Add the CocoaLumberjack files to your project
2.  Access and configure the framework
3.  Convert your NSLog statements to use the CocoaLumberjack macros

### Add CocoaLumberjack to your project

#### CocoaPods

```ruby
	platform :ios, '8.0'
	pod 'CocoaLumberjack'
```

#### Carthage

* Cartfile
```
	github "CocoaLumberjack/CocoaLumberjack"
```

#### Manual installation

_Please note, installation via CocoaPods or Carthage is much simpler and recommended by the development team_

* Add in the CocoaLumberjack files to your project using git submodules

```
	git submodule add https://git@github.com/CocoaLumberjack/CocoaLumberjack.git
```

* Drag `CocoaLumberjack/Lumberjack.xcodeproj` into your project
* In your application target Build Phases
	* Add the framework you need
		* `CocoaLumberjack-macOS` or `CocoaLumberjackSwift-macOS` for macOS
		* `CocoaLumberjack-iOS` or `CocoaLumberjackSwift-iOS` for iOS
		* `CocoaLumberjack-tvOS` or `CocoaLumberjackSwift-tvOS` for tvOS
		* `CocoaLumberjack-watchOS` or `CocoaLumberjackSwift-watchOS` for watchOS
* Make this CocoaLumberjack framework a dependency for your application target
* Add a Copy Files phase to the application bundle 
	* This needs to specify the _Frameworks_ sub-folder
	* Drag in the CocoaLumberjack.framework from the Lumberjack.xcodeproj products group
	* _Note: be careful to include only your relevant platform product_

#### Manual installation (iOS static library)

Consider this method if you favour static libraries over frameworks or have to use the static library.

* Add in the CocoaLumberjack files to your project using git submodules

```
	git submodule add https://git@github.com/CocoaLumberjack/CocoaLumberjack.git
```

* Drag `CocoaLumberjack/Lumberjack.xcodeproj` into your project
* Make the `CocoaLumberjack-iOS-Static` a dependency for your application target
* Add the `CocoaLumberjack-iOS-Static` to the `Link Binary` phase
* Add `"$(BUILT_PRODUCTS_DIR)/include"` to the `Header Search Paths`

#### Even more manual installation

Consider this method if you want to more easily modify target build settings, have other complex needs or simply prefer to do things by hand.

* Download the CocoaLumberjack files using git clone

```
	git clone https://git@github.com/CocoaLumberjack/CocoaLumberjack.git
```

* Copy just the .m/.h files from CocoaLumberjack/Classes into your project
	* Including the .swift file if relevant
	* Ignore the contents of the CLI and Extensions folders for basic use
* Add a separate CocoaLumberjack static library target
	* This will build e.g. a libCocoaLumberjack.a static library
* From time-to-time, git pull, re-copy and commit the updated CocoaLumberjack files

### Access and configure the framework

* Access the CocoaLumberjack framework by adding the following lines to a precompiled header (.pch) file
	* _Note: newer Xcode projects do not create a .pch file by default but using one eases access to CocoaLumberjack through your project_
	* _Note: #defining LOG\_LEVEL\_DEF before #importing the framework is currently required, but has been under discussion in the early 2.x series_

```objective-c
#define LOG_LEVEL_DEF ddLogLevel
#import <CocoaLumberjack/CocoaLumberjack.h>
```

* Configure CocoaLumberjack (typically in the applicationDidFinishLaunching method)

A couple lines of code is all you need to get started:

```objective-c
[DDLog addLogger:[DDASLLogger sharedInstance]];
[DDLog addLogger:[DDTTYLogger sharedInstance]];
```

This will add a pair of "loggers" to the logging framework. In other words, your log statements will be sent to the Console.app and the Xcode console (just like a normal NSLog).

Part of the power of the logging framework is its flexibility. If you also wanted your log statements to be written to a file, then you could add and configure a file logger:

```objective-c
DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
fileLogger.logFileManager.maximumNumberOfLogFiles = 7;

[DDLog addLogger:fileLogger];
```

The above code tells the application to keep a week's worth of log files on the system.

You will also need to set a global log level for your application. This can be modified in different manners later (see the bottom of this document for more information).

To do this, simply define the `ddLogLevel` constant. One example of this may be in your .pch file like so:

```objective-c
static const DDLogLevel ddLogLevel = DDLogLevelDebug;
```

This global log level will be used as a default unless stated otherwise. See below for possible levels you can set this to.

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

Of course not! We all know what it's like to debug or add new features. You want verbose logging just for the part that you're currently working on. The CocoaLumberjack framework gives you per file debugging control. So you can change the log level on just that file you're editing.

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

The latest versions of CocoaLumberjack use ARC. If you're not using ARC in your project, learn how to properly flag the CocoaLumberjack files as ARC in your Xcode project on the [ARC](ARC.md) page.

### Learn More about CocoaLumberjack

This is just the tip of the iceberg.

Find out how to:

-   [Automatically use different log levels for your debug vs release builds](XcodeTricks.md)
-   [Tailor the log levels to suite your needs](CustomLogLevels.md)
-   [Filter logs based on logger settings](PerLoggerLogLevels.md)
-   [Write your own custom formatters](CustomFormatters.md)
-   [Write your own custom loggers](CustomLoggers.md)
-   [And more...](README.md)
