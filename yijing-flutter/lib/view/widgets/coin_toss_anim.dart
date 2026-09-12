import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/yijing_theme.dart';

/// 铜钱投掷动画 (iter46) — 三枚方孔铜钱依次翻掷、落定显字背.
/// 每枚独立时间轴: 前段 scaleX=cos 翻转 (过 0 侧面), 末段缓落定面 + 回弹.
/// 落定面: 偶数枚「字」(金底方孔+四点), 奇数枚「背」(金底方孔+满纹弧).
class CoinTossAnim extends StatefulWidget {
  const CoinTossAnim({super.key, this.coinSize = 62});

  final double coinSize;

  @override
  State<CoinTossAnim> createState() => _CoinTossAnimState();
}

class _CoinTossAnimState extends State<CoinTossAnim>
    with TickerProviderStateMixin {
  // 三枚错拍翻转; 第 4s 循环重来 (起卦阶段最多停留 ~1.1s, 只见首掷)
  final List<AnimationController> _ctrls = [];
  final List<double> _durations = [1400, 1700, 2000];

  @override
  void initState() {
    super.initState();
    for (final d in _durations) {
      _ctrls.add(AnimationController(vsync: this, duration: Duration(milliseconds: d.round()))
        ..repeat());
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  /// 翻转缩放 (scaleY): 翻掷段 |cos| 摆动, 落定段缓回 1
  double _flipScale(int i, double t) {
    const flipPortion = 0.62; // 前 62% 翻掷
    if (t < flipPortion) {
      final ft = t / flipPortion;
      final spins = 2.0 + i * 0.7;
      return cos(ft * spins * pi).abs().clamp(0.12, 1.0) +
          0.04 * sin(ft * spins * pi * 2);
    }
    final st = (t - flipPortion) / (1 - flipPortion); // 落定段
    return 1.0 - 0.08 * sin(st * pi) * (1 - st); // 轻微落地回弹
  }

  /// 落定透明度: 各枚错拍淡入
  double _settleAlpha(int i, double t) {
    final start = i * 0.06;
    return ((t - start) / 0.12).clamp(0.35, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 3; i++) ...[
        AnimatedBuilder(
          animation: _ctrls[i],
          builder: (_, _) {
            final t = _ctrls[i].value;
            final sy = _flipScale(i, t);
            final face = (i + DateTime.now().minute) % 2 == 0; // 落定面 (视觉装饰)
            return Opacity(
              opacity: _settleAlpha(i, t),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(1.0, max(0.12, sy), 1.0),
                child: _coin(i, face),
              ),
            );
          },
        ),
        if (i < 2) const SizedBox(width: 18),
      ],
    ]);
  }

  Widget _coin(int i, bool isCharFace) {
    final d = widget.coinSize;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.35),
          radius: 1.1,
          colors: [Color(0xFFEBD3A4), Color(0xFFC9A876), Color(0xFF8F6F42)],
          stops: [0, 0.55, 1],
        ),
        border: Border.all(color: const Color(0xFF6E5432), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: YiColors.gold.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Stack(alignment: Alignment.center, children: [
        // 方孔
        Container(
          width: d * 0.26,
          height: d * 0.26,
          decoration: BoxDecoration(
            color: YiColors.ink,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: const Color(0xFF8F6F42), width: 1),
          ),
        ),
        if (isCharFace)
          // 字面: 四点纹 (钱文抽象)
          ...List.generate(4, (k) {
            final a = k * pi / 2 + pi / 4;
            return Positioned(
              left: d / 2 + cos(a) * d * 0.32 - d * 0.035,
              top: d / 2 + sin(a) * d * 0.32 - d * 0.035,
              child: Container(
                width: d * 0.07,
                height: d * 0.07,
                decoration: BoxDecoration(
                    color: const Color(0xFF6E5432), shape: BoxShape.circle),
              ),
            );
          })
        else
          // 背面: 两道满纹弧 (抽象)
          ...[
            Positioned(
              left: d * 0.12,
              top: d * 0.30,
              child: Container(
                  width: d * 0.76, height: d * 0.05,
                  decoration: BoxDecoration(
                      color: const Color(0xFF8F6F42).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(2))),
            ),
            Positioned(
              left: d * 0.18,
              bottom: d * 0.22,
              child: Container(
                  width: d * 0.64, height: d * 0.05,
                  decoration: BoxDecoration(
                      color: const Color(0xFF8F6F42).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2))),
            ),
          ],
      ]),
    );
  }
}
