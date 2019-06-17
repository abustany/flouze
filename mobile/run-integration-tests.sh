#!/bin/sh

set -e

cd $(dirname $0)

# Ensure we have flouze-cli available
cargo build -p flouze-cli

# First test will create an account, populate and upload it to the test server
flutter -d android drive test_driver/create_populate_share.dart

# Clear app data
adb shell pm clear org.bustany.flouze

flutter -d android drive --no-build test_driver/clone.dart
