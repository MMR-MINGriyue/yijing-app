import 'package:flutter/material.dart';

import '../../theme/yijing_theme.dart';

/// 卦象绘制 — 上爻在上、初爻在下 (与易道 PWA HEX_DRAW_ORDER 一致)
/// [lines] 初→上; [moving] 动爻索引 (朱砂); 圆头爻线.
///
/// iter45 视觉升级:
/// - 爻身纵向金渐变 (亮金→暗金), 呼应图标与墨韵的金属质感
/// - 动爻朱砂渐变 + 柔光晕 (BoxShadow), 叠加原有 1.4s 呼吸
/// - [animated] 时逐爻入场: 自初爻起 60ms 步进浮现 + 上滑归位
///   (列表/网格场景 animated=false 保持静态, 不建控制器)
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

  static const LinearGradient _goldGrad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE0C298), Color(0xFFA8854F)],
  );

  static const LinearGradient _cinnabarGrad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8795C), Color(0xFFC43F30)],
  );

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    // 上爻先画 (lines 为初→上, 倒序渲染); step = 距初爻位数 (入场次序)
    // iter45b: 行距统一 — 每行 (除初爻) 一律留 gap, 修复全阳/连阴时粘连
    for (var i = lines.length - 1; i >= 0; i--) {
      final isMoving = moving.contains(i);
      final step = i; // 初爻 i=0 先入场
      final isLast = i == 0; // 初爻最后渲染, 不留尾距
      if (lines[i]) {
        rows.add(_wrap(_lineBody(width, _grad(isMoving)), isMoving, step, isLast));
      } else {
        final seg = (width - lineH * 1.6) / 2;
        rows.add(_wrap(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _seg(seg, _grad(isMoving)),
              SizedBox(width: lineH * 1.6),
              _seg(seg, _grad(isMoving)),
            ],
          ),
          isMoving,
          step,
          isLast,
        ));
      }
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Decoration _grad(bool isMoving) => BoxDecoration(
        gradient: isMoving ? _cinnabarGrad : (color == null ? _goldGrad : null),
        color: color,
        borderRadius: BorderRadius.circular(lineH / 2),
        boxShadow: isMoving
            ? [BoxShadow(
                  color: YiColors.cinnabar.withValues(alpha: 0.40),
                  blurRadius: lineH * 1.6,
                  spreadRadius: 0.5,
                )]
            : null,
      );

  Widget _lineBody(double w, Decoration deco) => Container(
        width: w,
        height: lineH,
        decoration: deco,
      );

  Widget _seg(double seg, Decoration deco) => Container(
        width: seg,
        height: lineH,
        decoration: deco,
      );

  /// 动爻呼吸 + 逐爻入场 (animated 时); 普通静态场景原样
  /// [isLast] 初爻不留尾距 (渲染序末行)
  Widget _wrap(Widget child, bool isMoving, int step, bool isLast) {
    if (!animated && isLast) return child;
    Widget w = Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : gap),
      child: child,
    );
    if (!animated) return w;
    if (isMoving) {
      w = _BreathingLine(cycle: YiMotion.breathCycle, child: w);
    }
    return _RevealLine(step: step, lineH: lineH, child: w);
  }
}

/// 动爻呼吸: opacity 0.55 ↔ 1 循环 (PWA 波纹呼吸对应物)
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

/// 逐爻入场: 初爻起每爻延迟 60ms, 320ms 内 fade + 上滑 6px 归位
class _RevealLine extends StatefulWidget {
  final int step;
  final double lineH;
  final Widget child;

  const _RevealLine({required this.step, required this.lineH, required this.child});

  @override
  State<_RevealLine> createState() => _RevealLineState();
}

class _RevealLineState extends State<_RevealLine>
    with SingleTickerProviderStateMixin {
  static const _dur = Duration(milliseconds: 320);
  static const _stagger = Duration(milliseconds: 60);

  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: _dur + (_stagger * widget.step))
        ..forward();
  late final Animation<double> _anim = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(
        widget.step == 0 ? 0 : (_stagger * widget.step).inMilliseconds /
            (_dur + _stagger * widget.step).inMilliseconds,
        1.0,
        curve: Curves.easeOutCubic,
      ));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, child) => Opacity(
          opacity: _anim.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _anim.value) * widget.lineH * 1.5),
            child: child,
          ),
        ),
        child: widget.child,
      );
}
