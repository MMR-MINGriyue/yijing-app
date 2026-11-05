/// 道家纹饰工具 (iter58) — 标准阴阳鱼 / 星宿云篆背景 / 朱砂印章
/// 全应用共用, 纯绘制无资源文件.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import 'yijing_theme.dart';

/// 标准太极阴阳鱼 — 半圆 + 上下两个小圆叠画.
/// 修复 iter57 的 arcTo 路径畸形: arcTo 起点与当前点不连续会插入直线段,
/// 令阴阳鱼变形; 此叠画法只用 drawArc/drawCircle, 几何恒定.
void paintTaiji(
  Canvas canvas,
  Offset c,
  double r, {
  Color yang = YiColors.gold,
  Color yin = const Color(0xFF20190F),
}) {
  final gold = Paint()..color = yang;
  final ink = Paint()..color = yin;
  // 阳底 → 右半阴扇形 → 上阴鱼头 → 下阳鱼头 → 两眼 → 外郭
  canvas.drawCircle(c, r, gold);
  canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2, pi, true, ink);
  canvas.drawCircle(Offset(c.dx, c.dy - r / 2), r / 2, ink);
  canvas.drawCircle(Offset(c.dx, c.dy + r / 2), r / 2, gold);
  canvas.drawCircle(Offset(c.dx, c.dy - r / 2), r * 0.14, gold);
  canvas.drawCircle(Offset(c.dx, c.dy + r / 2), r * 0.14, ink);
  canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = YiColors.goldDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
}

/// 星宿云篆底纹 (iter58) — 极淡, 铺于墨韵之上, 不干扰内容可读性.
/// 40 颗星宿点 + 4 道云篆弧 + 四角卦符, 全部 alpha ≤ 0.12.
class YiMysticPainter extends CustomPainter {
  const YiMysticPainter({this.seed = 7});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    // 星宿散点
    for (var i = 0; i < 40; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final rr = 0.5 + rnd.nextDouble() * 1.1;
      canvas.drawCircle(
          Offset(x, y),
          rr,
          Paint()
            ..color = (i % 5 == 0 ? YiColors.talisman : YiColors.starSilver)
                .withValues(alpha: 0.06 + rnd.nextDouble() * 0.07));
    }
    // 云篆弧: 左上与右下各两道同心淡弧
    final cloudPaint = Paint()
      ..color = YiColors.gold.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final anchor in <Offset>[
      const Offset(-40, -30),
      Offset(size.width + 40, size.height + 30),
    ]) {
      for (var k = 1; k <= 3; k++) {
        canvas.drawArc(
            Rect.fromCircle(center: anchor, radius: size.width * 0.22 * k),
            0,
            pi * 1.2,
            false,
            cloudPaint);
      }
    }
    // 四角卦符 (乾坤离坎, 三爻短线)
    final corners = <Offset>[
      const Offset(24, 26),
      Offset(size.width - 24, 26),
      const Offset(24, 1),
      Offset(size.width - 24, 1),
    ];
    const trigrams = <List<int>>[
      [1, 1, 1], // 乾
      [0, 0, 0], // 坤
      [1, 0, 1], // 离
      [0, 1, 0], // 坎
    ];
    for (var i = 0; i < 4; i++) {
      final p = corners[i];
      final y0 = i < 2 ? size.height * 0.16 : size.height * 0.84;
      final tri = trigrams[i];
      for (var line = 0; line < 3; line++) {
        final ly = y0 + line * 5.0;
        final paint = Paint()
          ..color = YiColors.gold.withValues(alpha: 0.07)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
        if (tri[line] == 1) {
          canvas.drawLine(Offset(p.dx - 8, ly), Offset(p.dx + 8, ly), paint);
        } else {
          canvas.drawLine(Offset(p.dx - 8, ly), Offset(p.dx - 2, ly), paint);
          canvas.drawLine(Offset(p.dx + 2, ly), Offset(p.dx + 8, ly), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant YiMysticPainter old) => old.seed != seed;
}

/// 朱砂印章 — 单字方印, 道家符箓味
class YiSeal extends StatelessWidget {
  const YiSeal({super.key, required this.text, this.size = 26});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: YiColors.cinnabar.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
              color: const Color(0xFF8E2E24).withValues(alpha: 0.9), width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: size * 0.58,
            height: 1.0,
            color: const Color(0xFFFFF3E4),
            fontFamily: 'KaiTi',
            fontFamilyFallback: const ['STKaiti', 'serif'],
          ),
        ),
      );
}
