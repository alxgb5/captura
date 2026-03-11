#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building Captura...${NC}"

SDK=$(xcrun --show-sdk-path)

# Create build directory structure
mkdir -p build/Captura.app/Contents/MacOS
mkdir -p build/Captura.app/Contents/Resources

# Compile
echo "Compiling..."
# Use readarray to handle paths with spaces safely
readarray -d '' SOURCES < <(find Captura -name "*.swift" | sort | tr '\n' '\0')
swiftc "${SOURCES[@]}" \
  -sdk $SDK -target arm64-apple-macos13.0 \
  -framework Cocoa -framework ScreenCaptureKit -framework AVFoundation -framework Vision \
  -o build/Captura.app/Contents/MacOS/Captura

if [ ! -f build/Captura.app/Contents/MacOS/Captura ]; then
    echo -e "${RED}❌ Compilation failed${NC}"
    exit 1
fi

# Create Info.plist if it doesn't exist
if [ ! -f build/Captura.app/Contents/Info.plist ]; then
    cat > build/Captura.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Captura</string>
    <key>CFBundleIdentifier</key>
    <string>com.alxgb.captura</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Captura</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSMainStoryboardFile</key>
    <string></string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSScreenCaptureUsageDescription</key>
    <string>Captura needs permission to capture your screen.</string>
</dict>
</plist>
EOF
fi

# Code sign (ad-hoc)
echo "Signing..."
codesign --force --deep --sign - build/Captura.app 2>/dev/null || true

# Verify signature
if codesign --verify --deep build/Captura.app 2>/dev/null; then
    echo -e "${GREEN}✅ Build complete and signed${NC}"
else
    echo -e "${YELLOW}⚠️  Build complete (signature verification may fail on first run)${NC}"
fi

# Run tests
echo "Running tests..."
swiftc \
  Tests/main.swift \
  Sources/CapturaCore/CaptureHistoryManager.swift \
  Sources/CapturaCore/FilenameGenerator.swift \
  Sources/CapturaCore/ImageExporter.swift \
  Sources/CapturaCore/PreferencesManager.swift \
  -sdk $(xcrun --show-sdk-path) \
  -target arm64-apple-macos13.0 \
  -framework Cocoa \
  -o /tmp/captura_tests && /tmp/captura_tests
