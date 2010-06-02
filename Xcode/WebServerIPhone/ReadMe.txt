This Xcode project demonstrates "live remote logging" in an iPhone application.  Imagine you are testing your application on several different devices.  Perhaps you're testing some networking code (where multiple devices communicate).  Or perhaps you're testing scenarios that require the device to be disconnected from power.  Irregardless of the circumstances, you'd like to see the application's log console in real time, while the application is running, but when the device is not directly connected to your machine.  This project accomplishes this goal.  Using a web browser, you can connect to the device, and view the log in real time as your application is running.

It works by using an embedded HTTP server. Thankfully, we didn't have to write our own embedded HTTP server. There is a mature open source implementation which provides a slim yet powerful and flexible server:
http://code.google.com/p/cocoahttpserver/

This server also supports optional features such as secure connections (SSL/TLS) and password protection (secure digest access).

When you connect to the embedded HTTP server running within the application, it adds a new logger to the logging framework.  This logger will output the log messages to your browser.

There are a couple different HTTP techniques that could be used to implement such a thing.  We chose to use WebSockets because it was easy, and because it is one of the most efficient ways to accomplish the task.  Unfortunately WebSockets are not currently supported by all browsers (at the time of this writing).  If WebSockets are not supported, the page should report this problem to you.  Google Chrome is known to work right now.

