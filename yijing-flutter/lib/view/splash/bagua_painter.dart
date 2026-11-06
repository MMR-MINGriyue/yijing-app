import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/bagua.dart';
import '../../theme/yijing_theme.dart';
import '../../theme/yi_ornament.dart';

/// 八卦转盘绘制 (iter57) — 纯 CustomPainter, 无图片/无 blur.
/// 外环 8 卦符 (上卦)、内环 8 自然名 (下卦) 可各自旋转; 中心太极;
/// 顶部朱砂指针固定. 停位高亮随 reveal 渐显.
class BaguaPainter extends CustomPainter {
  const BaguaPainter({
    required this.outerTurns,
    required this.innerTurns,
    required this.upIndex,
    required this.downIndex,
    required this.reveal,
  });

  final double outerTurns; // 外环旋转弧度 (顺时针为正)
  final double innerTurns; // 内环旋转弧度
  final int upIndex; // 上卦停位序号
  final int downIndex; // 下卦停位序号
  final double reveal; // 0-1 停位显化进度

  static const Color _gold = YiColors.gold;
  static const Color _goldDark = YiColors.goldDark;
  static const Color _muted = YiColors.textTertiary;
  static const Color _cinnabar = YiColors.cinnabar;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final R = min(size.width, size.height) / 2;
    final ringOuter = R * 0.94;
    final ringTrig = R * 0.75;
    final ringInner = R * 0.52;
    final ringName = R * 0.36;
    final rTai = R * 0.20;

    final ringPaint = Paint()
      ..color = _goldDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final faintPaint = Paint()
      ..color = YiColors.stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 三道环
    canvas.drawCircle(c, ringOuter, ringPaint);
    canvas.drawCircle(c, ringInner, ringPaint);
    canvas.drawCircle(c, rTai + R * 0.03, faintPaint);

    // 8 条径向分隔 (淡)
    for (var i = 0; i < 8; i++) {
      final a = -pi / 2 + (i + 0.5) * pi / 4;
      canvas.drawLine(
          c + Offset(cos(a) * ringInner, sin(a) * ringInner),
          c + Offset(cos(a) * ringOuter, sin(a) * ringOuter),
          faintPaint);
    }

    // 外环卦符 (保持水平, 不随半径旋转)
    final lineW = R * 0.135;
    final lineH = R * 0.017;
    final lineGap = R * 0.012;
    final yangPaint = Paint()..color = _gold;
    final hiPaint = Paint()..color = _cinnabar;
    for (var i = 0; i < 8; i++) {
      final a = -pi / 2 + i * pi / 4 + outerTurns;
      final p = c + Offset(cos(a) * ringTrig, sin(a) * ringTrig);
      final bits = kBaguaXiantian[i].bits;
      final isUp = i == upIndex && reveal > 0;
      final paint = isUp ? hiPaint : yangPaint;
      for (var line = 0; line < 3; line++) {
        final y = p.dy + (1 - line) * (lineH + lineGap);
        if (bits[line] == '1') {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(
                      center: Offset(p.dx, y),
                      width: lineW,
                      height: lineH),
                  Radius.circular(lineH / 2)),
              paint);
        } else {
          final seg = (lineW - lineH * 2.2) / 2;
          for (final dx in [-1.0, 1.0]) {
            canvas.drawRRect(
                RRect.fromRectAndRadius(
                    Rect.fromCenter(
                        center: Offset(p.dx + dx * (seg + lineH * 2.2) / 2, y),
                        width: seg,
                        height: lineH),
                    Radius.circular(lineH / 2)),
                paint);
          }
        }
      }
      // 停位金圈 + 定盘涟漪 (iter59: 随 reveal 扩散淡出)
      if (isUp) {
        canvas.drawCircle(
            p,
            lineW * 0.72,
            Paint()
              ..color = _gold.withValues(alpha: reveal * 0.9)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
        canvas.drawCircle(
            p,
            lineW * 0.72 + reveal * R * 0.18,
            Paint()
              ..color = _gold.withValues(alpha: (1 - reveal) * 0.55)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2);
      }
    }

    // 内环自然名 (TextPainter 水平绘制)
    for (var i = 0; i < 8; i++) {
      final a = -pi / 2 + i * pi / 4 + innerTurns;
      final p = c + Offset(cos(a) * ringName, sin(a) * ringName);
      final isDown = i == downIndex && reveal > 0;
      final tp = TextPainter(
        text: TextSpan(
            text: kBaguaXiantian[i].nature,
            style: TextStyle(
                fontSize: R * 0.115,
                color: isDown ? _gold : _muted,
                fontWeight: isDown ? FontWeight.w500 : FontWeight.w400)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
      if (isDown) {
        canvas.drawCircle(
            p,
            R * 0.085,
            Paint()
              ..color = _gold.withValues(alpha: reveal * 0.75)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2);
        canvas.drawCircle(
            p,
            R * (0.085 + reveal * 0.12),
            Paint()
              ..color = _gold.withValues(alpha: (1 - reveal) * 0.4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0);
      }
    }

    // 中心太极 (iter58: 标准叠画阴阳鱼, 修复 arcTo 路径畸形; 不再盖中心墨点)
    paintTaiji(canvas, c, rTai, yang: _gold, yin: const Color(0xFF221C14));

    // 顶部固定朱砂指针
    final tipY = c.dy - ringOuter - R * 0.10;
    canvas.drawPath(
        Path()
          ..moveTo(c.dx, tipY + R * 0.075)
          ..lineTo(c.dx - R * 0.038, tipY)
          ..lineTo(c.dx + R * 0.038, tipY)
          ..close(),
        Paint()..color = _cinnabar);
    canvas.drawLine(
        Offset(c.dx, tipY),
        Offset(c.dx, c.dy - ringOuter),
        Paint()
          ..color = _cinnabar.withValues(alpha: 0.5)
          ..strokeWidth = 1);
    // 定盘脉冲: 指针处朱砂光环扩散 (iter59)
    if (reveal > 0) {
      canvas.drawCircle(
          Offset(c.dx, tipY + R * 0.04),
          R * (0.04 + reveal * 0.10),
          Paint()
            ..color = _cinnabar.withValues(alpha: (1 - reveal) * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant BaguaPainter old) =>
      old.outerTurns != outerTurns ||
      old.innerTurns != innerTurns ||
      old.reveal != reveal ||
      old.upIndex != upIndex ||
      old.downIndex != downIndex;
}
