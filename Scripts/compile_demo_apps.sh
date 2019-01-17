#!/usr/bin/env bash

# source: https://stackoverflow.com/a/3352015/4080860
trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    echo -n "$var"
}

build() {
    xcodebuild build                       \
        -workspace Demos/Demos.xcworkspace \
        -scheme "$1"                       \
        -configuration Release             \
        -sdk iphonesimulator               \
    | bundle exec xcpretty -c
}

# tail -n +3 removes the first 3 lines
SCHEMES=$(xcodebuild -workspace Demos/Demos.xcworkspace/ -list | tail -n +3)

while read -r line; do
    echo "Building $line"
    build "$(trim "$line")"
done <<< "$SCHEMES"
