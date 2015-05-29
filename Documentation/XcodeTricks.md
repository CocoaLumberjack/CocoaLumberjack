Automatically use different log levels per xcode configuration.

# Xcode 4+

Starting with Xcode 4, the `DEBUG` preprocessor macro is automatically set when building for debug (as opposed to release). So you can use this to automatically get different log levels depending upon your current build configuration.

```objective-c
#ifdef DEBUG
  static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
  static const DDLogLevel ddLogLevel = DDLogLevelWarn;
#endif
```

Nothing else is needed. (No changes required of your xcode project.) If the DEBUG macro isn't set in your project, it likely means you originally created the project with Xcode 3 (or before the DEBUG macro became standard). In that case, read on.

# Xcode 3

Xcode has powerful configuration tools that we can tap into to automatically use different log levels depending on whether we're compiling in Debug vs Release mode.

When we're done we'll be able to have code like this:

```objective-c
#ifdef CONFIGURATION_DEBUG
  static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
  static const DDLogLevel ddLogLevel = DDLogLevelWarn;
#endif
```

### Details

Open your Xcode project and go to:

Project -\> Edit **Project** Settings

Now change the configuration to **Debug Configuration**.

Filter on "preprocessor" so you can find the **Preprocessor Macros Not Used In Precompilation** setting.

Now add a **CONFIGURATION\_DEBUG** value to this setting.

Your project settings should look like this:

<a href="http://www.flickr.com/photos/100714763@N06/9575919913/" title="CocoaLumberjack_xcode1 by robbiehanson, on Flickr"><img src="http://farm8.staticflickr.com/7410/9575919913_4655514922_o.png" width="653" height="673" alt="CocoaLumberjack_xcode1"></a>

Next, switch the configuration to **Release Configuration**.

Now add a **CONFIGURATION\_RELEASE** to the **Preprocessor Macros Not Used In Precompilation** setting.

Your project settings should look like this:

<a href="http://www.flickr.com/photos/100714763@N06/9575920131/" title="CocoaLumberjack_xcode2 by robbiehanson, on Flickr"><img src="http://farm4.staticflickr.com/3808/9575920131_52625d8f01_o.png" width="653" height="673" alt="CocoaLumberjack_xcode2"></a>

And that's all there is to it. You're done!\

And this isn't limited to just logging.
You can use the `#ifdef CONFIGURATION_DEBUG` anywhere you want in your project if you feel the need to differentiate something between your debug and release builds.