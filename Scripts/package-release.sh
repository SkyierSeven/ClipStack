#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-Release}"
DERIVED_DATA="$ROOT/build"
APP="$DERIVED_DATA/Build/Products/$CONFIGURATION/ClipStack.app"
DIST="$ROOT/dist"

cd "$ROOT"

echo "==> Building ClipStack ($CONFIGURATION)..."
xcodebuild \
  -scheme ClipStack \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  build | tail -5

if [[ ! -d "$APP" ]]; then
  echo "!! App bundle not found: $APP"
  exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$APP/Contents/Info.plist")
ARCH=$(uname -m)
STAMP="ClipStack-${VERSION}-build${BUILD}-macOS-${ARCH}"

mkdir -p "$DIST"
ZIP="$DIST/${STAMP}.zip"
DMG="$DIST/${STAMP}.dmg"

echo "==> Creating zip..."
ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> Creating dmg..."
rm -f "$DMG"
hdiutil create \
  -volname "ClipStack" \
  -srcfolder "$APP" \
  -ov \
  -format UDZO \
  "$DMG" >/dev/null

echo "==> Done"
echo "    $ZIP"
echo "    $DMG"
