import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/yijing_theme.dart';

/// 页内滑动返回 (iter53) — 左缘右滑/全屏横拖平移页面, 过阈值即返回.
/// 用于推入路由 (卦库/历史/变卦推演); 详情页因左右滑切卦不套用.
class SwipeBackPage extends StatefulWidget {
  const SwipeBackPage({super.key, required this.child});

  final Widget child;

  @override
  State<SwipeBackPage> createState() => _SwipeBackPageState();
}

class _SwipeBackPageState extends State<SwipeBackPage> {
  double _dx = 0;
  bool _dragging = false;

  static const double _thresholdRatio = 0.28; // 拖过屏宽 28% 即返回
  static const double _velocityThreshold = 800; // 或快速轻扫

  void _onDragEnd(DragEndDetails d) {
    final w = MediaQuery.of(context).size.width;
    final fast = (d.primaryVelocity ?? 0) > _velocityThreshold;
    final passed = _dx > w * _thresholdRatio || (fast && _dx > w * 0.06);
    if (passed && mounted) {
      Navigator.of(context).maybePop();
    }
    setState(() {
      _dx = 0;
      _dragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Stack(children: [
      // 底衬: 页面滑开时露出墨底
      const Positioned.fill(child: ColoredBox(color: YiColors.ink)),
      AnimatedSlide(
        offset: Offset(max(0, _dx) / w, 0),
        duration: _dragging ? Duration.zero : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) => setState(() => _dragging = true),
          onHorizontalDragUpdate: (d) =>
              setState(() => _dx = max(0, _dx + d.delta.dx)),
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: () => setState(() {
            _dx = 0;
            _dragging = false;
          }),
          child: widget.child,
        ),
      ),
      // 滑动时右缘投影, 强化层次
      if (_dx > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: -4),
                ],
              ),
            ),
          ),
        ),
    ]);
  }
}
