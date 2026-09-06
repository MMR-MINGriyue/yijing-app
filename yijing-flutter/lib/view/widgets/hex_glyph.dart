import 'package:flutter/material.dart';

import '../../theme/yijing_theme.dart';

/// 卦象绘制 — 上爻在上、初爻在下 (与易道 PWA HEX_DRAW_ORDER 一致)
/// [lines] 初→上; [moving] 动爻索引 (朱砂色); 圆角爻线 (iter38)
/// [animated] 动爻呼吸动画 (朱砂线 1.4s 呼吸, PWA 波纹呼吸对应物; 列表场景保持静态)
class HexGlyph extends StatelessWidget {
  final List<bool> lines;
  final List<int> moving;
  final double width;
  final double lineH;
  final double gap;
  final Color? color;
  final bool animated;

  const HexGlyph({
    super.key,
    required this.lines,
    this.moving = const [],
    this.width = 36,
    this.lineH = 4,
    this.gap = 3,
    this.color,
    this.animated = false,
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
        rows.add(_line(Container(
          width: width,
          height: lineH,
          decoration: BoxDecoration(
            color: lc,
            borderRadius: BorderRadius.circular(lineH / 2),
          ),
        ), isMoving));
      } else {
        final seg = (width - lineH * 1.6) / 2;
        rows.add(_line(Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _seg(seg, lc),
              SizedBox(width: lineH * 1.6),
              _seg(seg, lc),
            ],
          ),
        ), isMoving));
      }
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Widget _seg(double seg, Color c) => Container(
        width: seg,
        height: lineH,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(lineH / 2),
        ),
      );

  /// 动爻呼吸: opacity 0.55 ↔ 1 循环; 普通爻原样
  Widget _line(Widget child, bool isMoving) {
    if (!isMoving || !animated) return child;
    return _BreathingLine(
      cycle: YiMotion.breathCycle,
      child: child,
    );
  }
}

class _BreathingLine extends StatefulWidget {
  final Duration cycle;
  final Widget child;

  const _BreathingLine({required this.cycle, required this.child});

  @override
  State<_BreathingLine> createState() => _BreathingLineState();
}

class _BreathingLineState extends State<_BreathingLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.cycle)..repeat(reverse: true);
  late final Animation<double> _opacity = Tween(begin: 0.55, end: 1.0)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
