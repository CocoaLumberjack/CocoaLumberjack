#!/usr/bin/env bash

# cd to our root source directory, no matter where we're called from
HOME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$HOME_DIR/.." || exit

source ./Scripts/setup_default_env.sh

test() {
	echo "Testing $1"

	xcodebuild test                                                         \
		-project "Tests/Tests.xcodeproj"                                    \
	 	-scheme "$1"                                                        \
	 	-sdk "$SDK"                                                         \
	 	-destination platform="$PLATFORM",OS="$OS",name="$NAME"             \
	| bundle exec xcpretty -c -f "$(bundle exec xcpretty-travis-formatter)"
} 

if [ "$PLATFORM" = "iOS Simulator" ]; then 
	test "iOS Tests"
else 
	test "OS X Tests"
fi
