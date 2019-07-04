#!/bin/sh

set -e

cd $(dirname $0)
mkdir -p lib/l10n
flutter pub pub run intl_translation:generate_from_arb --output-dir=lib/l10n --no-use-deferred-loading lib/localization.dart lib/l10n/intl_*.arb
