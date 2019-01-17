#!/usr/bin/env bash

# cd to our root source directory, no matter where we're called from
HOME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$HOME_DIR/.." || exit

bash ./Scripts/setup_default_env.sh

# -e: Fail if command fails
# -x: print commands with expanded arguments
# -o pipefail: check each command's exit code in a pipe
set -exo pipefail

if [ -z "$TRAVIS" ]; then
    set -o functrace
fi

build() {
    xcodebuild build                                                         \
        -workspace "Demos/Demos.xcworkspace"                                 \
        -scheme "$1"                                                         \
    | bundle exec xcpretty -c
}

# tail -n +3 removes the first 3 lines
SCHEMES=$(xcodebuild -workspace Demos/Demos.xcworkspace/ -list -json)

START_SCHEMES_LINE="\"schemes\" : ["
IS_INSIDE_SCHEME_ARRAY=0
END_SCHEMES_LINE="]"

while read -r line; do
    if [ "$END_SCHEMES_LINE" == "$line" ]; then
        IS_INSIDE_SCHEME_ARRAY=0
    fi

    if [ $IS_INSIDE_SCHEME_ARRAY -eq 1 ]; then
        if [[ "$line" == *"\"" ]]; then
            # the last line doesn't have a trailing ,
            build "${line:1:${#line}-2}"
        else
            build "${line:1:${#line}-3}"
        fi
    fi

    if [ "$START_SCHEMES_LINE" == "$line" ]; then
        IS_INSIDE_SCHEME_ARRAY=1
    fi
done <<< "$SCHEMES"
