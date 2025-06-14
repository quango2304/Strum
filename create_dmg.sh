#!/bin/bash

# Fixed DMG Creation Script for Strum
# This version ensures the app appears correctly in the DMG

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Strum"
DMG_NAME="Strum-1.0"
DMG_DIR="./dmg_temp"
DIST_DIR="./dist"
DMG_PATH="${DIST_DIR}/${DMG_NAME}.dmg"

echo -e "${BLUE}🎵 Creating DMG for ${APP_NAME}...${NC}"

# Check if app path is provided
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Usage: $0 /path/to/Strum.app${NC}"
    echo -e "${YELLOW}Example: $0 ~/Desktop/Strum.app${NC}"
    echo -e "${YELLOW}Or drag and drop the Strum.app onto this script${NC}"
    exit 1
fi

APP_PATH="$1"

# Remove trailing slash if present
APP_PATH="${APP_PATH%/}"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ Error: ${APP_PATH} not found!${NC}"
    echo -e "${YELLOW}Please provide the correct path to your Strum.app file.${NC}"
    exit 1
fi

# Verify it's actually a .app bundle
if [[ ! "$APP_PATH" == *.app ]]; then
    echo -e "${RED}❌ Error: ${APP_PATH} is not a .app bundle!${NC}"
    echo -e "${YELLOW}Please provide the path to the Strum.app file.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found app at: ${APP_PATH}${NC}"

# Get just the app name (e.g., "Strum.app" from "/path/to/Strum.app")
APP_BASENAME=$(basename "$APP_PATH")

# Create directories
echo -e "${BLUE}📁 Creating directories...${NC}"
mkdir -p "$DIST_DIR"
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

# Copy app to DMG directory with explicit name
echo -e "${BLUE}📦 Copying ${APP_BASENAME}...${NC}"
cp -R "$APP_PATH" "$DMG_DIR/$APP_BASENAME"

# Verify the app was copied correctly
if [ ! -d "$DMG_DIR/$APP_BASENAME" ]; then
    echo -e "${RED}❌ Error: App was not copied correctly to DMG directory${NC}"
    echo -e "${YELLOW}Contents of DMG directory:${NC}"
    ls -la "$DMG_DIR/"
    exit 1
fi

echo -e "${GREEN}✅ ${APP_BASENAME} copied successfully${NC}"

# Create Applications symlink for easy installation
echo -e "${BLUE}🔗 Creating Applications symlink...${NC}"
ln -s /Applications "$DMG_DIR/Applications"

# Show what will be in the DMG
echo -e "${BLUE}📋 DMG will contain:${NC}"
ls -la "$DMG_DIR/"

# Create DMG
echo -e "${BLUE}💿 Creating DMG...${NC}"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_PATH"

# Clean up
echo -e "${BLUE}🧹 Cleaning up...${NC}"
rm -rf "$DMG_DIR"

echo -e "${GREEN}✅ DMG created successfully!${NC}"
echo -e "${YELLOW}📤 Location: ${DMG_PATH}${NC}"

# Show file info
if [ -f "$DMG_PATH" ]; then
    echo -e "${BLUE}📊 File info:${NC}"
    ls -lh "$DMG_PATH"
    echo ""
    echo -e "${GREEN}🎉 Ready to share with your friend!${NC}"
    echo -e "${BLUE}📋 Instructions for your friend:${NC}"
    echo -e "1. Double-click the DMG file to mount it"
    echo -e "2. Drag ${APP_BASENAME} to the Applications folder"
    echo -e "3. Launch Strum from Applications or Spotlight"
    echo ""
    echo -e "${YELLOW}💡 Tip: You can test the DMG by double-clicking it now!${NC}"
fi
