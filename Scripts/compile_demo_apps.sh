#!/usr/bin/env bash

# cd to our root source directory, no matter where we're called from
HOME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$HOME_DIR/.." || exit

source ./Scripts/setup_default_env.sh

# source: https://stackoverflow.com/a/3352015/4080860
trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    echo "$var"
}

build() {
    xcodebuild build                                                         \
        -workspace "Demos/Demos.xcworkspace"                                 \
        -scheme "$1"                                                         \
    | bundle exec xcpretty -c -f "$(bundle exec xcpretty-travis-formatter)"
}

# tail -n +3 removes the first 3 lines
SCHEMES=$(xcodebuild -workspace Demos/Demos.xcworkspace/ -list | tail -n +3)

while read -r line; do
    echo "Building $line"
    build "$(trim "$line")"
done <<< "$SCHEMES"
