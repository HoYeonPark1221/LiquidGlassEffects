#!/bin/bash
# Builds Examples/GlassLab into a double-clickable GlassLab.app and a zip for a GitHub release.
#
#   Scripts/make-demo-app.sh
#
# The app is ad-hoc signed, so macOS asks the user to approve it on first launch. For a build
# anyone can open, sign with a Developer ID and notarize it:
#
#   DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)" \
#   NOTARY_PROFILE="my-notarytool-profile" \
#   Scripts/make-demo-app.sh
#
# NOTARY_PROFILE is a keychain profile made once with `xcrun notarytool store-credentials`.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
APP="$DIST/GlassLab.app"

# A universal build needs Xcode's toolchain, not just the Command Line Tools.
if [[ -z "${DEVELOPER_DIR:-}" && "$(xcode-select -p)" == */CommandLineTools && -d /Applications/Xcode.app ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

cd "$ROOT/Examples/GlassLab"
swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/GlassLab"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/GlassLab"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>io.github.hoyeonpark1221.glasslab</string>
    <key>CFBundleName</key><string>GlassLab</string>
    <key>CFBundleDisplayName</key><string>GlassLab</string>
    <key>CFBundleExecutable</key><string>GlassLab</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.2.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

codesign --force --deep --options runtime --sign "${DEVELOPER_ID:--}" "$APP"

ZIP="$DIST/GlassLab.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$APP"
    rm -f "$ZIP"
    ditto -c -k --keepParent "$APP" "$ZIP"
fi

echo "Built $APP"
echo "Zip:   $ZIP"
