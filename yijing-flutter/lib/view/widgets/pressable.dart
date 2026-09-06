import 'package:flutter/material.dart';

import '../../theme/yijing_theme.dart';

/// 全站按压反馈 — 按下 scale 0.96 (PWA v1.14 交互反馈体系)
/// 包裹卡片/chips/按钮等可点元素; onTap 为空时原样返回
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = YiMotion.pressScale,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent, // 空白区域也可命中 (子级无背景时)
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: YiMotion.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
