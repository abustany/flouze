#!/bin/sh

# Builds the Rust part of the Flouze flutter plugin as a universal library and
# installs it in ios/Classes/lib.

set -e

cd $(dirname $0)

CARGO_ARGS=
LIB_DIR=debug

if [ "$1" == "--release" ]; then
	CARGO_ARGS="${CARGO_ARGS} --release"
	LIB_DIR=release
fi

cargo lipo -p flouze-flutter --targets aarch64-apple-ios,x86_64-apple-ios --features ios $CARGO_ARGS
cp ../target/universal/$LIB_DIR/libflouze_flutter.a ios/Classes/lib/libflouze_flutter_rust.a
