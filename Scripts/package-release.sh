#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-Release}"
DERIVED_DATA="$ROOT/build"
APP="$DERIVED_DATA/Build/Products/$CONFIGURATION/ClipStack.app"
DIST="$ROOT/dist"
STAGING="$DERIVED_DATA/dmg-staging"

cd "$ROOT"

TEAM_ID="${APPLE_TEAM_ID:-${DEVELOPMENT_TEAM:-}}"
SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-}"
if [[ -n "$TEAM_ID" && -z "$SIGN_IDENTITY" ]]; then
  SIGN_IDENTITY="Developer ID Application"
fi

echo "==> Building ClipStack ($CONFIGURATION)..."
mkdir -p "$DERIVED_DATA"
BUILD_LOG="$DERIVED_DATA/build.log"

XCODE_ARGS=(
  -scheme ClipStack
  -configuration "$CONFIGURATION"
  -derivedDataPath "$DERIVED_DATA"
)

if [[ -n "$TEAM_ID" ]]; then
  echo "    Signing with team: $TEAM_ID"
  XCODE_ARGS+=(
    DEVELOPMENT_TEAM="$TEAM_ID"
    CODE_SIGN_IDENTITY="$SIGN_IDENTITY"
    CODE_SIGN_STYLE=Manual
  )
else
  echo "    Warning: no APPLE_TEAM_ID / DEVELOPMENT_TEAM — building unsigned (ad-hoc)."
  echo "    Users must right-click → Open, or run: xattr -cr /path/to/ClipStack.app"
fi

if ! xcodebuild "${XCODE_ARGS[@]}" build >"$BUILD_LOG" 2>&1; then
  echo "!! Build failed. Last 80 lines:"
  tail -80 "$BUILD_LOG"
  exit 1
fi
tail -5 "$BUILD_LOG"

if [[ ! -d "$APP" ]]; then
  echo "!! App bundle not found: $APP"
  exit 1
fi

if [[ -n "$TEAM_ID" ]]; then
  echo "==> Verifying app signature..."
  codesign --verify --deep --strict --verbose=2 "$APP"
  spctl -a -t exec -vv "$APP" || true
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
rm -rf "$STAGING"
mkdir -p "$STAGING"
ditto "$APP" "$STAGING/ClipStack.app"
ln -s /Applications "$STAGING/Applications"

rm -f "$DMG"
hdiutil create \
  -volname "ClipStack" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DMG" >/dev/null

if [[ -n "$TEAM_ID" && -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" && "${SKIP_NOTARIZATION:-}" != "1" ]]; then
  echo "==> Submitting dmg for notarization..."
  xcrun notarytool submit "$DMG" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait

  echo "==> Stapling notarization ticket..."
  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"
  spctl -a -t open --context context:primary-signature -vv "$DMG" || true
elif [[ -n "$TEAM_ID" ]]; then
  echo "    Skipping notarization (set APPLE_ID + APPLE_APP_SPECIFIC_PASSWORD to enable)."
fi

echo "==> Done"
echo "    $ZIP"
echo "    $DMG"
