import 'package:flutter/material.dart';

import 'yijing_theme.dart';

/// 墨韵背景 (iter45) — 与新图标同源的层叠晕染:
/// 基底墨色 + 顶部金晕 (光) + 右下松绿沉晕 (水) + 左下朱砂微晕 (火).
/// 铺于各屏 Scaffold 之下, 主 surface 需透明背景以透出.
class YiInkWash extends StatelessWidget {
  final Widget child;

  const YiInkWash({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: YiColors.ink),
      child: Stack(children: [
        // 顶部金晕 — 呼应图标光晕
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1.15),
                radius: 1.3,
                colors: [
                  YiColors.gold.withValues(alpha: 0.10),
                  YiColors.gold.withValues(alpha: 0.0),
                ],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
        // 右下松绿沉晕
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.2, 1.25),
                radius: 1.1,
                colors: [
                  YiColors.pine.withValues(alpha: 0.07),
                  YiColors.pine.withValues(alpha: 0.0),
                ],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
        // 左下朱砂微晕
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-1.25, 1.3),
                radius: 1.0,
                colors: [
                  YiColors.cinnabar.withValues(alpha: 0.05),
                  YiColors.cinnabar.withValues(alpha: 0.0),
                ],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
        child,
      ]),
    );
  }
}
