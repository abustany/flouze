#!/bin/sh

set -e

ZIP_FILENAME=$1

if [ -z "$ZIP_FILENAME" ]; then
	echo "Usage: $0 flouze.zip"
	echo ""
	echo "Imports the translations from a CrowdIn archive (obtained by clicking Build and Download)."
	exit 1
fi

SUPPORTED_LOCALES=$(grep 'bool isSupported' $(dirname $0)/lib/localization.dart | grep -o '\[.\+\]' | sed 's/[^a-z]/ /g' | sed 's/ en //g')

for LOCALE in $SUPPORTED_LOCALES; do
	echo "Importing translations for locale $LOCALE..."
	unzip -p "$ZIP_FILENAME" "$LOCALE/intl_messages.arb" > $(dirname $0)/lib/l10n/intl_fr.arb
done

echo Done
