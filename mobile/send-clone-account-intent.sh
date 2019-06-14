#!/bin/sh

account_id=$1

if [ -z "$account_id" ]; then
	echo "Usage: $0 ACCOUNT_ID"
	echo "Sends an Android intent to initiate the cloning of an account from the server."
	echo "ACCOUNT_ID is the hexadecimal account id."
	exit 1
fi

adb shell am start -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "https://flouze.bustany.org/mobile/clone?accountId=$account_id"
