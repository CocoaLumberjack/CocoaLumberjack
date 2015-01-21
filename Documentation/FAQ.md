Frequently asked questions.

# Questions

### How can it be faster than NSLog when only outputting to the console?

> This simple answer is that NSLog is just slow. But the more technical answer involves the Apple System Logging (asl) facility, and the fact that the Lumberjack framework is able to reuse a single asl client connection, as opposed to opening and closing one for every single log message.

> For a more detailed explanation see the section entitled "A Better NSLog" in the [performance page](Performance.md).

### Does Lumberjack require Grand Central Dispatch?

> No. In fact one of the original requirements was that the framework must support iPhone 3.X which doesn't include GCD.

> And the performance of the framework without GCD is still excellent. See the [performance page](Performance.md) for a benchmark of the framework running on iPhone 3.1.3 on an iPhone 3GS.

### Where should I initialize/configure the lumberjack framework?

> The simple answer is that you should initialize the framework before you first use it. Since logging is one of those "set it and forget it" tasks, it is usually best if you do so first thing when your application launches. In most cases this means in your applicationDidFinishLaunching method. However, you may need to do so even earlier if you have custom code in init or awakeFromNib methods that executes before the application has finished launching.

> For information on configuring the logging framework, see the [getting started page](GettingStarted.md).
