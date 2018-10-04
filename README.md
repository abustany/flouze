# Flouze, an app to keep track of expenses among friends

[![CircleCI](https://circleci.com/gh/abustany/flouze.svg?style=svg)](https://circleci.com/gh/abustany/flouze)

Flouze is an open source group expense tracker. Whenever you're traveling with
other people, keeping track of who paid what and who owes whom quickly gets
complicated. Flouze helps keeping a log of all expenses, which can be
synchronized across several devices.

Another popular group expense tracking service supporting synchronization is
[Tricount](https://www.tricount.com/) which works really well but lacks the
following features:

- History view of all changes to an expense log (for auditing/fixing mistakes)
- Monthly statistics (useful with long running accounts)
- Open protocol (although they do seem to have an API)
- Open Source (what is their app doing with my data?)

Another good open source alternative is [Tricky Tripper](https://trickytripper.blogspot.com/),
but it lacks proper support for synchronization.

Flouze is also an exercise in mixing Rust (for the logic) and Flutter (for the
UI) in a mobile application.

## Status

Flouze is currently at an early stage of development, and supports the following
features:

- Support several accounts (expense logs)
- Adding/editing/deleting Transactions
- Balance view showing who owes whom

The features currently being developed include:

- Synchronization (basic support in the library, needs a server + UI work)
- Statistics per day/week/month for long running accounts (eg. shared flat)

## Compatibility

Rust and Flutter should allow targeting both Android and iOS as mobile platforms.
I currently only develop for Android, but the platform specific layer binding
Flutter to Rust (because of the [lack of FFI](https://github.com/flutter/flutter/issues/7053))
is really thin and should be trivial to port to Objective-C or Swift. There's
also a very basic CLI tool for interacting with Flouze accounts, that one should
work on all desktop platforms.

## Development

The main parts of this repository are:

- `lib/` the main Rust library holding all the shared logic
- `flouze_flutter/` a Flutter package exposing the Rust API to Flutter via
  Platform Channels
- `mobile/` the (pure Dart/Flutter) sources of the mobile app
- `cli/` a simple CLI tool to interact with Flouze account files

The Rust library needs to be cross-compiled for all supported Android targets
before building the mobile app. The `generate-toolchains.sh` script in
`flouze_flutter/` needs to be run once to create standalone versions of the
toolchains contained in the Android NDK (which needs to be installed
beforehand). Once this is in place, the `build-jni-libs.sh` script in the same
directory builds the library for all targets. At this point, Rust nightly is
required because [the sled library requires it for 32-bit support](https://github.com/spacejam/sled/pull/300).

After the native libraries are built, the normal Flutter commands can be used
from the `mobile/` folder to run/develop/debug the application.
