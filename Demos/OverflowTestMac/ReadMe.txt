This Xcode project demonstrates how the logging framework handles overflow.  That is, if asynchronous logging is enabled, and the application spits out log messages faster than the framework can process them, then what should the framework do?

The framework can optionally enforce a maximum queue size. This project tests this max queue size, and ensures the framework is properly enforcing it.

Detailed information can be found in DDLog's queueLogMessage:: method.

This is a unit test project.