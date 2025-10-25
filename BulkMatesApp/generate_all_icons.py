#!/usr/bin/env python3
"""
Generate all required iOS app icon sizes from the 1024x1024 master icon
"""

from PIL import Image
import os

def resize_icon(source_path, output_path, size):
    """Resize icon to specified size with high-quality resampling"""
    img = Image.open(source_path)
    img_resized = img.resize((size, size), Image.Resampling.LANCZOS)
    img_resized.save(output_path, 'PNG', optimize=True)
    print(f"✅ Created {output_path} ({size}x{size})")

def generate_all_icon_sizes():
    """Generate all required iOS icon sizes"""
    source_icon = 'BulkMatesIcon-1024.png'
    output_dir = 'BulkMatesApp/Assets.xcassets/AppIcon.appiconset'

    # Icon sizes required by iOS (from Contents.json)
    icon_sizes = {
        'app-icon-1024.png': 1024,      # App Store
        'app-icon-60@2x.png': 120,      # iPhone App Icon (60pt @2x)
        'app-icon-60@3x.png': 180,      # iPhone App Icon (60pt @3x)
        'app-icon-76.png': 76,          # iPad App Icon (76pt @1x)
        'app-icon-76@2x.png': 152,      # iPad App Icon (76pt @2x)
        'app-icon-83.5@2x.png': 167,    # iPad Pro App Icon (83.5pt @2x)
    }

    print(f"Generating all icon sizes from {source_icon}...")
    print(f"Output directory: {output_dir}\n")

    if not os.path.exists(source_icon):
        print(f"❌ Error: Source icon not found: {source_icon}")
        return False

    if not os.path.exists(output_dir):
        print(f"❌ Error: Output directory not found: {output_dir}")
        return False

    # Generate all sizes
    for filename, size in icon_sizes.items():
        output_path = os.path.join(output_dir, filename)
        try:
            resize_icon(source_icon, output_path, size)
        except Exception as e:
            print(f"❌ Error creating {filename}: {e}")
            return False

    print(f"\n✅ All icon sizes generated successfully!")
    print(f"   Total icons created: {len(icon_sizes)}")
    return True

if __name__ == '__main__':
    success = generate_all_icon_sizes()
    if success:
        print("\n📱 Next steps:")
        print("   1. Open Xcode")
        print("   2. Build and run the app to see the new icon")
        print("   3. The icon will appear on the home screen and in the App Store")
    else:
        print("\n❌ Icon generation failed. Please check the errors above.")
