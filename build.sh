#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP=Pomodoro.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
swiftc -O -swift-version 5 -parse-as-library \
    -target "$(uname -m)-apple-macosx13.0" \
    Sources/Pomodoro/*.swift \
    -o "$APP/Contents/MacOS/Pomodoro"
cp Resources/Info.plist "$APP/Contents/"
codesign --force -s - "$APP"
echo "Built $APP — run: open $APP  (or copy to /Applications)"
