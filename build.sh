#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP=Tomatick.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
swiftc -O -swift-version 5 -parse-as-library \
    -target arm64-apple-macosx13.0 \
    Sources/Tomatick/*.swift \
    -o "$APP/Contents/MacOS/Tomatick"
cp Resources/Info.plist "$APP/Contents/"
codesign --force -s - "$APP"
echo "Built $APP — run: open $APP  (or copy to /Applications)"
