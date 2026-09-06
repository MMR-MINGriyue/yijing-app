import 'package:flutter/material.dart';

import '../../theme/yijing_theme.dart';

/// 起卦推演动画 — 六爻逐爻点亮循环 (iter38 替换普通 spinner, 主题化)
/// 每爻依次亮起 (金 30% → 90%), 末段整体回落, 配合文字呼吸
class CastingAnim extends StatefulWidget {
  const CastingAnim({super.key, this.size = 180});

  final double size;

  @override
  State<CastingAnim> createState() => _CastingAnimState();
}

class _CastingAnimState extends State<CastingAnim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 第 [i] 爻 (0=下 … 5=上) 在周期内的亮度: 依次点亮 + 末段整体回落
  double _lineGlow(int i) {
    final t = _ctrl.value;
    const stagger = 0.11;
    final start = i * stagger;
    final lit = ((t - start) / 0.16).clamp(0.0, 1.0); // 点亮上升段
    final settle = t > 0.82 ? ((t - 0.82) / 0.18) : 0.0; // 末段回落
    final base = 0.30 + 0.60 * Curves.easeOutExpo.transform(lit);
    return base * (1 - 0.55 * Curves.easeIn.transform(settle));
  }

  @override
  Widget build(BuildContext context) {
    const lw = 120.0, lh = 8.0, gap = 12.0;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: 6 * (lh + gap), // 每行含 bottom padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var k = 5; k >= 0; k--) // 上爻在上
                  Padding(
                    padding: const EdgeInsets.only(bottom: gap),
                    child: _row(k % 2 == 1, _lineGlow(k), lw, lh),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '卦 象 推 演 中',
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 4,
              color: YiColors.gold.withValues(alpha: 0.55 + 0.45 * _lineGlow(2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(bool yang, double glow, double lw, double lh) {
    final color = YiColors.gold.withValues(alpha: glow.clamp(0.0, 1.0));
    Widget seg(double w) => Container(
          width: w,
          height: lh,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(lh / 2),
            boxShadow: glow > 0.7
                ? [BoxShadow(color: YiColors.gold.withValues(alpha: 0.35), blurRadius: 12)]
                : null,
          ),
        );
    if (yang) return seg(lw);
    final half = (lw - lh * 1.6) / 2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [seg(half), SizedBox(width: lh * 1.6), seg(half)],
    );
  }
}
