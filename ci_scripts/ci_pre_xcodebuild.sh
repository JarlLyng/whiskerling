#!/bin/sh

# Xcode Cloud runs this before every build; it looks for ci_scripts next to Whiskerling.xcodeproj.
# Sets a unique, rising build number from Xcode Cloud's own, so every TestFlight upload is accepted.
# Outside Xcode Cloud (CI_BUILD_NUMBER is unset) it does nothing. There is no crash-report or dSYM
# step on purpose: Whiskerling is in the Kids category and sends nothing (XCODE_CLOUD.md).

set -e

if [ -n "$CI_BUILD_NUMBER" ] && [ -n "$CI_PRIMARY_REPOSITORY_PATH" ]; then
    echo "Setting the build number to $CI_BUILD_NUMBER"
    cd "$CI_PRIMARY_REPOSITORY_PATH"
    agvtool new-version -all "$CI_BUILD_NUMBER"
else
    echo "Not in Xcode Cloud, leaving the build number unchanged."
fi
