#!/usr/bin/env bash

# cd to our root source directory, no matter where we're called from
HOME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$HOME_DIR/.." || exit

bash ./Scripts/setup_default_env.sh

build_workspace() {
	echo "Building $3"

	xcodebuild -verbose "$1" build                                          \
	 	-workspace "$2"                                                     \
	 	-scheme "$3"                                                        \
	 	-sdk "$SDK"                                                         \
	 	-destination platform="$PLATFORM",OS="$OS",name="$NAME"             \
	| bundle exec xcpretty -c -f "$(bundle exec xcpretty-travis-formatter)"
}

build_project() {
	echo "Building $3"

	xcodebuild -verbose "$1" build                                          \
	 	-project "$2"                                                       \
	 	-scheme "$3"                                                        \
	 	-sdk "$SDK"                                                         \
	 	-destination platform="$PLATFORM",OS="$OS",name="$NAME"             \
	| bundle exec xcpretty -c -f "$(bundle exec xcpretty-travis-formatter)"
}

build_workspace "clean" "Framework/Lumberjack.xcworkspace" "CocoaLumberjack-Static"
build_workspace "clean" "Framework/Lumberjack.xcworkspace" "CocoaLumberjack"
build_workspace "clean" "Framework/Lumberjack.xcworkspace" "CocoaLumberjackSwift"

build_project "" "Integration/Integration.xcodeproj" "iOSStaticLibraryIntegration"
build_project "" "Integration/Integration.xcodeproj" "iOSFrameworkIntegration"
build_project "" "Integration/Integration.xcodeproj" "iOSSwiftIntegration"

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
