#!/usr/bin/env python3
"""
BulkMates App Icon Generator
Creates a 1024x1024px iOS app icon with "Circle of Friends" design
"""

from PIL import Image, ImageDraw, ImageFont
import math

def create_gradient_background(size, color_start, color_end):
    """Create a diagonal gradient from top-left to bottom-right"""
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

def draw_circle_with_shadow(draw, center, radius, fill_color, shadow_offset=(0, 8), shadow_blur=24):
    """Draw a circle with a drop shadow effect"""
    x, y = center
    # Shadow (we'll simulate this with multiple darker circles)
    shadow_color = (0, 0, 0, 40)  # Semi-transparent black
    for i in range(shadow_blur, 0, -2):
        alpha = int(40 * (1 - i / shadow_blur))
        shadow_x = x + shadow_offset[0]
        shadow_y = y + shadow_offset[1]
        draw.ellipse(
            [shadow_x - radius - i//2, shadow_y - radius - i//2,
             shadow_x + radius + i//2, shadow_y + radius + i//2],
            fill=(0, 0, 0, alpha)
        )

    # Main circle
    draw.ellipse(
        [x - radius, y - radius, x + radius, y + radius],
        fill=fill_color
    )

def draw_checkmark(draw, center, size, color, width):
    """Draw a checkmark symbol"""
    x, y = center
    # Checkmark consists of two lines
    # Short line going down-left, then long line going up-right

    # Calculate points for checkmark
    # Start point (left side of checkmark)
    start_x = x - size * 0.35
    start_y = y

    # Middle point (bottom of checkmark)
    mid_x = x - size * 0.1
    mid_y = y + size * 0.25

    # End point (top-right of checkmark)
    end_x = x + size * 0.35
    end_y = y - size * 0.25

    # Draw the two lines of the checkmark
    draw.line([(start_x, start_y), (mid_x, mid_y)], fill=color, width=width)
    draw.line([(mid_x, mid_y), (end_x, end_y)], fill=color, width=width)

def draw_person_icon(draw, center, size, color):
    """Draw a simple person silhouette (head + shoulders)"""
    x, y = center

    # Head (circle)
    head_radius = size * 0.18
    head_y = y - size * 0.15
    draw.ellipse(
        [x - head_radius, head_y - head_radius,
         x + head_radius, head_y + head_radius],
        fill=color
    )

    # Shoulders/body (semi-circle/arc shape)
    shoulder_width = size * 0.35
    shoulder_height = size * 0.25
    shoulder_y = y + size * 0.1

    # Draw as a rounded rectangle for shoulders
    draw.ellipse(
        [x - shoulder_width, shoulder_y - shoulder_height,
         x + shoulder_width, shoulder_y + shoulder_height * 1.5],
        fill=color
    )

def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def create_bulkmates_icon():
    """Create the BulkMates app icon"""
    # Canvas size
    size = (1024, 1024)
    center = (512, 512)

    # Colors
    gradient_start = hex_to_rgb('#4CAF50')  # Green
    gradient_end = hex_to_rgb('#2196F3')    # Blue
    white = (255, 255, 255)
    checkmark_green = hex_to_rgb('#4CAF50')

    # Person circle colors
    person_colors = [
        hex_to_rgb('#FF9800'),  # Orange (12 o'clock)
        hex_to_rgb('#9C27B0'),  # Purple (2 o'clock)
        hex_to_rgb('#FFE66D'),  # Yellow (4 o'clock)
        hex_to_rgb('#FF6B6B'),  # Coral/Red (6 o'clock)
        hex_to_rgb('#4ECDC4'),  # Teal (8 o'clock)
        hex_to_rgb('#95E1D3'),  # Mint green (10 o'clock)
    ]

    # Create base image with gradient
    img = create_gradient_background(size, gradient_start, gradient_end)

    # Create a drawing context with alpha for shadows
    # We'll use an overlay for shadows
    shadow_layer = Image.new('RGBA', size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer, 'RGBA')

    # Main drawing context
    draw = ImageDraw.Draw(img)

    # Draw person circles with shadows (6 people in a circle)
    person_radius = 60  # 120px diameter
    circle_radius = 300  # Distance from center

    for i, color in enumerate(person_colors):
        # Calculate position (clock positions)
        angle = (i * 60 - 90) * math.pi / 180  # Start at top (12 o'clock), every 60 degrees
        person_x = int(center[0] + circle_radius * math.cos(angle))
        person_y = int(center[1] + circle_radius * math.sin(angle))

        # Draw shadow on shadow layer
        shadow_offset = 4
        shadow_blur = 12
        for j in range(shadow_blur, 0, -1):
            alpha = int(50 * (1 - j / shadow_blur))
            shadow_draw.ellipse(
                [person_x - person_radius - j//2 + shadow_offset,
                 person_y - person_radius - j//2 + shadow_offset,
                 person_x + person_radius + j//2 + shadow_offset,
                 person_y + person_radius + j//2 + shadow_offset],
                fill=(0, 0, 0, alpha)
            )

        # Draw colored circle
        draw.ellipse(
            [person_x - person_radius, person_y - person_radius,
             person_x + person_radius, person_y + person_radius],
            fill=color
        )

        # Draw person icon inside
        draw_person_icon(draw, (person_x, person_y), person_radius * 1.2, white)

    # Composite shadow layer
    img = Image.alpha_composite(img.convert('RGBA'), shadow_layer).convert('RGB')
    draw = ImageDraw.Draw(img)

    # Create another shadow layer for center circle
    shadow_layer2 = Image.new('RGBA', size, (0, 0, 0, 0))
    shadow_draw2 = ImageDraw.Draw(shadow_layer2, 'RGBA')

    # Draw center white circle shadow
    center_radius = 90  # 180px diameter
    shadow_offset = 8
    shadow_blur = 24
    for j in range(shadow_blur, 0, -1):
        alpha = int(60 * (1 - j / shadow_blur))
        shadow_draw2.ellipse(
            [center[0] - center_radius - j//2 + shadow_offset,
             center[1] - center_radius - j//2 + shadow_offset,
             center[0] + center_radius + j//2 + shadow_offset,
             center[1] + center_radius + j//2 + shadow_offset],
            fill=(0, 0, 0, alpha)
        )

    # Composite center shadow
    img = Image.alpha_composite(img.convert('RGBA'), shadow_layer2).convert('RGB')
    draw = ImageDraw.Draw(img)

    # Draw center white circle
    draw.ellipse(
        [center[0] - center_radius, center[1] - center_radius,
         center[0] + center_radius, center[1] + center_radius],
        fill=white
    )

    # Draw checkmark in center
    draw_checkmark(draw, center, 100, checkmark_green, 16)

    return img

if __name__ == '__main__':
    print("Creating BulkMates app icon...")
    icon = create_bulkmates_icon()

    # Save the icon
    output_path = 'BulkMatesIcon-1024.png'
    icon.save(output_path, 'PNG')
    print(f"✅ Icon created successfully: {output_path}")
    print(f"   Size: {icon.size}")
    print(f"   Format: {icon.format}")
