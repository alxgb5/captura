#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$REPO_ROOT/build/Captura.app"
DMG_PATH="$REPO_ROOT/dist/Captura.dmg"
TEMP_DIR=$(mktemp -d)

echo -e "${YELLOW}Creating DMG for Captura...${NC}"

# Verify app exists
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ Build not found. Run ./build.sh first${NC}"
    exit 1
fi

# Create dist directory
mkdir -p "$REPO_ROOT/dist"

# Create temporary DMG workspace
MOUNT_POINT="$TEMP_DIR/Captura"
mkdir -p "$MOUNT_POINT"

# Copy app
cp -r "$APP_PATH" "$MOUNT_POINT/"

# Create Applications symlink
ln -s /Applications "$MOUNT_POINT/Applications"

# Create DMG (500MB capacity, read/write)
echo "Creating disk image..."
hdiutil create -volname "Captura" \
    -srcfolder "$MOUNT_POINT" \
    -ov \
    -format UDRW \
    "$REPO_ROOT/dist/Captura-rw.dmg" > /dev/null

# Convert to read-only compressed
echo "Compressing..."
hdiutil convert "$REPO_ROOT/dist/Captura-rw.dmg" \
    -format UDZO \
    -o "$DMG_PATH" > /dev/null

# Clean up
rm "$REPO_ROOT/dist/Captura-rw.dmg"
rm -rf "$TEMP_DIR"

if [ -f "$DMG_PATH" ]; then
    SIZE=$(du -h "$DMG_PATH" | cut -f1)
    echo -e "${GREEN}✅ DMG created: $DMG_PATH ($SIZE)${NC}"
else
    echo -e "${RED}❌ DMG creation failed${NC}"
    exit 1
fi
