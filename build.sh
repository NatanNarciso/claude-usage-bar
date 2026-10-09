#!/bin/zsh
# Gera "Claude Usage.app" (sem precisar do Xcode).
set -e
cd "$(dirname "$0")"
VERSION=$(cat VERSION)
mkdir -p .build
swiftc -O -parse-as-library -target arm64-apple-macosx14.0 Sources/ClaudeUsageBar/*.swift -o .build/ClaudeUsageBar
APP="build/Claude Usage.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/ClaudeUsageBar "$APP/Contents/MacOS/ClaudeUsageBar"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.natan.claudeusagebar</string>
<key>CFBundleName</key><string>Claude Usage</string>
<key>CFBundleExecutable</key><string>ClaudeUsageBar</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleVersion</key><string>$VERSION</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
echo "OK: $APP"

if [[ "$1" == "--install" ]]; then
  # Instala em ~/Applications (caminho fixo, necessário para abrir no login) e reinicia.
  pkill -x ClaudeUsageBar 2>/dev/null || true
  mkdir -p ~/Applications
  rm -rf ~/Applications/"Claude Usage.app"
  cp -R "$APP" ~/Applications/
  open ~/Applications/"Claude Usage.app"
  echo "Instalado em ~/Applications"
fi
