import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/cast_engine.dart';
import '../../core/yi_calendar.dart';
import '../../model/hex.dart';
import '../../theme/yi_ornament.dart';

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

  // iter73: 断行测量复用同一 TextPainter, 避免逐字符 new + layout 的对象分配
  final TextPainter _measureTp = TextPainter(
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  );

  ShareCardPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final hex = data.hex;
    final mv = data.moving;
    final w = size.width;

    // 背景: 竖向渐变 #241809 → #100B06 + 双金色氛围光 (卦象区/卦名区)
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
    final glow2Paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w / 2, 500), 320,
        [const Color(0x14D04D3E), const Color(0x00D04D3E)],
      );
    canvas.drawRect(Offset.zero & size, glow2Paint);

    // iter68: 双线边框 + 四角云头角饰
    canvas.drawRect(
      const Rect.fromLTWH(24, 24, _kCardW - 48, _kCardH - 48),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x59C9A876),
    );
    canvas.drawRect(
      const Rect.fromLTWH(32, 32, _kCardW - 64, _kCardH - 64),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x2EC9A876),
    );
    _cornerOrnaments(canvas);

    // 顶部标准太极 (与全应用同一 paintTaiji, iter57 修复版几何)
    paintTaiji(canvas, Offset(w / 2, 56), 15);

    // 序号: 第 N 卦 (中文数字)
    _centerText(canvas, w / 2, '第 ${cnNumber(hex.no)} 卦', 88,
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
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH((w - lw) / 2, y, lw, lh), const Radius.circular(6)),
            linePaint);
      } else {
        final half = (lw - 44) / 2;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH((w - lw) / 2, y, half, lh), const Radius.circular(6)),
            linePaint);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH((w - lw) / 2 + half + 44, y, half, lh),
                const Radius.circular(6)),
            linePaint);
      }
      if (isMoving) {
        // iter68: 动爻标注升级为朱砂小方章
        final bx = (w + lw) / 2 + 18;
        final by = y - 4;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(bx, by, 26, 26), const Radius.circular(4)),
            Paint()..color = _cinnabar.withValues(alpha: 0.92));
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(bx + 1.5, by + 1.5, 23, 23),
                const Radius.circular(3)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = const Color(0xFF8E2E24));
        _centerText(canvas, bx + 13, '动', by + 4,
            const TextStyle(fontSize: 15, color: Color(0xFFFFF3E4), fontFamily: _serif));
      }
      glyphBottom = y + lh;
    }

    // 上下卦标注: ☰ 上 · 天　☷ 下 · 地
    _centerText(canvas, w / 2, '${hex.triU} 上 · ${hex.triUN}　${hex.triD} 下 · ${hex.triDN}',
        glyphBottom + 26,
        const TextStyle(fontSize: 20, color: _muted, fontFamily: _serif));

    // 卦名 + 两侧饰线 + 拼音 + 卦德
    _centerText(canvas, w / 2, '${hex.name} 卦', 448,
        const TextStyle(fontSize: 76, color: _text, fontFamily: _serif, letterSpacing: 8));
    _sideOrnaments(canvas, w, 486);
    _centerText(canvas, w / 2, hex.en, 548,
        const TextStyle(fontSize: 22, color: _gold, fontFamily: _sans));
    _centerText(canvas, w / 2, hex.desc, 580,
        const TextStyle(fontSize: 26, color: _text, fontFamily: _serif, letterSpacing: 3));

    // 分隔线 (中央菱形, iter68)
    _diamondDivider(canvas, w, 636);

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
          top: _kCardH - 196);
    }

    // 动爻落款 (iter68: 有动爻时朱砂一行)
    if (mv.isNotEmpty) {
      _centerText(canvas, w / 2, '动 爻 · ${mv.map(hex.yaoName).join(' · ')}', _kCardH - 122,
          const TextStyle(fontSize: 18, color: _cinnabar, fontFamily: _serif, letterSpacing: 2));
    }

    // 页脚: 品牌 + 干支落款 + 公历
    final stamp = '${data.now.year}-${data.now.month.toString().padLeft(2, '0')}-'
        '${data.now.day.toString().padLeft(2, '0')}';
    _centerText(canvas, w / 2, '易 道 · 卦 象 解 读　${ganzhiFull(data.now)}　$stamp', _kCardH - 78,
        const TextStyle(fontSize: 20, color: Color(0xBFB0A088), fontFamily: _sans, letterSpacing: 2));

    // 朱砂竖印「易道」(iter68, 右下)
    _seal(canvas, w);
  }

  /// iter68: 四角云头角饰 — 双层 L 形金线
  void _cornerOrnaments(Canvas canvas) {
    const inset = 44.0, len = 42.0, len2 = 26.0, gap = 8.0;
    final p1 = Paint()
      ..strokeWidth = 2
      ..color = const Color(0x73C9A876)
      ..strokeCap = StrokeCap.round;
    final p2 = Paint()
      ..strokeWidth = 1
      ..color = const Color(0x40C9A876)
      ..strokeCap = StrokeCap.round;
    void corner(double x, double y, int dx, int dy) {
      // 外层
      canvas.drawLine(Offset(x + dx * inset, y + dy * inset),
          Offset(x + dx * (inset + len), y + dy * inset), p1);
      canvas.drawLine(Offset(x + dx * inset, y + dy * inset),
          Offset(x + dx * inset, y + dy * (inset + len)), p1);
      // 内层
      final i2 = inset + gap;
      canvas.drawLine(Offset(x + dx * i2, y + dy * i2),
          Offset(x + dx * (i2 + len2), y + dy * i2), p2);
      canvas.drawLine(Offset(x + dx * i2, y + dy * i2),
          Offset(x + dx * i2, y + dy * (i2 + len2)), p2);
    }
    corner(0, 0, 1, 1);
    corner(_kCardW, 0, -1, 1);
    corner(0, _kCardH, 1, -1);
    corner(_kCardW, _kCardH, -1, -1);
  }

  /// iter68: 卦名两侧饰线 — 短金线 + 内端菱形
  void _sideOrnaments(Canvas canvas, double w, double cy) {
    final p = Paint()
      ..strokeWidth = 1.2
      ..color = const Color(0x59C9A876);
    const halfGap = 150.0, lineLen = 64.0;
    for (final dir in <double>[-1, 1]) {
      final inner = w / 2 + dir * halfGap;
      final outer = w / 2 + dir * (halfGap + lineLen);
      canvas.drawLine(Offset(inner, cy), Offset(outer, cy), p);
      // 内端菱形
      final d = Path();
      d.moveTo(inner - dir * 5, cy);
      d.lineTo(inner, cy - 5);
      d.lineTo(inner + dir * 5, cy);
      d.lineTo(inner, cy + 5);
      d.close();
      canvas.drawPath(d, p);
    }
  }

  /// iter68: 分隔线 — 线·中央菱形·线
  void _diamondDivider(Canvas canvas, double w, double cy) {
    final p = Paint()
      ..strokeWidth = 1
      ..color = const Color(0x47C9A876);
    canvas.drawLine(Offset(140, cy), Offset(w / 2 - 14, cy), p);
    canvas.drawLine(Offset(w / 2 + 14, cy), Offset(_kCardW - 140, cy), p);
    final d = Path();
    d.moveTo(w / 2, cy - 6);
    d.lineTo(w / 2 + 7, cy);
    d.lineTo(w / 2, cy + 6);
    d.lineTo(w / 2 - 7, cy);
    d.close();
    canvas.drawPath(d, Paint()..color = const Color(0x80C9A876));
  }

  /// iter68: 朱砂竖印「易道」— 双字方印, 右下角
  void _seal(Canvas canvas, double w) {
    const boxW = 36.0, boxH = 74.0;
    final left = w - 82.0;
    final top = _kCardH - 178.0;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, boxW, boxH), const Radius.circular(4)),
        Paint()..color = _cinnabar.withValues(alpha: 0.9));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(left + 2, top + 2, boxW - 4, boxH - 4),
            const Radius.circular(3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF8E2E24));
    final style = const TextStyle(
        fontSize: 24, color: Color(0xFFFFF3E4), fontFamily: 'KaiTi',
        fontFamilyFallback: ['STKaiti', _serif]);
    _centerText(canvas, left + boxW / 2, '易', top + 9, style);
    _centerText(canvas, left + boxW / 2, '道', top + 41, style);
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
  /// iter73: 逐字符线性测量 → 二分找最长不超宽前缀, 测量次数 O(n) → O(行数·log n),
  /// 且共享 _measureTp 不再每字 new TextPainter. 断行语义与原实现等价.
  int _wrapCentered(Canvas canvas, String text, double maxW, TextStyle style,
      int maxLines, double lineH, {double? top}) {
    final lines = <String>[];
    for (final para in text.split('\n')) {
      if (lines.length >= maxLines) break;
      var start = 0;
      while (start < para.length && lines.length < maxLines) {
        var lo = start + 1;
        var hi = para.length;
        var best = start + 1; // 单字超宽时仍强制收 1 字, 与原实现一致
        while (lo <= hi) {
          final mid = (lo + hi) >> 1;
          if (_measure(para.substring(start, mid), style) <= maxW) {
            best = mid;
            lo = mid + 1;
          } else {
            hi = mid - 1;
          }
        }
        lines.add(para.substring(start, best));
        start = best;
      }
    }
    if (top == null) return lines.length;
    var y = top;
    for (final l in lines) {
      _centerText(canvas, _kCardW / 2, l, y, style);
      y += lineH;
    }
    return lines.length;
  }

  double _measure(String text, TextStyle style) {
    _measureTp
      ..text = TextSpan(text: text, style: style)
      ..layout(maxWidth: _kCardW - 80);
    return _measureTp.width;
  }

  @override
  bool shouldRepaint(covariant ShareCardPainter old) => old.data != data;
}
