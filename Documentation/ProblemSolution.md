Common issues you may encounter and their solutions.

### NSConcreteStackBlock

Your application fails to launch, and you see a crash message that looks something like
> Dyld Error Message: Symbol not found: **NSConcreteStackBlock

This seems to be an issue with LLVM, and blocks in general. It seems to affect those using Xcode 3, and targeting either Mac OS X 10.5 or iOS 3.X, and perhaps using the LLVM compiler.

A solution was posted to [StackOverflow](http://stackoverflow.com/questions/3313786/ios-4-app-crashes-at-startup-on-ios-3-1-3-symbol-not-found-nsconcretestackblo), and states that you should specify the linker flag
```objective-c
-weak_library /usr/lib/libSystem.B.dylib
```

This was also reported in Issue \#10 (concerning Mac OS X 10.5), and the linker flag was reported to work.

### Xcode 4.4 or later required

**Problem:** Your application fails to build because of the Xcode modern syntax @{} for dictionaries ...

**Cause:** This is because Xcode 4.4 or later is required to process this.

**Solution:** Upgrade to the latest Xcode version.

**Mac OS X 10.6 solution:** If you still need to support Mac OS X 10.6, please use an older version of Lumberjack that can be built using an older Xcode