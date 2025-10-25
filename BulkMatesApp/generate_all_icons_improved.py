#!/usr/bin/env python3
"""
Generate all required iOS app icon sizes from the improved 1024x1024 master icon
"""

from PIL import Image
import os

def resize_icon(source_path, output_path, size):
    """Resize icon to specified size with high-quality resampling"""
    img = Image.open(source_path)
    img_resized = img.resize((size, size), Image.Resampling.LANCZOS)
    img_resized.save(output_path, 'PNG', optimize=True)
    print(f"✅ Created {os.path.basename(output_path)} ({size}x{size})")

def generate_all_icon_sizes():
    """Generate all required iOS icon sizes"""
    source_icon = 'BulkMatesIcon-1024-Improved.png'
    output_dir = 'BulkMatesApp/Assets.xcassets/AppIcon.appiconset'
    splash_output_dir = 'BulkMatesApp/Assets.xcassets/SplashIcon.imageset'

    # Icon sizes required by iOS
    icon_sizes = {
        'app-icon-1024.png': 1024,      # App Store
        'app-icon-60@2x.png': 120,      # iPhone App Icon (60pt @2x)
        'app-icon-60@3x.png': 180,      # iPhone App Icon (60pt @3x)
        'app-icon-76.png': 76,          # iPad App Icon (76pt @1x)
        'app-icon-76@2x.png': 152,      # iPad App Icon (76pt @2x)
        'app-icon-83.5@2x.png': 167,    # iPad Pro App Icon (83.5pt @2x)
    }

    print(f"Generating all icon sizes from improved master icon...")
    print(f"Source: {source_icon}")
    print()

    if not os.path.exists(source_icon):
        print(f"❌ Error: Source icon not found: {source_icon}")
        return False

    # Generate AppIcon sizes
    print("📱 Generating AppIcon.appiconset sizes:")
    for filename, size in icon_sizes.items():
        output_path = os.path.join(output_dir, filename)
        try:
            resize_icon(source_icon, output_path, size)
        except Exception as e:
            print(f"❌ Error creating {filename}: {e}")
            return False

    print()

    # Generate SplashIcon (for displaying in app)
    print("🖼️  Generating SplashIcon.imageset:")
    splash_path = os.path.join(splash_output_dir, 'splash-icon.png')
    try:
        resize_icon(source_icon, splash_path, 1024)  # Use full resolution for splash
    except Exception as e:
        print(f"❌ Error creating splash icon: {e}")
        return False

    print()
    print(f"✅ All icon sizes generated successfully!")
    print(f"   Total icons created: {len(icon_sizes) + 1}")
    print()
    print("📸 Icon sizes generated:")
    print("   - 1024x1024 (App Store)")
    print("   - 180x180 (iPhone 3x)")
    print("   - 120x120 (iPhone 2x)")
    print("   - 167x167 (iPad Pro)")
    print("   - 152x152 (iPad 2x)")
    print("   - 76x76 (iPad 1x)")
    print()
    print("🎯 Updated locations:")
    print("   - BulkMatesApp/Assets.xcassets/AppIcon.appiconset/")
    print("   - BulkMatesApp/Assets.xcassets/SplashIcon.imageset/")
    return True

if __name__ == '__main__':
    success = generate_all_icon_sizes()
    if success:
        print()
        print("═" * 70)
        print("✅ ICON UPDATE COMPLETE")
        print("═" * 70)
        print()
        print("The improved icons have been generated with:")
        print("  ✓ Larger person circles (140px diameter)")
        print("  ✓ Clear person silhouettes (head + shoulders)")
        print("  ✓ Larger center checkmark circle (200px)")
        print("  ✓ Bolder checkmark stroke (18px)")
        print("  ✓ Better shadows and visibility")
        print()
        print("Next steps:")
        print("  1. Open Xcode to view the new icons")
        print("  2. Build and run to see them on device/simulator")
        print("  3. Verify visibility at all sizes")
        print()
    else:
        print()
        print("❌ Icon generation failed. Please check the errors above.")
