### Lumberjack is Fast & Simple, yet Powerful & Flexible.

It is similar in concept to other popular logging frameworks such as log4j, yet is designed specifically for Objective-C, and takes advantage of features such as multi-threading, grand central dispatch (if available), lockless atomic operations, and the dynamic nature of the Objective-C runtime.

### Lumberjack is Fast

In most cases it is an order of magnitude faster than NSLog.

### Lumberjack is Simple

It takes as little as a single line of code to configure lumberjack when your application launches. Then simply replace your NSLog statements with DDLog statements and that's about it. (And the DDLog macros have the exact same format and syntax as NSLog, so it's super easy.)

### Lumberjack is Powerful:

One log statement can be sent to multiple loggers, meaning you can log to a file and the console simultaneously. Want more? Create your own loggers (it's easy) and send your log statements over the network. Or to a database or distributed file system. The sky is the limit.

### Lumberjack is Flexible:

Configure your logging however you want. Change log levels per file (perfect for debugging). Change log levels per logger (verbose console, but concise log file). Change log levels per xcode configuration (verbose debug, but concise release). Have your log statements compiled out of the release build. Customize the number of log levels for your application. Add your own fine-grained logging. Dynamically change log levels during runtime. Choose how & when you want your log files to be rolled. Upload your log files to a central server. Compress archived log files to save disk space...

<br/>
This framework is for you if:

-   You're looking for a way to track down that impossible-to-reproduce bug that keeps popping up in the field.
-   You're frustrated with the super short console log on the iPhone.
-   You're looking to take your application to the next level in terms of support and stability.
-   You're looking for an enterprise level logging solution for your application (Mac or iPhone).

<br/>
**[Get started using Lumberjack](https://github.com/robbiehanson/CocoaLumberjack/wiki/GettingStarted)**<br/>
**[Learn more about Lumberjack](https://github.com/robbiehanson/CocoaLumberjack/wiki)**<br/>

### Requirements 
- Xcode 4.4 or later is required
- iOS 5 or later
- OS X 10.7 or later

<br/>
Can't find the answer to your question in any of the [wiki](https://github.com/robbiehanson/CocoaLumberjack/wiki) articles? Try the **[mailing list](http://groups.google.com/group/cocoalumberjack)**.
<br/>
<br/>
Love the project? Wanna buy me a coffee? (or a beer :D) [![donation](http://www.paypal.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=UZRA26JPJB3DA)
