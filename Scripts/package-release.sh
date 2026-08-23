#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-Release}"
DERIVED_DATA="$ROOT/build"
APP="$DERIVED_DATA/Build/Products/$CONFIGURATION/ClipStack.app"
DIST="$ROOT/dist"

cd "$ROOT"

echo "==> Building ClipStack ($CONFIGURATION)..."
mkdir -p "$DERIVED_DATA"
BUILD_LOG="$DERIVED_DATA/build.log"
if ! xcodebuild \
  -scheme ClipStack \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  build >"$BUILD_LOG" 2>&1; then
  echo "!! Build failed. Last 80 lines:"
  tail -80 "$BUILD_LOG"
  exit 1
fi
tail -5 "$BUILD_LOG"

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
