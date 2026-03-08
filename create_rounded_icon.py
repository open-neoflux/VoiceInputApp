#!/usr/bin/env python3
from PIL import Image
import sys

def add_rounded_corners(input_path, output_path, corner_radius_ratio=0.22):
    img = Image.open(input_path).convert("RGBA")
    width, height = img.size
    
    # macOS 圆角半径约为图标尺寸的 22%
    corner_radius = int(min(width, height) * corner_radius_ratio)
    
    # 创建圆角蒙版
    mask = Image.new('L', (width, height), 0)
    
    from PIL import ImageDraw
    draw = ImageDraw.Draw(mask)
    
    # 绘制圆角矩形
    draw.rounded_rectangle([(0, 0), (width, height)], radius=corner_radius, fill=255)
    
    # 应用蒙版
    img.putalpha(mask)
    
    img.save(output_path, "PNG")
    print(f"Created rounded icon: {output_path}")

if __name__ == "__main__":
    add_rounded_corners("logo.png", "logo_rounded.png")
