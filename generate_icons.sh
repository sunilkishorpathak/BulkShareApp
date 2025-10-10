#!/bin/bash

# Script to generate iOS app icons from a single 1024x1024 source image
# Usage: ./generate_icons.sh path/to/source_image.png

if [ $# -eq 0 ]; then
    echo "❌ Error: Please provide the path to your source icon image (1024x1024 pixels)"
    echo "Usage: ./generate_icons.sh path/to/source_image.png"
    echo ""
    echo "Example: ./generate_icons.sh ~/Desktop/app_icon_1024.png"
    exit 1
fi

SOURCE_IMAGE="$1"
ICON_DIR="BulkMatesApp/BulkMatesApp/Assets.xcassets/AppIcon.appiconset"

# Check if source image exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "❌ Error: Source image file not found: $SOURCE_IMAGE"
    exit 1
fi

# Check if directory exists
if [ ! -d "$ICON_DIR" ]; then
    echo "❌ Error: AppIcon.appiconset directory not found: $ICON_DIR"
    exit 1
fi

echo "🎨 Generating iOS app icons from: $SOURCE_IMAGE"
echo "📁 Output directory: $ICON_DIR"
echo ""

# Function to generate icon
generate_icon() {
    local size=$1
    local filename=$2
    echo "📱 Generating ${size}x${size} → $filename"
    sips -z $size $size "$SOURCE_IMAGE" --out "$ICON_DIR/$filename" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✅ Created: $filename"
    else
        echo "   ❌ Failed to create: $filename"
    fi
}

# Generate all required icon sizes
echo "🔄 Starting icon generation..."
echo ""

# iPhone icons (60pt)
generate_icon 120 "app-icon-60@2x.png"    # 60pt @2x = 120x120 (iPhone iOS 10+)
generate_icon 180 "app-icon-60@3x.png"    # 60pt @3x = 180x180 (iPhone iOS 10+)

# iPad icons (76pt)
generate_icon 76 "app-icon-76.png"        # 76pt @1x = 76x76 (iPad iOS 10+)
generate_icon 152 "app-icon-76@2x.png"    # 76pt @2x = 152x152 (iPad iOS 10+)

# iPad Pro icon (83.5pt)
generate_icon 167 "app-icon-83.5@2x.png"  # 83.5pt @2x = 167x167 (iPad Pro)

# App Store icon
generate_icon 1024 "app-icon-1024.png"    # 1024x1024 (App Store)

echo ""
echo "🎉 Icon generation complete!"
echo ""
echo "📋 Generated files:"
ls -la "$ICON_DIR"/*.png 2>/dev/null | awk '{print "   " $9 " (" $5 " bytes)"}'
echo ""
echo "✅ Your app should now have all required icon sizes for App Store submission."
echo "📝 Next steps:"
echo "   1. Open your project in Xcode"
echo "   2. Clean build folder (⌘+Shift+K)"
echo "   3. Build and archive for App Store submission"