# -*- coding: utf-8 -*-
# 生成易道 App 图标 (iter40): 墨底 + 暗金坎卦 + 朱砂九二动爻
# 产物: 自适应图标 XML + 遗留密度 PNG + 通知白色小图标
import os

RES = r'D:\workspace\yijing-app\yijing-flutter\android\app\src\main\res'

INK = (20, 16, 11)        # 14100B
GOLD = (201, 168, 118)    # C9A876
CINNABAR = (208, 77, 62)  # D04D3E

# ---- 卦象几何 (108dp 自适应视口; 上爻在上) ----
# 坎卦: 上→下 = 阴,阳,阴,阴,阳(动/朱砂),阴  (九二动 motif)
LINES = [  # (yang, moving)
    (False, False),  # 上六
    (True,  False),  # 九五
    (False, False),  # 六四
    (False, False),  # 六三
    (True,  True),   # 九二 ← 朱砂动爻
    (False, False),  # 初六
]
W, LH, GAP = 40.0, 4.5, 4.5
Y0 = 54.0 - (6 * (LH + GAP) - GAP) / 2
SEG_GAP = 7.0


def rrect_path(x, y, w, h, r):
    """圆角矩形 SVG path"""
    return (f"M{x+r:.2f},{y:.2f} L{x+w-r:.2f},{y:.2f} A{r:.2f},{r:.2f} 0 0 1 {x+w:.2f},{y+r:.2f} "
            f"L{x+w:.2f},{y+h-r:.2f} A{r:.2f},{r:.2f} 0 0 1 {x+w-r:.2f},{y+h:.2f} "
            f"L{x+r:.2f},{y+h:.2f} A{r:.2f},{r:.2f} 0 0 1 {x:.2f},{y+h-r:.2f} "
            f"L{x:.2f},{y+r:.2f} A{r:.2f},{r:.2f} 0 0 1 {x+r:.2f},{y:.2f} Z")


def glyph_paths(color_gold, color_red):
    """返回 [(pathData, fillColor)], 108dp 视口, 上爻先画"""
    out = []
    for k, (yang, moving) in enumerate(LINES):
        y = Y0 + k * (LH + GAP)
        fill = '#FF' + ''.join(f'{c:02X}' for c in (CINNABAR if moving else GOLD))
        _ = color_gold, color_red
        if yang:
            out.append((rrect_path(54 - W / 2, y, W, LH, LH / 2), fill))
        else:
            seg = (W - SEG_GAP) / 2
            out.append((rrect_path(54 - W / 2, y, seg, LH, LH / 2), fill))
            out.append((rrect_path(54 + SEG_GAP / 2, y, seg, LH, LH / 2), fill))
    return out


def vector_xml(viewport, paths):
    body = '\n'.join(
        f'    <path android:pathData="{d}" android:fillColor="{c}"/>' for d, c in paths)
    return (f'<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
            f'    android:width="{viewport}dp" android:height="{viewport}dp"\n'
            f'    android:viewportWidth="{viewport}" android:viewportHeight="{viewport}">\n'
            f'{body}\n</vector>\n')


def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)
    print('write', path)


# 1) 前景 (含顶部氛围光晕: 金 14% → 0% 径向渐变)
glow = ('    <path android:pathData="M54,54m-46,0a46,46 0 1,1 92,0a46,46 0 1,1 -92,0">\n'
        '      <aapt:attr xmlns:aapt="http://schemas.android.com/aapt" name="android:fillColor">\n'
        '        <gradient android:type="radial" android:centerX="54" android:centerY="40"\n'
        '            android:gradientRadius="46"\n'
        '            android:startColor="#24C9A876" android:endColor="#00C9A876"/>\n'
        '      </aapt:attr>\n'
        '    </path>\n')
fg_paths = '\n'.join(f'    <path android:pathData="{d}" android:fillColor="{c}"/>'
                     for d, c in glyph_paths(None, None))
write(f'{RES}/drawable/ic_launcher_foreground.xml',
      '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
      '    xmlns:aapt="http://schemas.android.com/aapt"\n'
      '    android:width="108dp" android:height="108dp"\n'
      '    android:viewportWidth="108" android:viewportHeight="108">\n'
      f'{glow}{fg_paths}\n</vector>\n')

# 2) 单色层 (Android 13 主题图标: 白)
mono = [(d, '#FFFFFFFF') for d, _ in glyph_paths(None, None)]
write(f'{RES}/drawable/ic_launcher_monochrome.xml', vector_xml(108, mono))

# 3) 通知小图标 (白色 24dp)
notif = []
nw, nlh, ngap = 14.0, 1.7, 1.7
ny0 = 12.0 - (6 * (nlh + ngap) - ngap) / 2
nseg = (nw - 4.2) / 2
for k, (yang, moving) in enumerate(LINES):
    y = ny0 + k * (nlh + ngap)
    if yang:
        notif.append((rrect_path(12 - nw / 2, y, nw, nlh, nlh / 2), '#FFFFFFFF'))
    else:
        notif.append((rrect_path(12 - nw / 2, y, nseg, nlh, nlh / 2), '#FFFFFFFF'))
        notif.append((rrect_path(12 + 2.1, y, nseg, nlh, nlh / 2), '#FFFFFFFF'))
write(f'{RES}/drawable/ic_notification.xml', vector_xml(24, notif))

# 4) 自适应图标装配 + 背景色
adaptive = ('<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background"/>\n'
            '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
            '    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>\n'
            '</adaptive-icon>\n')
write(f'{RES}/mipmap-anydpi-v26/ic_launcher.xml', adaptive)
write(f'{RES}/mipmap-anydpi-v26/ic_launcher_round.xml', adaptive)
write(f'{RES}/values/ic_launcher_background.xml',
      '<?xml version="1.0" encoding="utf-8"?>\n'
      '<resources>\n    <color name="ic_launcher_background">#14100B</color>\n</resources>\n')

# 5) 遗留密度 PNG (PIL 超采样)
from PIL import Image, ImageDraw

def render(size, round_mask):
    ss = 4  # 超采样
    S = size * ss
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # 墨底 (圆角 20%; round 版全圆)
    radius = int(S * (0.5 if round_mask else 0.20))
    d.rounded_rectangle([0, 0, S - 1, S - 1], radius=radius, fill=INK + (255,))
    # 氛围光 (同心圆近似径向渐变)
    cx, cy, maxr = int(S * 0.5), int(S * 0.37), int(S * 0.43)
    steps = 60
    for i in range(steps, 0, -1):
        r = int(maxr * i / steps)
        a = int(0.14 * 255 * (1 - i / steps))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GOLD + (a,))
    # 卦象
    def rr(x, y, w, h, r, fill):
        d.rounded_rectangle([x, y, x + w, y + h], radius=r, fill=fill)
    total_h = 6 * (LH + GAP) - GAP
    scale = S / 108.0
    for k, (yang, moving) in enumerate(LINES):
        y = (Y0 + k * (LH + GAP)) * scale
        h = LH * scale
        fill = CINNABAR + (255,) if moving else GOLD + (255,)
        if yang:
            rr((54 - W / 2) * scale, y, W * scale, h, h / 2, fill)
        else:
            seg = (W - SEG_GAP) / 2 * scale
            rr((54 - W / 2) * scale, y, seg, h, h / 2, fill)
            rr((54 + SEG_GAP / 2) * scale, y, seg, h, h / 2, fill)
    # 圆形遮罩
    if round_mask:
        mask = Image.new('L', (S, S), 0)
        ImageDraw.Draw(mask).ellipse([0, 0, S - 1, S - 1], fill=255)
        out = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        out.paste(img, (0, 0), mask)
        img = out
    return img.resize((size, size), Image.LANCZOS)


for dpi, px in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    folder = f'{RES}/mipmap-{dpi}'
    os.makedirs(folder, exist_ok=True)
    render(px, False).save(f'{folder}/ic_launcher.png')
    render(px, True).save(f'{folder}/ic_launcher_round.png')
    print('png', dpi, px)

print('ALL DONE')
