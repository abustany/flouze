#!/bin/sh

PACKAGE=org.bustany.flouze

set -e

cd $(dirname $0)

# Ensure we have flouze-cli available
cargo build -p flouze-cli

# Ensure adb is running as root, since this is needed for reverse port
# forwarding.
adb root

if adb shell pm list packages $PACKAGE | grep $PACKAGE; then
	adb shell pm uninstall $PACKAGE
fi

# First test will create an account, populate and upload it to the test server
flutter -d AOSP drive test_driver/create_populate_share.dart

# Clear app data
adb shell pm clear $PACKAGE

flutter -d AOSP drive --no-build test_driver/clone.dart
