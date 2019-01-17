#!/usr/bin/env bash

COMMON="-project Integration/Integration.xcodeproj            \
        -destination \"platform=$PLATFORM,OS=$OS,name=$NAME\" \
        -sdk $SDK                                             \
        -configuration Release | bundle exec xcpretty -c"

xcodebuild build -scheme "$INTEGRATION_TEST_PREFIXStaticLibraryIntegration" "$COMMON"
xcodebuild build -scheme "$INTEGRATION_TEST_PREFIXFrameworkIntegration" "$COMMON"
xcodebuild build -scheme "$INTEGRATION_TEST_PREFIXSwiftIntegration" "$COMMON"