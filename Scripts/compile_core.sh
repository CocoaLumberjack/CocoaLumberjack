#!/usr/bin/env bash

if [ -z "$PLATFORM" ] || [ -z "$OS" ]; then
	echo "PLATFORM or OS not set."
	exit 1
fi

if [ -z "$NAME" ] && ! [ "$PLATFORM" = "macOS" ]; then
	echo "Empty NAME only allowed on macOS."
fi

COMMON="-workspace Framework/Lumberjack.xcworkspace             \
        -destination \"platform=$PLATFORM,OS=$OS,name=$NAME\"   \
        -sdk $SDK                                               \
        -configuration Release | bundle exec xcpretty -c"

xcodebuild clean build -scheme "CocoaLumberjack-Static" "$COMMON"
xcodebuild clean build -scheme "CocoaLumberjack" "$COMMON"
xcodebuild clean build -scheme "CocoaLumberjackSwift" "$COMMON"