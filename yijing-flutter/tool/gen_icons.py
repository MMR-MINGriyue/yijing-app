#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""易道 图标统一生成器 (iter45) — 「易」华文行楷 + 朱砂「道」印 + 墨底金晕.

设计: 墨底 #14100B + 顶部金色径向光晕 + 金渐变行楷「易」(华文行楷, 4x 超采样)
      + 朱砂圆角印章「道」(楷体墨字, -7° 微倾) — 易道二字拆借入印.
产物:
  iOS   ios/Runner/Assets.xcassets/AppIcon.appiconset/ (按 Contents.json 全 19 尺寸)
  Andoroid legacy mipmap-*/ic_launcher.png + ic_launcher_round.png (5 密度)
  Android adaptive drawable/ic_launcher_foreground.png (透明底, 安全区构图)
          drawable/ic_launcher_monochrome.png (纯白 alpha)
          drawable/ic_notification.png (纯白 易 字)
  PWA   icons/icon-192.png, icons/icon-512.png

依赖: Pillow + numpy (系统 Python310). 用法: python tool/gen_icons.py
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IOS_ASSETS = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
ANDROID_RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
PWA_ICONS = os.path.join(os.path.dirname(ROOT), 'icons')

INK = (0x14, 0x10, 0x0B, 255)
GOLD = (0xC9, 0xA8, 0x76)
CINNABAR = (0xD0, 0x4D, 0x3E)
HALO = (0xC9, 0xA8, 0x76)
WHITE = (255, 255, 255, 255)

F_XINGKA = r'C:\Windows\Fonts\STXINGKA.TTF'
F_KAI = r'C:\Windows\Fonts\simkai.ttf'

SS = 4  # 超采样倍率


def _halo(ss, strength, cy_frac=0.30, r_frac=0.42):
    yg, xg = np.mgrid[0:ss, 0:ss]
    dx = (xg - ss / 2) / (ss * r_frac)
    dy = (yg - ss * cy_frac) / (ss * r_frac)
    dist = np.sqrt(dx * dx + dy * dy)
    alpha = np.clip(strength * (1.0 - dist), 0, 255).astype(np.uint8)
    halo = np.zeros((ss, ss, 4), dtype=np.uint8)
    halo[..., 0], halo[..., 1], halo[..., 2] = HALO
    halo[..., 3] = alpha
    return Image.fromarray(halo, 'RGBA')


def _gold_gradient(size):
    top, bot = (0xE6, 0xC8, 0x96), (0xA5, 0x83, 0x4E)
    g = Image.new('RGBA', (size, size))
    d = ImageDraw.Draw(g)
    for y in range(size):
        t = y / max(1, size - 1)
        c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)) + (255,)
        d.line([(0, y), (size, y)], fill=c)
    return g


def _glyph_mask(ch, font_path, px):
    """4x 渲染字形 → L mask (紧裁剪)"""
    s = 4
    m = Image.new('L', (px * s, px * s), 0)
    d = ImageDraw.Draw(m)
    d.text((px * s // 2, px * s // 2), ch, font=ImageFont.truetype(font_path, px),
           fill=255, anchor='mm')
    m = m.resize((px, px), Image.LANCZOS)
    return m.crop(m.getbbox())


def _paste_glyph(img, ch, font_path, box, ucx=0.49, ucy=0.455, glow=True, color=None):
    """金渐变(或指定色)字形 + 柔光, 按画布比例位放置"""
    ss = img.size[0]
    m = _glyph_mask(ch, font_path, int(ss * 0.75))
    gw, gh = m.size
    scale = (ss * box) / max(gw, gh)
    gw, gh = max(1, int(gw * scale)), max(1, int(gh * scale))
    m = m.resize((gw, gh), Image.LANCZOS)
    if color is None:
        fill_img = _gold_gradient(gh).resize((gw, gh))
    else:
        fill_img = Image.new('RGBA', (gw, gh), color)
    layer = Image.new('RGBA', (gw, gh), (0, 0, 0, 0))
    layer.paste(fill_img, (0, 0), m)
    if glow and color is None:
        pad = max(8, ss // 64)
        gl = Image.new('RGBA', (gw + 2 * pad, gh + 2 * pad), (0, 0, 0, 0))
        gl.paste(Image.new('RGBA', (gw, gh), GOLD + (70,)), (pad, pad), m)
        gl = gl.filter(ImageFilter.GaussianBlur(max(6, ss // 85)))
        flat = Image.new('RGBA', gl.size, (0, 0, 0, 0))
        flat.alpha_composite(gl)
        flat.alpha_composite(layer, (pad, pad))
        layer = flat
    img.alpha_composite(layer, (int(ss * ucx - layer.size[0] / 2),
                                int(ss * ucy - layer.size[1] / 2)))
    return img


def _paste_seal(img, ch, frac=0.22, ucx=0.73, ucy=0.70, tilt=-7, fill=CINNABAR + (235,),
                text_color=(0x14, 0x10, 0x0B, 255)):
    """朱砂圆角印章 + 墨字 (楷体), -7° 微倾"""
    ss = img.size[0]
    side = max(8, int(ss * frac))
    s = 4
    tile = Image.new('RGBA', (side * s, side * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(tile)
    pad = int(side * s * 0.06)
    d.rounded_rectangle([pad, pad, side * s - pad, side * s - pad],
                        radius=int(side * s * 0.14), fill=fill)
    fs = int(side * s * 0.62)
    d.text((side * s // 2, side * s // 2 + side * s * 0.02), ch,
           font=ImageFont.truetype(F_KAI, fs), fill=text_color, anchor='mm')
    tile = tile.rotate(tilt, resample=Image.BICUBIC, expand=True)
    tile = tile.resize((max(1, tile.size[0] // s), max(1, tile.size[1] // s)), Image.LANCZOS)
    img.alpha_composite(tile, (int(ss * ucx - tile.size[0] / 2),
                               int(ss * ucy - tile.size[1] / 2)))
    return img


def render_full(size):
    """全出血: 墨底 + 光晕 + 金易 + 朱砂印 (iOS / mipmap / PWA)"""
    ss = size * SS
    img = Image.new('RGBA', (ss, ss), INK)
    img = Image.alpha_composite(img, _halo(ss, 55))
    k = ss / size
    small = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    _paste_glyph(small, '易', F_XINGKA, 0.64)
    _paste_seal(small, '道', 0.22)
    img.alpha_composite(small.resize((ss, ss), Image.LANCZOS))
    return img.resize((size, size), Image.LANCZOS)


def render_fg(size):
    """自适应前景: 透明底, 图形收进中心安全区 (66/108)"""
    ss = size * SS
    img = Image.new('RGBA', (ss, ss), (0, 0, 0, 0))
    k = ss / size
    small = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    _paste_glyph(small, '易', F_XINGKA, 0.42, ucx=0.46, ucy=0.44, glow=False)
    _paste_seal(small, '道', 0.145, ucx=0.675, ucy=0.645, tilt=-7)
    img.alpha_composite(small.resize((ss, ss), Image.LANCZOS))
    return img.resize((size, size), Image.LANCZOS)


def render_mono(size):
    """单色层: 纯白 易 (alpha 即形状)"""
    ss = size * SS
    img = Image.new('RGBA', (ss, ss), (0, 0, 0, 0))
    small = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    _paste_glyph(small, '易', F_XINGKA, 0.46, ucx=0.5, ucy=0.5, glow=False, color=WHITE)
    img.alpha_composite(small.resize((ss, ss), Image.LANCZOS))
    return img.resize((size, size), Image.LANCZOS)


def render_notif(size):
    """通知白色小图标: 纯白 易"""
    ss = size * SS
    img = Image.new('RGBA', (ss, ss), (0, 0, 0, 0))
    small = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    _paste_glyph(small, '易', F_XINGKA, 0.62, ucx=0.5, ucy=0.5, glow=False, color=WHITE)
    img.alpha_composite(small.resize((ss, ss), Image.LANCZOS))
    return img.resize((size, size), Image.LANCZOS)


def circle_crop(img):
    ss = img.size[0]
    mask = Image.new('L', (ss * 2, ss * 2), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, ss * 2 - 1, ss * 2 - 1], fill=255)
    mask = mask.resize((ss, ss), Image.LANCZOS)
    out = Image.new('RGBA', (ss, ss), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def main():
    # 1) iOS 全 19 尺寸
    with open(os.path.join(IOS_ASSETS, 'Contents.json'), encoding='utf-8') as f:
        contents = json.load(f)
    cache = {}
    for image in contents['images']:
        px = int(float(image['size'].split('x')[0])) * int(image['scale'].rstrip('x'))
        if px not in cache:
            print(f'full {px}px')
            cache[px] = render_full(px)
        cache[px].save(os.path.join(IOS_ASSETS, image['filename']), 'PNG')
    print('  iOS done')

    # 2) Android legacy mipmap (方形全出血 + 圆形裁切)
    for dpi, px in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
        d = os.path.join(ANDROID_RES, f'mipmap-{dpi}')
        os.makedirs(d, exist_ok=True)
        full = render_full(px)
        full.convert('RGB').save(os.path.join(d, 'ic_launcher.png'), 'PNG')
        circle_crop(full).save(os.path.join(d, 'ic_launcher_round.png'), 'PNG')
    print('  Android mipmap done')

    # 3) Android adaptive drawable (PNG 替代旧 vector XML)
    d = os.path.join(ANDROID_RES, 'drawable')
    os.makedirs(d, exist_ok=True)
    render_fg(432).save(os.path.join(d, 'ic_launcher_foreground.png'), 'PNG')
    render_mono(432).save(os.path.join(d, 'ic_launcher_monochrome.png'), 'PNG')
    render_notif(192).save(os.path.join(d, 'ic_notification.png'), 'PNG')
    for old in ('ic_launcher_foreground.xml', 'ic_launcher_monochrome.xml', 'ic_notification.xml'):
        p = os.path.join(d, old)
        if os.path.exists(p):
            os.remove(p)
    print('  Android drawable done')

    # 4) PWA
    if os.path.isdir(PWA_ICONS):
        render_full(192).convert('RGB').save(os.path.join(PWA_ICONS, 'icon-192.png'), 'PNG')
        render_full(512).convert('RGB').save(os.path.join(PWA_ICONS, 'icon-512.png'), 'PNG')
        print('  PWA done')


if __name__ == '__main__':
    main()
