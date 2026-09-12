# -*- coding: utf-8 -*-
"""易 图标重设计 (iter45) — 华文行楷「易」+ 朱砂「道」印 + 墨底金晕
用法:
  python _icon_preview.py          # 三方案对比图
  python _icon_preview.py final    # 定稿 1024 预览
"""
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

INK = (0x14, 0x10, 0x0B, 255)
GOLD = (0xC9, 0xA8, 0x76)
CINNABAR = (0xD0, 0x4D, 0x3E)
HALO = (0xC9, 0xA8, 0x76)

F_XINGKA = r'C:\Windows\Fonts\STXINGKA.TTF'
F_LISHU = r'C:\Windows\Fonts\SIMLI.TTF'
F_KAI = r'C:\Windows\Fonts\simkai.ttf'


def base(size, halo_strength=40):
    ss = size * 2
    img = Image.new('RGBA', (ss, ss), INK)
    yg, xg = np.mgrid[0:ss, 0:ss]
    cx = cy = ss / 2.0
    dx = (xg - cx) / (ss * 0.42)
    dy = (yg - ss * 0.30) / (ss * 0.42)
    dist = np.sqrt(dx * dx + dy * dy)
    alpha = np.clip(halo_strength * (1.0 - dist), 0, 255).astype(np.uint8)
    halo = np.zeros((ss, ss, 4), dtype=np.uint8)
    halo[..., 0], halo[..., 1], halo[..., 2] = HALO
    halo[..., 3] = alpha
    img = Image.alpha_composite(img, Image.fromarray(halo, 'RGBA'))
    return img


def gold_gradient(size):
    top = (0xE6, 0xC8, 0x96)
    bot = (0xA5, 0x83, 0x4E)
    g = Image.new('RGBA', (size, size))
    d = ImageDraw.Draw(g)
    for y in range(size):
        t = y / max(1, size - 1)
        c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)) + (255,)
        d.line([(0, y), (size, y)], fill=c)
    return g


def glyph_layer(img, ch, font_path, size_px, box, tilt=0.0, glow=True):
    font = ImageFont.truetype(font_path, size_px)
    s = 4
    m = Image.new('L', (size_px * s, size_px * s), 0)
    d = ImageDraw.Draw(m)
    d.text((size_px * s // 2, size_px * s // 2), ch, font=font, fill=255, anchor='mm')
    if tilt:
        m = m.rotate(tilt, resample=Image.BICUBIC, expand=False)
    m = m.resize((size_px, size_px), Image.LANCZOS)
    bbox = m.getbbox()
    m = m.crop(bbox)
    gw, gh = m.size
    scale = box / max(gw, gh)
    gw, gh = int(gw * scale), int(gh * scale)
    m = m.resize((gw, gh), Image.LANCZOS)
    grad = gold_gradient(gh).resize((gw, gh))
    layer = Image.new('RGBA', (gw, gh), (0, 0, 0, 0))
    layer.paste(grad, (0, 0), m)
    ss = img.size[0]
    if glow:
        pad = 16
        gl = Image.new('RGBA', (gw + 2 * pad, gh + 2 * pad), (0, 0, 0, 0))
        gl.paste(Image.new('RGBA', (gw, gh), GOLD + (70,)), (pad, pad), m)
        gl = gl.filter(ImageFilter.GaussianBlur(12))
        flat = Image.new('RGBA', gl.size, (0, 0, 0, 0))
        flat.alpha_composite(gl)
        flat.alpha_composite(layer, (pad, pad))
        layer = flat
    gx = int(ss * 0.49 - layer.size[0] / 2)
    gy = int(ss * 0.455 - layer.size[1] / 2)
    img.alpha_composite(layer, (gx, gy))
    return img


def seal(img, ch, font_path, frac=0.22, cx=0.73, cy=0.70, tilt=-7):
    ss = img.size[0]
    side = int(ss * frac)
    s = 4
    tile = Image.new('RGBA', (side * s, side * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(tile)
    pad = int(side * s * 0.06)
    d.rounded_rectangle([pad, pad, side * s - pad, side * s - pad],
                        radius=int(side * s * 0.14), fill=CINNABAR + (235,))
    fs = int(side * s * 0.62)
    font = ImageFont.truetype(font_path, fs)
    d.text((side * s // 2, side * s // 2 + side * s * 0.02), ch,
           font=font, fill=(0x14, 0x10, 0x0B, 255), anchor='mm')
    tile = tile.rotate(tilt, resample=Image.BICUBIC, expand=True)
    tile = tile.resize((tile.size[0] // s, tile.size[1] // s), Image.LANCZOS)
    px = int(ss * cx - tile.size[0] / 2)
    py = int(ss * cy - tile.size[1] / 2)
    img.alpha_composite(tile, (px, py))
    return img


def final_img(size):
    img = base(size, halo_strength=55)
    glyph_layer(img, '易', F_XINGKA, int(size * 0.66), int(size * 0.64))
    seal(img, '道', F_KAI, frac=0.21, cx=0.735, cy=0.735, tilt=-7)
    return img


def main():
    s = 512
    v1 = base(s)
    glyph_layer(v1, '易', F_XINGKA, int(s * 0.62), int(s * 0.60))
    v2 = base(s)
    glyph_layer(v2, '易', F_XINGKA, int(s * 0.60), int(s * 0.56))
    seal(v2, '道', F_KAI, frac=0.22, cx=0.755, cy=0.745, tilt=-7)
    v3 = base(s)
    glyph_layer(v3, '易', F_LISHU, int(s * 0.60), int(s * 0.56))
    seal(v3, '道', F_KAI, frac=0.22, cx=0.755, cy=0.745, tilt=-7)
    cells = [(v1, 'V1 xingka'), (v2, 'V2 xingka+seal'), (v3, 'V3 lishu+seal')]
    n = 512
    gap = 24
    cols = 2
    rows = (len(cells) + 1) // 2
    W = cols * n + (cols + 1) * gap
    H = rows * n + (rows + 1) * gap
    board = Image.new('RGB', (W, H), (40, 36, 30))
    for i, (img, label) in enumerate(cells):
        x = gap + (i % cols) * (n + gap)
        y = gap + (i // cols) * (n + gap)
        board.paste(img.convert('RGB'), (x, y))
        ImageDraw.Draw(board).text((x + 8, y + n - 30), label, fill=(230, 225, 215))
    board.save(r'D:\workspace\yijing-app\.pwtest\icon_variants.png')
    print('variants saved')


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'final':
        final_img(1024).convert('RGB').save(r'D:\workspace\yijing-app\.pwtest\icon_final.png')
        print('final saved')
    else:
        main()
