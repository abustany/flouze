# Flouze, an app to keep track of expenses among friends

[![CircleCI](https://circleci.com/gh/abustany/flouze.svg?style=svg)](https://circleci.com/gh/abustany/flouze)

[Download prebuilt binaries here!](https://flouze.bustany.org)

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
- Synchronization (needs more testing)

The features currently being developed include:

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

The OpenSSL development headers are required for compilation to succeed, the
package is named `openssl-devel` on Fedora and `libssl-dev` on Debian
derivatives. Installing this package is only needed if you want to build the
flouze CLI for the host architecture, for cross compilation the build scripts
will take care of downloading and building OpenSSL for Android.

The Rust library needs to be cross-compiled for all supported Android targets
before building the mobile app. The `generate-toolchains.sh` script in
`flouze_flutter/` needs to be run once to create standalone versions of the
toolchains contained in the Android NDK (which needs to be installed
beforehand). Once this is in place, the `build-openssl.sh` compiles OpenSSL for
various Android architectures, and the `build-jni-libs.sh` script in the same
directory builds the library for all targets.

After the native libraries are built, the normal Flutter commands can be used
from the `mobile/` folder to run/develop/debug the application.

## Synchronization server

The synchronization server URL is configured by the `mobile/assets/sync_server_uri.txt`
file. The file should contain a URL in the form `http://my.sync.server.tld:8080/`.

Flouze ships with a basic built-in server, accessible via the `serve` command of
`flouze-cli`.

## Sharing accounts between devices

Sharing is accomplished by registering a URL prefix with the application, and
interpreting the URLs under that prefix in the app. The URL used for sharing
needs *not* match the actual address of the synchronization server, in other
words it is a "vanity" URL, which however needs to validate [certain criteria
described in the Android Developer Documentation](https://developer.android.com/training/app-links/verify-site-associations),
notably the hosting of a `/.well-known/assetlinks.json` file.

The URL of the sharing server is configured by the `mobile/assets/share_server_uri.txt`
file. The file should contain a URL of the form `https://myapp.com/app`.

With the example above, any link starting with `https://myapp.com/app` will
activate the mobile application. As of now, the only action using such links is
the cloning of a remote account. Clicking a link of the form
`https://myapp.com/app/clone?accountId=[ACCOUNT_ID]`, where `[ACCOUNT_ID]` is
the UUID of the account, will activate the "Clone remote account" page of the
app. Remember, the server that will be contacted for the cloning is the
*synchronization server*, not the *sharing server*.

## Sentry

The mobile application can be configured to report crashes to Sentry (for now in
the Dart part only, the Rust part needs to be done). To do so, place your Sentry
DSN in `mobile/assets/sentry_dsn.txt`, and rebuild the application.
