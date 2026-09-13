import 'package:flutter/material.dart';

/// 易道路由过渡 (iter49) — 淡入 + 轻微上浮, 替代默认横滑
/// 用于详情/推演/卦库/历史等推入路由; HeroFullscreen 保持自带缩放淡入
Route<T> yiFadeRoute<T extends Object?>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, anim, _, child) {
      final curved = Curves.easeOutCubic.transform(anim.value);
      return FadeTransition(
        opacity: anim,
        child: Transform.translate(
          offset: Offset(0, (1 - curved) * 16),
          child: child,
        ),
      );
    },
  );
}
