#!/bin/sh

set -e

cd $(dirname $0)

# Ensure we have flouze-cli available
cargo build -p flouze-cli

# First test will create an account, populate and upload it to the test server
flutter drive test_driver/create_populate_share.dart

# Clear app data
adb shell pm clear org.bustany.flouze

flutter drive --no-build test_driver/clone.dart
