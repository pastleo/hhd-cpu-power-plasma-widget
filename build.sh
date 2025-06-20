#!/bin/bash

# Build script for HHD Control Plasmoid
# Creates a .plasmoid file for installation

set -e

PACKAGE_NAME="org.kde.plasma.desktoptdpcontrol"
VERSION=$(grep -o '"Version": "[^"]*"' metadata.json | cut -d'"' -f4)
OUTPUT_FILE="${PACKAGE_NAME}-${VERSION}.plasmoid"

echo "Building plasmoid package: $OUTPUT_FILE"

# Clean up any existing build artifacts
rm -f "$OUTPUT_FILE"
rm -rf build/

# Create temporary build directory
mkdir -p build

# Copy essential plasmoid files to build directory
echo "Copying plasmoid files..."
cp -r contents/ build/
cp metadata.json build/
cp metadata.desktop build/

# Create the .plasmoid file (which is just a zip file)
echo "Creating plasmoid package..."
cd build
zip -r "../$OUTPUT_FILE" . -x "*.git*" "*.DS_Store*" "*Thumbs.db*"
cd ..

# Clean up build directory
rm -rf build/

echo "Successfully created: $OUTPUT_FILE"
echo ""
echo "To install the plasmoid, run:"
echo "  plasmapkg2 --install $OUTPUT_FILE"
echo ""
echo "To upgrade an existing installation, run:"
echo "  plasmapkg2 --upgrade $OUTPUT_FILE"
echo ""
echo "To uninstall, run:"
echo "  plasmapkg2 --remove $PACKAGE_NAME"