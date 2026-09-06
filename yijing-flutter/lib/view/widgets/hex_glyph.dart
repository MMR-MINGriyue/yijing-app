import 'package:flutter/material.dart';

import '../../theme/yijing_theme.dart';

/// 卦象绘制 — 上爻在上、初爻在下 (与易道 PWA HEX_DRAW_ORDER 一致)
/// [lines] 初→上; [moving] 动爻索引 (朱砂色)
class HexGlyph extends StatelessWidget {
  final List<bool> lines;
  final List<int> moving;
  final double width;
  final double lineH;
  final double gap;
  final Color? color;

  const HexGlyph({
    super.key,
    required this.lines,
    this.moving = const [],
    this.width = 36,
    this.lineH = 4,
    this.gap = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? YiColors.gold;
    final rows = <Widget>[];
    // 上爻先画 (lines 为初→上, 倒序渲染)
    for (var i = lines.length - 1; i >= 0; i--) {
      final isMoving = moving.contains(i);
      final lc = isMoving ? YiColors.cinnabar : c;
      if (lines[i]) {
        rows.add(Container(
          width: width,
          height: lineH,
          color: lc,
          margin: EdgeInsets.only(bottom: gap),
        ));
      } else {
        final seg = (width - lineH * 1.6) / 2;
        rows.add(Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: seg, height: lineH, color: lc),
              SizedBox(width: lineH * 1.6),
              Container(width: seg, height: lineH, color: lc),
            ],
          ),
        ));
      }
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
