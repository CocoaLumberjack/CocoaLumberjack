#!/usr/bin/env bash

xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "BenchmarkIPhone" -configuration Release -sdk iphonesimulator | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "CaptureASL" -sdk iphonesimulator | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "RegisteredLoggingTest (Mobile)" -sdk iphonesimulator | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "TextXcodeColors (Mobile)" -sdk iphonesimulator | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "UniversalApp" -sdk iphonesimulator | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "WebServerIPhone" -sdk iphonesimulator | bundle exec xcpretty -c

xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "SQLiteLogger" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "CLI" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "BenchmarkMac" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "RegisteredLoggingTest (Desktop)" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "RollingTestMac" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "OverflowTestMac" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "ContextFilter" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "CoreDataLogger" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "CustomFormatters" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "CustomLogLevels" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "DispatchQueueLogger" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "FineGrainedLogging" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "GlobalLogLevel" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "LogFileCompressor" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "NonArcTest" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "PerUserLogLevels" | bundle exec xcpretty -c
xcodebuild build -workspace Demos/Demos.xcworkspace -scheme "TestXcodeColors (Desktop)" | bundle exec xcpretty -c