import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/yijing_theme.dart';

/// 页内滑动返回 (iter53) — 左缘右滑/全屏横拖平移页面, 过阈值即返回.
/// 用于推入路由 (卦库/历史/变卦推演); 详情页因左右滑切卦不套用.
///
/// iter73: 拖拽位移改 ValueNotifier 驱动 — 原实现每帧 setState 重建整页子树,
/// 现在只重建 Stack 里的位移层, GestureDetector + 页面内容作为 builder 的 child 缓存.
class SwipeBackPage extends StatefulWidget {
  const SwipeBackPage({super.key, required this.child});

  final Widget child;

  @override
  State<SwipeBackPage> createState() => _SwipeBackPageState();
}

@immutable
class _SwipeState {
  const _SwipeState(this.dx, this.dragging);

  final double dx;
  final bool dragging;
}

class _SwipeBackPageState extends State<SwipeBackPage> {
  final ValueNotifier<_SwipeState> _swipe =
      ValueNotifier<_SwipeState>(const _SwipeState(0, false));
  bool _fromEdge = false; // 起手是否落在边缘区 (iter56 规范: 仅边缘触发)

  static const double _thresholdRatio = 0.28; // 拖过屏宽 28% 即返回
  static const double _velocityThreshold = 800; // 或快速轻扫
  static const double _edgeWidth = 26; // 左右边缘触发区 (逻辑px, 对齐系统手势)

  @override
  void dispose() {
    _swipe.dispose();
    super.dispose();
  }

  bool _inEdge(double x) {
    final w = MediaQuery.of(context).size.width;
    return x <= _edgeWidth || x >= w - _edgeWidth;
  }

  /// down 瞬间判定边缘 (DragStart 已含 touchSlop 位移, 快扫会漏 — iter56)
  void _onDragDown(DragDownDetails d) {
    _fromEdge = _inEdge(d.localPosition.dx);
    _swipe.value = _SwipeState(_swipe.value.dx, _fromEdge);
  }

  void _onDragUpdateReal(DragUpdateDetails d) {
    if (!_swipe.value.dragging) return;
    _swipe.value = _SwipeState(
        max(0, _swipe.value.dx + d.delta.dx), true);
  }

  void _onDragEnd(DragEndDetails d) {
    final w = MediaQuery.of(context).size.width;
    final dx = _swipe.value.dx;
    final fast = (d.primaryVelocity ?? 0) > _velocityThreshold;
    final passed = _fromEdge &&
        (dx > w * _thresholdRatio || (fast && dx > w * 0.06));
    if (passed && mounted) {
      Navigator.of(context).maybePop();
    }
    _swipe.value = const _SwipeState(0, false);
    _fromEdge = false;
  }

  void _onDragCancel() {
    _swipe.value = const _SwipeState(0, false);
    _fromEdge = false;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return ValueListenableBuilder<_SwipeState>(
      valueListenable: _swipe,
      // 页面内容 (含整屏 ListView) 只在 widget.child 变化时重建, 拖拽期间零重建
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragDown: _onDragDown,
        onHorizontalDragUpdate: _onDragUpdateReal,
        onHorizontalDragEnd: _onDragEnd,
        onHorizontalDragCancel: _onDragCancel,
        child: widget.child,
      ),
      builder: (context, s, child) {
        return Stack(children: [
          // 底衬: 页面滑开时露出墨底
          const Positioned.fill(child: ColoredBox(color: YiColors.ink)),
          AnimatedSlide(
            offset: Offset(max(0, s.dx) / w, 0),
            duration: s.dragging
                ? Duration.zero
                : YiMotion.reduced(context, const Duration(milliseconds: 180)),
            curve: Curves.easeOutCubic,
            child: child,
          ),
          // 滑动时右缘投影, 强化层次
          if (s.dx > 0)
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
      },
    );
  }
}
