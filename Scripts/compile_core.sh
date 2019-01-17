#!/usr/bin/env bash

set -e # exit on first error, and print commands with expansions

if [ -z "$PLATFORM" ] || [ -z "$OS" ] || [ -z "$SDK" ]; then
	echo "PLATFORM or OS not set."
	exit 1
fi

if [ -z "$NAME" ] && ! [ "$PLATFORM" = "macOS" ]; then
	echo "Empty NAME only allowed on macOS."
	exit 1
fi

build_workspace() {
	echo "Building $3"

	xcodebuild -verbose "$1" build                               \
	 	-workspace "$2"                                          \
	 	-scheme "$3"                                             \
	 	-sdk "$SDK"                                              \
	 	-destination platform="$PLATFORM",OS="$OS",name="$NAME"  \
	 	-configuration Release                                   \
	| bundle exec xcpretty -c
}

build_project() {
	echo "Building $3"
	
	xcodebuild -verbose "$1" build                               \
	 	-project "$2"                                            \
	 	-scheme "$3"                                             \
	 	-sdk "$SDK"                                              \
	 	-destination platform="$PLATFORM",OS="$OS",name="$NAME"  \
	 	-configuration Release                                   \
	| bundle exec xcpretty -c
}

build_workspace "clean" "Framework/Lumberjack.xcworkspace" "CocoaLumberjack-Static"
build_workspace "clean" "Framework/Lumberjack.xcworkspace" "CocoaLumberjack"
build_workspace "clean" "Framework/Lumberjack.xcworkspace" "CocoaLumberjackSwift"

build_project "" "Integration/Integration.xcodeproj" "" "iOSStaticLibraryIntegration"
build_project "" "Integration/Integration.xcodeproj" "" "iOSFrameworkIntegration"
build_project "" "Integration/Integration.xcodeproj" "" "iOSSwiftIntegration"

OS="$$DEFAULT_WATCH_OS"
SDK="watchSimulator$OS"
build_project "" "Integration/Integration.xcodeproj" "watchOSSwiftIntegration"

OS="$$DEFAULT_TV_OS"
SDK="appletvsimulator$OS"
NAME="Apple TV"
PLATFORM="tvOS Simulator"
build_project "" "Integration/Integration.xcodeproj" "tvOSSwiftIntegration"

OS="$DEFAULT_MAC_OS"
SDK="macOS$OS"
NAME=""
PLATFORM="macOS"
build_project "" "Integration/Integration.xcodeproj" "macOSSwiftIntegration"