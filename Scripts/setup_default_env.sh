#!/usr/bin/env bash

# -e: Fail if command fails
# -x: print commands with expanded arguments
# -o pipefail: check each command's exit code in a pipe
set -exo pipefail

DEFAULT_PLATFORM="iOS Simulator"
DEFAULT_NAME="iPhone 8"
DEFAULT_SDK="iphonesimulator"

DEFAULT_IOS_OS="12.1"
DEFAULT_WATCH_OS="4.2"
DEFAULT_MAC_OS="10.14"
DEFAULT_TV_OS="12.0"

if [ -z "$PLATFORM" ]; then
	echo "\$PLATFORM not set, using $DEFAULT_PLATFORM"
	PLATFORM="$DEFAULT_PLATFORM"
fi

if [ -z "$OS" ]; then
	echo "\$OS not set, using $DEFAULT_IOS_OS"
	OS="$DEFAULT_IOS_OS"
fi

if [ -z "$NAME" ]; then
	echo "\$NAME not set, using $DEFAULT_NAME"
	NAME="$DEFAULT_NAME"
fi

if [ -z "$SDK" ]; then
	echo "\$SDK not set, using $DEFAULT_SDK"
	SDK="$DEFAULT_SDK"
fi
