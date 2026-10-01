#!/bin/bash
set -e

echo "🔨 Building DIFMPlayer for macOS (Release mode)..."
swift build -c release

BIN_DIR=$(swift build -c release --show-bin-path)
APP_DIR="build/DIFMPlayer.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "📦 Assembling ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp "${BIN_DIR}/DIFMPlayer" "${MACOS_DIR}/DIFMPlayer"
chmod +x "${MACOS_DIR}/DIFMPlayer"

cp "Sources/DIFMPlayer/Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"

if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

echo "🔏 Code signing DIFMPlayer.app (ad-hoc)..."
codesign -s - --force --deep "${APP_DIR}"

echo "✅ Successfully built: ${APP_DIR}"
echo "🚀 To run the app:"
echo "   open build/DIFMPlayer.app"
