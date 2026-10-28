#!/usr/bin/env bash
# Builds a universal Orbit.app into ./build (and a zip + dmg into ./dist).
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)}"
VERSION="${VERSION:-0.1.0}"
APP="build/Orbit.app"

swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Orbit"

[ -f Resources/AppIcon.icns ] || swift scripts/make-icon.swift

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Orbit"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
sed "s/__VERSION__/$VERSION/g" Resources/Info.plist > "$APP/Contents/Info.plist"
cp -R Resources/*.lproj "$APP/Contents/Resources/"

# A stable identity lets macOS keep the Accessibility permission across builds
# (ad-hoc signatures change every build, so the permission would reset). See scripts/setup-signing.sh.
if [ -z "${SIGN_IDENTITY:-}" ]; then
  SIGN_IDENTITY="$(security find-identity -p codesigning 2>/dev/null | awk -F'"' '/(Orbit|Soniq) Local Signing/ {print $2; exit}')"
fi
codesign --force --options runtime --timestamp=none --sign "${SIGN_IDENTITY:--}" "$APP"

mkdir -p dist
rm -f dist/Orbit.zip dist/Orbit.dmg
ditto -c -k --keepParent "$APP" dist/Orbit.zip
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -quiet -volname "Orbit" -srcfolder "$STAGE" -fs HFS+ -format UDZO dist/Orbit.dmg
rm -rf "$STAGE"
(cd dist && shasum -a 256 Orbit.zip Orbit.dmg > SHA256SUMS.txt)

echo "Built $APP (v$VERSION), dist/Orbit.zip and dist/Orbit.dmg"
