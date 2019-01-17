#!/usr/bin/env bash

# cd to our root source directory, no matter where we're called from
HOME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$HOME_DIR/.." || exit

source ./Scripts/setup_default_env.sh

build_workspace() {
	echo "Building $3"

	# quoting $1 will break the script, take care
	xcodebuild $1 build                                                     \
        -verbose                                                            \
        -workspace "$2"                                                     \
        -scheme "$3"                                                        \
        -destination OS="$OS",name="$NAME"                                  \
	| bundle exec xcpretty -c
}

build_project() {
	echo "Building $3"

	# quoting $1 will break the script, take care
	xcodebuild $1 build                                                     \
        -verbose                                                            \
        -project "$2"                                                       \
        -scheme "$3"                                                        \
        -destination OS="$OS",name="$NAME"                                  \
	| bundle exec xcpretty -c
}

build_workspace "clean" "Framework/Lumberjack.xcworkspace" "CocoaLumberjack-Static"
build_workspace "clean" "Framework/Lumberjack.xcworkspace" "CocoaLumberjack"
build_workspace "clean" "Framework/Lumberjack.xcworkspace" "CocoaLumberjackSwift"

build_project "" "Integration/Integration.xcodeproj" "iOSStaticLibraryIntegration"
build_project "" "Integration/Integration.xcodeproj" "iOSFrameworkIntegration"
build_project "" "Integration/Integration.xcodeproj" "iOSSwiftIntegration"

SDK="watchsimulator"
build_project "" "Integration/Integration.xcodeproj" "watchOSSwiftIntegration"

OS="$DEFAULT_TV_OS"
NAME="Apple TV"
build_project "" "Integration/Integration.xcodeproj" "tvOSSwiftIntegration"

xcodebuild build                                                        \
    -verbose                                                            \
    -project "Integration/Integration.xcodeproj"                        \
    -scheme "macOSSwiftIntegration"                                     \
    -sdk "macosx"                                                       \
| bundle exec xcpretty -c
