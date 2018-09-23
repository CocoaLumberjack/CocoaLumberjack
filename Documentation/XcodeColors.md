It's sometimes helpful to color-coordinate your log messages. For example, you may want your error messages to print in red so they stick out.  
This is possible with `DDTTYLogger` and **XcodeColors**.

<a href="http://www.flickr.com/photos/100714763@N06/9576120087/" title="Screen Shot 2013-08-23 at 10.30.09 AM by robbiehanson, on Flickr"><img src="http://farm4.staticflickr.com/3755/9576120087_bf2a3cae91_c.jpg" width="800" height="568" alt="Screen Shot 2013-08-23 at 10.30.09 AM"></a>

## Install XcodeColors

**XcodeColors** is a simple plugin for Xcode.  
It allows you to use colors in the Xcode debugging console.

Full installation instructions can be found on the XcodeColors project page:  
https://github.com/robbiehanson/XcodeColors

But here's a summary:
- Download the plugin
- Slap it into the Xcode Plug-ins directory
- Restart Xcode

## Enable Colors

All it takes is one extra line of code to enable colors in Lumberjack:

```objc
// Standard lumberjack initialization
[DDLog addLogger:[DDTTYLogger sharedInstance]];

// And we also enable colors
[[DDTTYLogger sharedInstance] setColorsEnabled:YES];
```

The **default color scheme** (if you don't customize it) is:

- `DDLogError` : Prints in red
- `DDLogWarn`  : Prints in orange

However, **you can fully customize the color schemes** however you like!  
In fact, you can customize the foreground and/or background colors.  
And you can specify any RGB value you'd like.

```objc
// Let's customize our colors.
// DDLogInfo : Pink

#if TARGET_OS_IPHONE
UIColor *pink = [UIColor colorWithRed:(255/255.0) green:(58/255.0) blue:(159/255.0) alpha:1.0];
#else
NSColor *pink = [NSColor colorWithCalibratedRed:(255/255.0) green:(58/255.0) blue:(159/255.0) alpha:1.0];
#endif

[[DDTTYLogger sharedInstance] setForegroundColor:pink backgroundColor:nil forFlag:DDLogFlagInfo];

DDLogInfo(@"Warming up printer"); // Prints in Pink !
```

## XcodeColors and iOS

You may occasionally notice that colors don't work when you're debugging your app in the simulator. And you may also notice that your colors never work when debugging on the actual device. How do I fix it so it works everywhere, all the time?

You can fix it in a few seconds. Here's how.

- In Xcode bring up the Scheme Editor (Product -> Edit Scheme...)
- Select "Run" (on the left), and then the "Arguments" tab
- Add a new Environment Variable named "XcodeColors", with a value of "YES"

<a href="http://www.flickr.com/photos/100714763@N06/9578924278/" title="Screen Shot 2013-08-23 at 10.32.59 AM by robbiehanson, on Flickr"><img src="http://farm6.staticflickr.com/5330/9578924278_1aa7431003_c.jpg" width="800" height="530" alt="Screen Shot 2013-08-23 at 10.32.59 AM"></a>

Your colors should now work on the simulator and on the device, every single time.

### More information:

The XcodeColors plugin is automatically loaded by Xcode when Xcode launches. When XcodeColors runs, it sets the environment variable "XcodeColors" to "YES". Thus the Xcode application itself has this environment variable set.  

It is this environment variable that Lumberjack uses to detect whether XcodeColors is installed or not. Because if Lumberjack injects color information when XcodeColors isn't installed, then your log statements have a bunch of garbage characters in them.  

Now any application that Xcode launches inherits the environment variables from Xcode. So if you hit build-and-go, and Xcode launches the simulator for you automatically, then the colors will work. But if you manually launch the simulator, then it doesn't inherit environment variables from Xcode (because Xcode isn't the process' parent in this case). It's a similar problem when debugging on the actual device.

## Colors in the Terminal

If you ever do any debugging in the Terminal, then you're in luck! **DDTTYLogger supports color in terminals as well.**

If your shell supports color, the DDTTYLogger will automatically map your requested colors to the closest supported color by your shell. In most cases your terminal will be "xterm-256color", so your terminal will support 256 different colors, and you'll get a close match for whatever RGB values you configure.
