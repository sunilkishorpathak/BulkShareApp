#!/usr/bin/env python3
"""
BulkMates App Icon Generator - IMPROVED VERSION
Creates a 1024x1024px iOS app icon with clear person silhouettes
"""

from PIL import Image, ImageDraw
import math

def create_gradient_background(size, color_start, color_end):
    """Create a diagonal gradient from top-left to bottom-right at 135 degrees"""
    base = Image.new('RGB', size, color_start)
    top = Image.new('RGB', size, color_end)
    mask = Image.new('L', size)
    mask_data = []

    for y in range(size[1]):
        for x in range(size[0]):
            # Diagonal gradient (135 degrees)
            distance = (x + y) / (size[0] + size[1])
            mask_data.append(int(255 * distance))

    mask.putdata(mask_data)
    base.paste(top, (0, 0), mask)
    return base

def draw_shadow(draw, center, radius, shadow_offset=(0, 10), shadow_blur=30, shadow_opacity=0.3):
    """Draw a soft shadow for a circle"""
    x, y = center
    for i in range(shadow_blur, 0, -2):
        alpha = int(255 * shadow_opacity * (1 - i / shadow_blur))
        shadow_x = x + shadow_offset[0]
        shadow_y = y + shadow_offset[1]
        shadow_color = (0, 0, 0, alpha)

        # Draw on RGBA layer
        return shadow_color, shadow_x, shadow_y, i

def draw_checkmark(draw, center, width, height, color, stroke_width):
    """Draw a bold checkmark symbol"""
    x, y = center

    # Checkmark shape - two lines forming a check
    # Adjusted for better visibility

    # Starting point (left side)
    start_x = x - width * 0.4
    start_y = y

    # Middle point (bottom of checkmark)
    mid_x = x - width * 0.1
    mid_y = y + height * 0.3

    # End point (top right)
    end_x = x + width * 0.4
    end_y = y - height * 0.3

    # Draw the two lines with thick stroke
    draw.line([(start_x, start_y), (mid_x, mid_y)], fill=color, width=stroke_width, joint='curve')
    draw.line([(mid_x, mid_y), (end_x, end_y)], fill=color, width=stroke_width, joint='curve')

def draw_person_silhouette(draw, center, circle_radius, color):
    """
    Draw a clear, recognizable person silhouette
    - Circle for head
    - Rounded trapezoid for shoulders/body
    """
    x, y = center

    # HEAD - White circle
    head_radius = 17.5  # 35px diameter
    head_center_y = y - circle_radius * 0.25  # Position in upper part of circle

    draw.ellipse(
        [x - head_radius, head_center_y - head_radius,
         x + head_radius, head_center_y + head_radius],
        fill=color
    )

    # SHOULDERS/BODY - Rounded trapezoid shape
    # Create a trapezoid that's wider at bottom (shoulders)

    body_top_y = head_center_y + head_radius + 3  # Small gap below head
    body_height = 45
    body_top_width = 22.5  # 45px total width at top
    body_bottom_width = 32.5  # 65px total width at bottom

    # Create trapezoid points
    # Top-left, top-right, bottom-right, bottom-left
    body_points = [
        (x - body_top_width, body_top_y),  # Top-left
        (x + body_top_width, body_top_y),  # Top-right
        (x + body_bottom_width, body_top_y + body_height),  # Bottom-right
        (x - body_bottom_width, body_top_y + body_height),  # Bottom-left
    ]

    # Draw filled polygon for body
    draw.polygon(body_points, fill=color)

    # Add rounded corners by drawing circles at the corners
    corner_radius = 8
    # Top corners
    draw.ellipse([x - body_top_width - corner_radius, body_top_y - corner_radius,
                  x - body_top_width + corner_radius, body_top_y + corner_radius], fill=color)
    draw.ellipse([x + body_top_width - corner_radius, body_top_y - corner_radius,
                  x + body_top_width + corner_radius, body_top_y + corner_radius], fill=color)
    # Bottom corners
    draw.ellipse([x - body_bottom_width - corner_radius, body_top_y + body_height - corner_radius,
                  x - body_bottom_width + corner_radius, body_top_y + body_height + corner_radius], fill=color)
    draw.ellipse([x + body_bottom_width - corner_radius, body_top_y + body_height - corner_radius,
                  x + body_bottom_width + corner_radius, body_top_y + body_height + corner_radius], fill=color)

def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def create_bulkmates_icon_improved():
    """Create the improved BulkMates app icon with larger, clearer elements"""
    # Canvas size
    size = (1024, 1024)
    center = (512, 512)

    # Colors
    gradient_start = hex_to_rgb('#4CAF50')  # Green
    gradient_end = hex_to_rgb('#2196F3')    # Blue
    white = (255, 255, 255)
    checkmark_green = hex_to_rgb('#4CAF50')

    # Person circle colors and angles
    person_data = [
        (hex_to_rgb('#FF9800'), -90),   # Orange (12 o'clock)
        (hex_to_rgb('#9C27B0'), -30),   # Purple (2 o'clock)
        (hex_to_rgb('#FFE66D'), 30),    # Yellow (4 o'clock)
        (hex_to_rgb('#FF6B6B'), 90),    # Coral (6 o'clock)
        (hex_to_rgb('#4ECDC4'), 150),   # Teal (8 o'clock)
        (hex_to_rgb('#95E1D3'), 210),   # Mint green (10 o'clock)
    ]

    # Create base image with gradient
    img = create_gradient_background(size, gradient_start, gradient_end)

    # Create RGBA layer for shadows
    shadow_layer = Image.new('RGBA', size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer, 'RGBA')

    # Main drawing context
    draw = ImageDraw.Draw(img)

    # DRAW PERSON CIRCLES with shadows
    person_radius = 70  # 140px diameter
    circle_radius = 320  # Distance from center

    for color, angle in person_data:
        # Calculate position
        angle_rad = math.radians(angle)
        person_x = int(center[0] + circle_radius * math.cos(angle_rad))
        person_y = int(center[1] + circle_radius * math.sin(angle_rad))

        # Draw shadow on shadow layer
        shadow_blur = 20
        shadow_offset_y = 6
        for j in range(shadow_blur, 0, -1):
            alpha = int(64 * (1 - j / shadow_blur))  # 0.25 opacity max
            shadow_draw.ellipse(
                [person_x - person_radius - j//2,
                 person_y - person_radius - j//2 + shadow_offset_y,
                 person_x + person_radius + j//2,
                 person_y + person_radius + j//2 + shadow_offset_y],
                fill=(0, 0, 0, alpha)
            )

        # Draw colored circle
        draw.ellipse(
            [person_x - person_radius, person_y - person_radius,
             person_x + person_radius, person_y + person_radius],
            fill=color
        )

        # Draw person silhouette inside
        draw_person_silhouette(draw, (person_x, person_y), person_radius, white)

    # Composite shadow layer
    img = Image.alpha_composite(img.convert('RGBA'), shadow_layer).convert('RGB')
    draw = ImageDraw.Draw(img)

    # Create shadow layer for center circle
    center_shadow_layer = Image.new('RGBA', size, (0, 0, 0, 0))
    center_shadow_draw = ImageDraw.Draw(center_shadow_layer, 'RGBA')

    # DRAW CENTER WHITE CIRCLE shadow
    center_radius = 100  # 200px diameter
    shadow_blur = 30
    shadow_offset_y = 10
    for j in range(shadow_blur, 0, -1):
        alpha = int(77 * (1 - j / shadow_blur))  # 0.3 opacity max
        center_shadow_draw.ellipse(
            [center[0] - center_radius - j//2,
             center[1] - center_radius - j//2 + shadow_offset_y,
             center[0] + center_radius + j//2,
             center[1] + center_radius + j//2 + shadow_offset_y],
            fill=(0, 0, 0, alpha)
        )

    # Composite center shadow
    img = Image.alpha_composite(img.convert('RGBA'), center_shadow_layer).convert('RGB')
    draw = ImageDraw.Draw(img)

    # Draw center white circle
    draw.ellipse(
        [center[0] - center_radius, center[1] - center_radius,
         center[0] + center_radius, center[1] + center_radius],
        fill=white
    )

    # Draw bold checkmark in center
    draw_checkmark(draw, center, 120, 100, checkmark_green, 18)

    return img

if __name__ == '__main__':
    print("Creating improved BulkMates app icon...")
    print("Improvements:")
    print("  - Larger person circles (140px diameter)")
    print("  - Clear person silhouettes (head + shoulders)")
    print("  - Larger center circle (200px diameter)")
    print("  - Bolder checkmark (18px stroke)")
    print("  - Better shadows and spacing")
    print()

    icon = create_bulkmates_icon_improved()

    # Save the icon
    output_path = 'BulkMatesIcon-1024-Improved.png'
    icon.save(output_path, 'PNG')
    print(f"✅ Icon created successfully: {output_path}")
    print(f"   Size: {icon.size}")
    print(f"   Format: PNG (no transparency)")
    print()
    print("Next: Generating all required sizes...")
