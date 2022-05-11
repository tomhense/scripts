#!/bin/sh

ADB='/bin/adb'
ADB_DEVICES="$("$ADB" devices | awk 'NR > 1 && NF>0 { printf "%s\t%s\n", $1, $5 }' | sed 's/model://g')"
ADB_DEVICES_COUNT=$(echo "$ADB_DEVICES" | wc -l)

if [ $ADB_DEVICES_COUNT -gt 1 ]; then
	SERIAL=$(echo "$ADB_DEVICES" | fzf | cut -f 1)
	"$ADB" -s "$SERIAL" "$@"
elif [ $ADB_DEVICES_COUNT = 1 ]; then
	echo $@
	"$ADB" "$@"
else
	echo 'No adb devices connected' >&2
	exit 2
fi

