#!/usr/bin/env bash

export DEFAULT_PLATFORM="iOS Simulator"
export DEFAULT_NAME="iPhone 8"
export DEFAULT_SDK="iphonesimulator"

export DEFAULT_IOS_OS="12.1"
export DEFAULT_WATCH_OS="4.2"
export DEFAULT_MAC_OS="10.14"
export DEFAULT_TV_OS="12.0"

# -e: Fail if command fails
# -o pipefail: check each command's exit code in a pipe
set -exo pipefail

if [ -z "$PLATFORM" ]; then
	echo "\$PLATFORM not set, using $DEFAULT_PLATFORM"
	export PLATFORM="$DEFAULT_PLATFORM"
fi

if [ -z "$OS" ]; then
	echo "\$OS not set, using $DEFAULT_IOS_OS"
	export OS="$DEFAULT_IOS_OS"
fi

if [ -z "$NAME" ]; then
	echo "\$NAME not set, using $DEFAULT_NAME"
	export NAME="$DEFAULT_NAME"
fi

if [ -z "$SDK" ]; then
	echo "\$SDK not set, using $DEFAULT_SDK"
	export SDK="$DEFAULT_SDK"
fi

if [ -z "$TRAVIS" ]; then
	# https://stackoverflow.com/a/24399288
	# this script is included in other scripts to provide an accurate line number when said script errors
	# don't include this on travis, as this is rather hacky.

	set -o functrace
	function handle_error {
	    local retval=$?
	    local line=${last_lineno:-$1}
	    echo "Failed at $line: $BASH_COMMAND"
	    echo "Trace: " "$@"
	    exit $retval
	}
	if (( ${BASH_VERSION%%.*} <= 3 )) || [[ ${BASH_VERSION%.*} = 4.0 ]]; then
	        trap '[[ $FUNCNAME = handle_error ]] || { last_lineno=$real_lineno; real_lineno=$LINENO; }' DEBUG
	fi
	trap 'handle_error $LINENO ${BASH_LINENO[@]}' ERR
fi
