#!/usr/bin/env bash

set -ex # exit on first error, and print commands with expansions

if [ -z "$PLATFORM" ] || [ -z "$OS" ]; then
	echo "PLATFORM or OS not set."
	exit 1
fi

if [ -z "$NAME" ] && ! [ "$PLATFORM" = "macOS" ]; then
	echo "Empty NAME only allowed on macOS."
	exit 1
fi

COMMON="-workspace Framework/Lumberjack.xcworkspace             \
        -destination \"platform=$PLATFORM,OS=$OS,name=$NAME\"   \
        -sdk $SDK                                               \
        -configuration Release"

xcodebuild clean build -scheme "CocoaLumberjack-Static" "$COMMON" | bundle exec xcpretty -c
xcodebuild clean build -scheme "CocoaLumberjack" "$COMMON" | bundle exec xcpretty -c
xcodebuild clean build -scheme "CocoaLumberjackSwift" "$COMMON" | bundle exec xcpretty -c

COMMON="-project Integration/Integration.xcodeproj            \
        -destination \"platform=$PLATFORM,OS=$OS,name=$NAME\" \
        -sdk $SDK                                             \
        -configuration Release"

xcodebuild build -scheme iOSStaticLibraryIntegration "$COMMON" | bundle exec xcpretty -c
xcodebuild build -scheme iOSFrameworkIntegration "$COMMON" | bundle exec xcpretty -c
xcodebuild build -scheme iOSSwiftIntegration "$COMMON" | bundle exec xcpretty -c

xcodebuild build -scheme watchOSSwiftIntegration "$COMMON" | bundle exec xcpretty -c
xcodebuild build -scheme tvOSSwiftIntegration "$COMMON" | bundle exec xcpretty -c
xcodebuild build -scheme macOSSwiftIntegration "$COMMON" | bundle exec xcpretty -c