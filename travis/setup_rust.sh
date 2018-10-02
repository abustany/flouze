#!/bin/bash

set -e

NIGHTLY_RELEASE="2018-07-18"
NIGHTLY_HASH="4f3c7a472"

export PATH="$HOME/.cargo/bin:$PATH"

# Install Rustup if needed
if ! which rustup >/dev/null 2>&1; then
  curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly-$NIGHTLY_RELEASE -y
fi

# Ensure that a nightly toolchain is installed

if ! rustup show | grep "rustc 1.29.0-nightly" | grep -q "$NIGHTLY_HASH"; then
  rustup toolchain install nightly-$NIGHTLY_RELEASE
fi

rustup default nightly-$NIGHTLY_RELEASE

target_add() {
  local arch=$1

  if ! rustup target list | grep installed | grep -q "^$arch"; then
    rustup target add $arch
  fi
}

target_add aarch64-linux-android
target_add armv7-linux-androideabi
target_add i686-linux-android
target_add x86_64-linux-android
