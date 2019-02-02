Common issues you may encounter and their solutions.

### Logging behavior is inconsistent in iOS Share/Other Extensions

When using logging to evaluate issues in iOS Extensions, logging sometimes works, but some messages are not logged, particularly if the extension crashes or otherwise encounters an error. This is very frustrating when trying to use logging to track down the problem.

iOS Extensions are sandboxed environments hosted within the sending application. If you double-Home to view the app list, you will see for instance that a Share Extension is not listed as an application - it is just a UIViewController presented within the host application itself. For security reasons, issue handling is especially rigid in this environment, and threading/async task handling has some odd side effects.

By default, for maximum performance, CocoaLumberjack logs messages asynchronously. This can cause problems in Extensions with reliable logging of the final messages before an exception is handled. To work around this, enable this compile-time setting either at the top of your Extension's entry code file or as a Preprocessor Macro:

```objc
#define LOG_ASYNC_ENABLED NO
```

In Swift there's a global variable you an set to achieve the same:
```swift
asyncLoggingEnabled = false
```

This will disable asynchronous logging just for the extension, improving its reliability there.

### NSConcreteStackBlock

Your application fails to launch, and you see a crash message that looks something like
> Dyld Error Message: Symbol not found: **NSConcreteStackBlock

This seems to be an issue with LLVM, and blocks in general. It seems to affect those using Xcode 3, and targeting either Mac OS X 10.5 or iOS 3.X, and perhaps using the LLVM compiler.

A solution was posted to [StackOverflow](http://stackoverflow.com/questions/3313786/ios-4-app-crashes-at-startup-on-ios-3-1-3-symbol-not-found-nsconcretestackblo), and states that you should specify the linker flag
```objc
-weak_library /usr/lib/libSystem.B.dylib
```

This was also reported in Issue \#10 (concerning Mac OS X 10.5), and the linker flag was reported to work.

### Xcode 4.4 or later required

**Problem:** Your application fails to build because of the Xcode modern syntax @{} for dictionaries ...

**Cause:** This is because Xcode 4.4 or later is required to process this.

**Solution:** Upgrade to the latest Xcode version.

**Mac OS X 10.6 solution:** If you still need to support Mac OS X 10.6, please use an older version of Lumberjack that can be built using an older Xcode
