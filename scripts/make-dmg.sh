#!/bin/zsh
# Gera dist/ClaudeUsageBar-<versão>.dmg e .zip a partir de build/Claude Usage.app
set -e
cd "$(dirname "$0")/.."
VERSION=$(cat VERSION)
APP="build/Claude Usage.app"
[[ -d "$APP" ]] || { echo "Rode ./build.sh primeiro"; exit 1; }
mkdir -p dist
STAGE=$(mktemp -d)
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "dist/ClaudeUsageBar-$VERSION.dmg"
hdiutil create -volname "Claude Usage Bar" -srcfolder "$STAGE" -ov -format UDZO "dist/ClaudeUsageBar-$VERSION.dmg" >/dev/null
ditto -c -k --keepParent "$APP" "dist/ClaudeUsageBar-$VERSION.zip"
rm -rf "$STAGE"
(cd dist && shasum -a 256 ClaudeUsageBar-$VERSION.* > SHA256SUMS.txt)
echo "OK: dist/"; ls -1 dist
