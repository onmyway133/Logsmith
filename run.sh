#!/bin/bash
set -e

cd "$(dirname "$0")"
CONFIGURATION="${1:-debug}"
swift build -c "$CONFIGURATION"
BIN_PATH="$(swift build -c "$CONFIGURATION" --show-bin-path)"
APP="$BIN_PATH/Logsmith.app"

pkill -x Logsmith 2>/dev/null || true
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_PATH/Logsmith" "$APP/Contents/MacOS/Logsmith"

# Compile the Icon Composer icon into Assets.car and AppIcon.icns
xcrun actool Resources/AppIcon.icon \
    --compile "$APP/Contents/Resources" \
    --app-icon AppIcon \
    --platform macosx \
    --minimum-deployment-target 27.0 \
    --target-device mac \
    --output-partial-info-plist "$BIN_PATH/AppIcon-partial.plist" \
    > /dev/null

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Logsmith</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.onmyway133.Logsmith</string>
    <key>CFBundleName</key>
    <string>Logsmith</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>27.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

open "$APP"
