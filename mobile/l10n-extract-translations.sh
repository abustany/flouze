#!/bin/sh

set -e

cd $(dirname $0)
mkdir -p lib/l10n
flutter pub pub run intl_translation:extract_to_arb --output-dir=lib/l10n lib/localization.dart
