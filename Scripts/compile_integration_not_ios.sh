#!/usr/bin/env bash

if [ -z "$PLATFORM" ] || [ -z "$OS" ]; then
	echo "PLATFORM or OS not set."
	exit 1
fi

if [ -z "$NAME" ] && ! [ "$PLATFORM" = "macOS" ]; then
	echo "Empty NAME only allowed on macOS."
fi

xcodebuild build                                           \
    -project Integration/Integration.xcodeproj             \
    -scheme "$INTEGRATION_TEST_PREFIX"SwiftIntegration     \
    -destination "platform=$PLATFORM,OS=$OS,name=$NAME"    \
    -sdk "$SDK"                                            \
    -configuration Release | bundle exec xcpretty -c