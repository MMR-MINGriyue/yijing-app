#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 iOS AppIcon (iter41) — 与 Android 自适应图标视觉同源.

数据源: android/app/src/main/res/drawable/ic_launcher_foreground.xml (108 视口)
渲染: 墨底 #14100B + 暗金坎卦 + 朱砂九二动爻 + 顶部金色径向微光, 4x 超采样抗锯齿.

用法: python tool/gen_ios_icons.py
输出: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png
"""
import json
import os
import sys

try:
    from PIL import Image, ImageDraw
    import numpy as np
except ImportError:
    sys.exit("需要 Pillow + numpy: pip install pillow numpy")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSET_DIR = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets",
                         "AppIcon.appiconset")

INK = (0x14, 0x10, 0x0B, 255)          # 墨底 #14100B
GOLD = (0xC9, 0xA8, 0x76, 255)         # 暗金 #C9A876
CINNABAR = (0xD0, 0x4D, 0x3E, 255)     # 朱砂 #D04D3E
HALO = (0xC9, 0xA8, 0x76)              # 顶部光晕色

# Android 自适应图标几何 (ic_launcher_foreground.xml, 108 视口)
# 坎卦六爻, 上爻在上; 每爻为圆头横条 (高 4.5, 圆角 2.25)
# rows: (y, [x1..x2, ...], color); 阴爻 = 两短段, 阳爻 = 一整段
ROWS = [
    (29.25, [(34.0, 50.5)], GOLD),      # 上六 (断)
    (38.25, [(34.0, 74.0)], GOLD),      # 九五
    (47.25, [(34.0, 50.5)], GOLD),      # 六四 (断)
    (56.25, [(34.0, 50.5)], GOLD),      # 六三 (断)
    (65.25, [(34.0, 74.0)], CINNABAR),  # 九二 动爻 (朱砂)
    (74.25, [(34.0, 50.5)], GOLD),      # 初六 (断)
]
BAR_H = 4.5
RAD = 2.25
GLYPH_CX = 54.0   # 图形中心 = 视口中心 (34..74 / 29.25..78.75)
GLYPH_CY = 54.0
HALO_CX, HALO_CY, HALO_R = 54.0, 40.0, 46.0

# 图标上图形占画布比例 (iOS 全幅可见, 需比 Android 安全区略大)
GLYPH_FRACTION = 0.56
SS = 4  # 超采样倍率


def rounded_bar(img, cx, cy, x1, x2, y, color, k):
    """以视口中心为原点绘制圆头横条 (已整体平移)."""
    draw = ImageDraw.Draw(img)
    px1 = cx + (x1 - GLYPH_CX) * k
    px2 = cx + (x2 - GLYPH_CX) * k
    py1 = cy + (y - GLYPH_CY) * k
    py2 = cy + (y + BAR_H - GLYPH_CY) * k
    r = RAD * k
    draw.rounded_rectangle([px1, py1, px2, py2], radius=r, fill=color)


def render(size):
    ss = size * SS
    img = Image.new("RGBA", (ss, ss), INK)
    # 顶部径向光晕: center (HALO_CX,HALO_CY), 半径 HALO_R, 金 alpha 36 → 0
    yg, xg = np.mgrid[0:ss, 0:ss]
    kk = ss / 108.0  # 视口→画布 (用 108 视口对齐光晕几何)
    dx = (xg - (HALO_CX * kk)) / (HALO_R * kk)
    dy = (yg - (HALO_CY * kk)) / (HALO_R * kk)
    dist = np.sqrt(dx * dx + dy * dy)
    alpha = np.clip(36.0 * (1.0 - dist), 0, 36).astype(np.uint8)  # 0x24=36
    halo = np.zeros((ss, ss, 4), dtype=np.uint8)
    halo[..., 0] = HALO[0]
    halo[..., 1] = HALO[1]
    halo[..., 2] = HALO[2]
    halo[..., 3] = alpha
    overlay = Image.fromarray(halo, "RGBA")
    img = Image.alpha_composite(img, overlay)

    # 坎卦六爻 — 在 ss 画布上以画布中心为原点绘制
    # 阳爻全长 40 单位 → GLYPH_FRACTION*size 像素
    k = (size * GLYPH_FRACTION) / 40.0  # 单位像素/视口单位
    cx = ss / 2.0  # 超采样画布中心, 几何中心对齐
    cy = ss / 2.0
    for y, segs, color in ROWS:
        for x1, x2 in segs:
            rounded_bar(img, cx, cy, x1, x2, y, color, k)
    return img.resize((size, size), Image.LANCZOS)


def main():
    contents_path = os.path.join(ASSET_DIR, "Contents.json")
    with open(contents_path, "r", encoding="utf-8") as f:
        contents = json.load(f)

    cache = {}
    for image in contents["images"]:
        name = image["filename"]
        size = int(float(image["size"].split("x")[0]))
        scale = int(image["scale"].rstrip("x"))
        px = size * scale
        if px not in cache:
            print(f"render {px}x{px}")
            cache[px] = render(px)
        path = os.path.join(ASSET_DIR, name)
        cache[px].save(path, "PNG")
        print(f"  -> {name} ({px}x{px})")


if __name__ == "__main__":
    main()
