#!/usr/bin/env bash

set -e

if [ -z "$PLATFORM" ] || [ -z "$OS" ] || [ -z "$SDK" ]; then
	echo "PLATFORM or OS not set."
	exit 1
fi

if [ -z "$NAME" ] && ! [ "$PLATFORM" = "macOS" ]; then
	echo "Empty NAME only allowed on macOS."
fi

test() {
	echo "Testing $1"

	xcodebuild test                                             \
		-project "Tests/Tests.xcodeproj"                        \
	 	-scheme "$1"                                            \
	 	-sdk "$SDK"                                             \
	 	-destination platform="$PLATFORM",OS="$OS",name="$NAME" \
	| bundle exec xcpretty -c
}

test "iOS Tests"
test "OS X Tests"
