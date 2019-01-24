#!/usr/bin/env bash

# cd to our root source directory, no matter where we're called from
HOME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$HOME_DIR/.." || exit

source ./Scripts/setup_default_env.sh

if [ "$PLATFORM" = "iOS Simulator" ]; then 
	xcodebuild test                                                         \
		-project "Tests/Tests.xcodeproj"                                    \
	 	-scheme "iOS Tests"                                                 \
	 	-sdk "$SDK"                                                         \
	 	-destination platform="$PLATFORM",OS="$OS",name="$NAME"             \
	| bundle exec xcpretty -c -f "$(bundle exec xcpretty-travis-formatter)"

else

	xcodebuild test                                                         \
		-project "Tests/Tests.xcodeproj"                                    \
	 	-scheme "OS X Tests"                                                \
	 	-sdk "$SDK"                                                         \
	 	-destination platform="$PLATFORM"                                   \
	| bundle exec xcpretty -c -f "$(bundle exec xcpretty-travis-formatter)"
fi