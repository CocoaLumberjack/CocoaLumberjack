#!/usr/bin/env bash

if [ -z "$PLATFORM" ] || [ -z "$OS" ]; then
	echo "PLATFORM or OS not set."
	exit 1
fi

if [ -z "$NAME" ] && ! [ "$PLATFORM" = "macOS" ]; then
	echo "Empty NAME only allowed on macOS."
fi

COMMON="-project Tests/Tests.xcodeproj                          \
        -destination \"platform=$PLATFORM,OS=$OS,name=$NAME\"   \
        -sdk $SDK                                               \
        GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES                    \
        GCC_GENERATE_TEST_COVERAGE_FILES=YES                    \
        -configuration Release | bundle exec xcpretty -c"       \

xcodebuild test -scheme "iOS Tests" "$COMMON"
xcodebuild test -scheme "OS X Tests" "$COMMON"