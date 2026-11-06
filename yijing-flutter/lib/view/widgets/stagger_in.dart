import 'package:flutter/material.dart';

import '../../theme/yijing_theme.dart';

/// 入场编排 — 淡入 + 上浮 16px, ease-out-expo, 按 [delay] 错峰
/// (PWA v1.17 首屏四段式 stagger 的 Flutter 对应物)
class StaggerIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset offset; // 起始位移

  const StaggerIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 16),
  });

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: YiMotion.slow);
  late final Animation<double> _anim = CurvedAnimation(
    parent: _ctrl,
    curve: YiMotion.easeOutExpo,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // iter59: 系统减少动画 → 直接落终态 (MediaQuery 依赖必须在此读取)
    if (MediaQuery.of(context).disableAnimations) {
      _ctrl.value = 1.0;
      return;
    }
    final delay = YiMotion.reduced(context, widget.delay);
    if (delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween(begin: widget.offset, end: Offset.zero).animate(_anim),
        child: widget.child,
      ),
    );
  }
}
