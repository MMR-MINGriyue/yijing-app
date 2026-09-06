import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/cast_engine.dart';
import '../../core/yi_calendar.dart';
import '../../model/hex.dart';

/// 卦象分享卡 — 移植自易道 PWA js/07-extra.js YijingShare.draw (720×1040)
/// 纯 Canvas 绘制: PictureRecorder → Picture → toImage → PNG bytes
class ShareCardData {
  final Hex hex;
  final List<int> moving; // 动爻索引
  final String question; // 所问之事 (可空)
  final DateTime now;

  const ShareCardData({
    required this.hex,
    this.moving = const [],
    this.question = '',
    required this.now,
  });
}

const double _kCardW = 720;
const double _kCardH = 1040;

const Color _gold = Color(0xFFC9A876);
const Color _text = Color(0xFFEFE2C8);
const Color _muted = Color(0xFFB0A088);
const Color _cinnabar = Color(0xFFD04D3E);

const String _serif = 'serif';
const String _sans = 'sans-serif';

/// 渲染分享卡 PNG (默认 2x = 1440×2080)
Future<ui.Image> renderShareCardImage(ShareCardData data, {double pixelRatio = 2}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
      recorder, Offset.zero & Size(_kCardW * pixelRatio, _kCardH * pixelRatio));
  canvas.scale(pixelRatio);
  ShareCardPainter(data).paint(canvas, const Size(_kCardW, _kCardH));
  final picture = recorder.endRecording();
  final img = await picture.toImage((_kCardW * pixelRatio).round(), (_kCardH * pixelRatio).round());
  return img;
}

/// 预览组件 (单测 / 调试可直接 pump)
class ShareCardPreview extends StatelessWidget {
  final ShareCardData data;

  const ShareCardPreview({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(_kCardW, _kCardH),
      painter: ShareCardPainter(data),
    );
  }
}

class ShareCardPainter extends CustomPainter {
  final ShareCardData data;

  ShareCardPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final hex = data.hex;
    final mv = data.moving;
    final w = size.width;

    // 背景: 竖向渐变 #241809 → #100B06 + 中心金色氛围光
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF241809), Color(0xFF100B06)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w / 2, 300), 420,
        [const Color(0x1AC9A876), const Color(0x00C9A876)],
      );
    canvas.drawRect(Offset.zero & size, glowPaint);
    // 金色边框 (内缩 24)
    canvas.drawRect(
      const Rect.fromLTWH(24, 24, _kCardW - 48, _kCardH - 48),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x59C9A876),
    );

    // 序号: 第 N 卦 (中文数字)
    _centerText(canvas, w, '第 ${cnNumber(hex.no)} 卦', 84,
        const TextStyle(fontSize: 22, color: _gold, fontFamily: _sans, letterSpacing: 6));

    // 卦象 (上爻在上): 线宽 220 / 线高 18 / 间距 22, 顶起 150
    const lw = 220.0, lh = 18.0, gap = 22.0;
    var glyphBottom = 150.0;
    for (var k = 0; k < 6; k++) {
      final idx = 5 - k;
      final isMoving = mv.contains(idx);
      final yang = hex.isYang(idx);
      final y = 150.0 + k * (lh + gap);
      final lineColor = isMoving ? _cinnabar : _gold;
      final linePaint = Paint()..color = lineColor;
      if (yang) {
        canvas.drawRect(Rect.fromLTWH((w - lw) / 2, y, lw, lh), linePaint);
      } else {
        final half = (lw - 44) / 2;
        canvas.drawRect(Rect.fromLTWH((w - lw) / 2, y, half, lh), linePaint);
        canvas.drawRect(Rect.fromLTWH((w - lw) / 2 + half + 44, y, half, lh), linePaint);
      }
      if (isMoving) {
        _centerText(canvas, (w + lw) / 2 + 26, '动', y - 4,
            const TextStyle(fontSize: 18, color: _cinnabar, fontFamily: _sans));
      }
      glyphBottom = y + lh;
    }

    // 上下卦标注: ☰ 上 · 天　☷ 下 · 地
    _centerText(canvas, w, '${hex.triU} 上 · ${hex.triUN}　${hex.triD} 下 · ${hex.triDN}',
        glyphBottom + 26,
        const TextStyle(fontSize: 20, color: _muted, fontFamily: _serif));

    // 卦名 + 拼音 + 卦德
    _centerText(canvas, w, '${hex.name} 卦', 448,
        const TextStyle(fontSize: 76, color: _text, fontFamily: _serif, letterSpacing: 8));
    _centerText(canvas, w, hex.en, 548,
        const TextStyle(fontSize: 22, color: _gold, fontFamily: _sans));
    _centerText(canvas, w, hex.desc, 580,
        const TextStyle(fontSize: 26, color: _text, fontFamily: _serif, letterSpacing: 3));

    // 分隔线
    canvas.drawLine(
      const Offset(140, 636),
      Offset(_kCardW - 140, 636),
      Paint()
        ..strokeWidth = 1
        ..color = const Color(0x47C9A876),
    );

    // 卦辞 (≤3 行) + 白话 (≤5 行)
    var y = 668.0;
    if (hex.guaci.isNotEmpty) {
      final lines = _wrapCentered(canvas, '「${hex.guaci}」', w - 160,
          const TextStyle(fontSize: 30, color: _text, fontFamily: _serif), 3, 46);
      y += lines * 46;
    }
    if (hex.intro.isNotEmpty) {
      _wrapCentered(canvas, hex.intro, w - 160,
          const TextStyle(fontSize: 22, color: _muted, fontFamily: _sans), 5, 34,
          top: y + 16);
    }

    // 所问之事 (≤2 行, 朱砂)
    if (data.question.isNotEmpty) {
      _wrapCentered(canvas, '所问：${data.question}', w - 200,
          const TextStyle(fontSize: 20, color: Color(0xE6D04D3E), fontFamily: _serif), 2, 30,
          top: _kCardH - 160);
    }

    // 页脚: 品牌 + 干支落款 + 公历
    final stamp = '${data.now.year}-${data.now.month.toString().padLeft(2, '0')}-'
        '${data.now.day.toString().padLeft(2, '0')}';
    _centerText(canvas, w, '易 道 · 卦 象 解 读　${ganzhiFull(data.now)}　$stamp', _kCardH - 84,
        const TextStyle(fontSize: 20, color: Color(0xBFB0A088), fontFamily: _sans, letterSpacing: 2));
  }

  TextPainter _tp(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: _kCardW - 80);
    return tp;
  }

  void _centerText(Canvas canvas, double cx, String text, double top, TextStyle style) {
    final tp = _tp(text, style);
    tp.paint(canvas, Offset(cx - tp.width / 2, top));
  }

  /// 居中多行绘制 (CJK 逐字断行), 返回行数
  int _wrapCentered(Canvas canvas, String text, double maxW, TextStyle style,
      int maxLines, double lineH, {double? top}) {
    final lines = <String>[];
    for (final para in text.split('\n')) {
      var line = '';
      for (final ch in para.split('')) {
        final test = line + ch;
        if (_measure(test, style) > maxW && line.isNotEmpty) {
          lines.add(line);
          line = ch;
        } else {
          line = test;
        }
        if (lines.length >= maxLines) break;
      }
      if (line.isNotEmpty && lines.length < maxLines) lines.add(line);
      if (lines.length >= maxLines) break;
    }
    if (top == null) return lines.length;
    var y = top;
    for (final l in lines) {
      _centerText(canvas, _kCardW / 2, l, y, style);
      y += lineH;
    }
    return lines.length;
  }

  double _measure(String text, TextStyle style) =>
      _tp(text, style).width;

  @override
  bool shouldRepaint(covariant ShareCardPainter old) => old.data != data;
}
