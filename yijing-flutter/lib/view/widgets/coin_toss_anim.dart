import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/yijing_theme.dart';

/// 铜钱投掷动画 (iter50 重构) — 六爻逐次真实掷币.
///
/// [tosses] 传入引擎结果 (6×3, 1=背 0=字) 时: 每爻一掷 (~430ms), 铜钱抛起
/// 翻转落定显示真实字背, 落定瞬间朱砂涟漪 + 地面阴影随高度缩放, 爻象自初爻
/// 逐根点亮 (三背/三字为动爻朱砂). [tosses] 为空时退化为装饰性循环翻转.
class CoinTossAnim extends StatefulWidget {
  const CoinTossAnim({super.key, this.tosses, this.coinSize = 58});

  final List<List<int>>? tosses;
  final double coinSize;

  static const int rounds = 6;
  static const int roundMs = 430;
  static Duration get realDuration =>
      const Duration(milliseconds: rounds * roundMs + 260);

  @override
  State<CoinTossAnim> createState() => _CoinTossAnimState();
}

class _CoinTossAnimState extends State<CoinTossAnim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final bool _real;

  @override
  void initState() {
    super.initState();
    _real = widget.tosses != null && widget.tosses!.length == CoinTossAnim.rounds;
    _ctrl = AnimationController(
      vsync: this,
      duration: _real
          ? CoinTossAnim.realDuration
          : const Duration(milliseconds: 2000),
    );
    if (_real) {
      _ctrl.forward();
    } else {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_real) return _decorative();
    final d = widget.coinSize;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final elapsed = _ctrl.value * CoinTossAnim.realDuration.inMilliseconds;
        final round =
            min(CoinTossAnim.rounds - 1, elapsed ~/ CoinTossAnim.roundMs);
        final t01 = ((elapsed - round * CoinTossAnim.roundMs) /
                CoinTossAnim.roundMs)
            .clamp(0.0, 1.0);
        return Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: d * 3 + 40,
            height: d + 46,
            child: Stack(alignment: Alignment.center, children: [
              // 地面阴影
              Positioned(
                bottom: 0,
                child: Row(children: [
                  for (var i = 0; i < 3; i++) ...[
                    _shadow(d, _heightOf(t01)),
                    if (i < 2) const SizedBox(width: 12),
                  ],
                ]),
              ),
              // 三枚铜钱 (抛起弧线 + 翻转 + 落定涟漪)
              Positioned(
                top: 46,
                child: Row(children: [
                  for (var i = 0; i < 3; i++) ...[
                    _tossCoin(i, round, t01),
                    if (i < 2) const SizedBox(width: 12),
                  ],
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          _bars(round, t01),
        ]);
      },
    );
  }

  double _heightOf(double t01) => sin(t01 * pi) * 40;

  Widget _tossCoin(int i, int round, double t01) {
    final d = widget.coinSize;
    final toss = widget.tosses![round];
    final isBack = toss[i] == 1;
    final h = _heightOf(t01);
    final flips = 2.0 + i * 0.5;
    final sy = cos(t01 * pi * flips).abs().clamp(0.10, 1.0);
    // 落定涟漪: t01 ∈ (0.82, 1]
    final ring = t01 > 0.82 ? (t01 - 0.82) / 0.18 : 0.0;
    return SizedBox(
      width: d + 8,
      height: d + 8,
      child: Stack(alignment: Alignment.center, children: [
        if (ring > 0)
          Container(
            width: d * (1.0 + ring * 0.5),
            height: d * (1.0 + ring * 0.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: YiColors.cinnabar.withValues(alpha: 1 - ring),
                  width: 1.5),
            ),
          ),
        Transform.translate(
          offset: Offset(0, -h),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1.0, max(0.10, sy), 1.0),
            child: _coin(d, isBack),
          ),
        ),
      ]),
    );
  }

  /// 爻象逐根点亮: 三背/三字 (动) 朱砂, 余暗金
  Widget _bars(int round, double t01) {
    const bh = 7.0, gap = 5.0, w = 76.0;
    Widget bar(int r) {
      final backs = widget.tosses![r].fold(0, (a, b) => a + b);
      final moving = backs == 0 || backs == 3;
      final yang = backs == 1 || backs == 3;
      final color = moving ? YiColors.cinnabar : YiColors.gold;
      Widget full() => Container(
          width: w,
          height: bh,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(bh / 2)));
      Widget broken() => Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: w * 0.4, height: bh,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(bh / 2))),
            const SizedBox(width: 11),
            Container(width: w * 0.4, height: bh,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(bh / 2))),
          ]);
      return Center(child: yang ? full() : broken());
    }

    return SizedBox(
      width: w + 8,
      height: 6 * (bh + gap),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 上爻在上的渲染序; 初爻先成沉底
          for (var r = CoinTossAnim.rounds - 1; r >= 0; r--)
            SizedBox(
              height: bh + gap,
              child: (r < round || (r == round && t01 > 0.9))
                  ? bar(r)
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  // ---------- 铜钱美术 (iter50): 双环郭 + 方孔内郭 + 钱文/满文 ----------

  Widget _shadow(double d, double h) {
    final k = 1 - (h / 40).clamp(0.0, 1.0);
    return Container(
      width: d * (0.6 + 0.34 * k),
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: Colors.black.withValues(alpha: 0.35 + 0.30 * k),
      ),
    );
  }

  Widget _coin(double d, bool isBack) {
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.4),
          radius: 1.15,
          colors: [Color(0xFFF2DDB0), Color(0xFFC9A876), Color(0xFF8F6F42)],
          stops: [0, 0.5, 1],
        ),
        border: Border.all(color: const Color(0xFF6E5432), width: 1.6),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(alignment: Alignment.center, children: [
        // 内郭细环
        Container(
          width: d * 0.84,
          height: d * 0.84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFF8F6F42).withValues(alpha: 0.8),
                width: 1),
          ),
        ),
        // 高光
        Positioned(
          left: d * 0.14,
          top: d * 0.08,
          child: Container(
            width: d * 0.3,
            height: d * 0.16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(d * 0.1),
              color: Colors.white.withValues(alpha: 0.20),
            ),
          ),
        ),
        // 方孔 + 内郭框
        Container(
          width: d * 0.27,
          height: d * 0.27,
          decoration: BoxDecoration(
            color: YiColors.ink,
            border: Border.all(color: const Color(0xFF8F6F42), width: 1),
          ),
        ),
        Container(
          width: d * 0.38,
          height: d * 0.38,
          decoration: BoxDecoration(
            border: Border.all(
                color: const Color(0xFF8F6F42).withValues(alpha: 0.75),
                width: 1),
          ),
        ),
        if (isBack)
          // 背面: 满文双弧 (抽象)
          SizedBox(
            width: d,
            height: d,
            child: CustomPaint(painter: _ManwenPainter()),
          )
        else
          // 字面: 乾隆通宝 (直读: 上乾 下隆 右通 左宝)
          ...[
            _char('乾', d, 0, -d * 0.30),
            _char('隆', d, 0, d * 0.30),
            _char('通', d, d * 0.30, 0),
            _char('宝', d, -d * 0.30, 0),
          ],
      ]),
    );
  }

  Widget _char(String ch, double d, double dx, double dy) {
    // Stack 居中对齐后仅 translate 一次 (iter50: 原 Align+translate 双重偏移飞出币面)
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Text(ch,
          style: TextStyle(
              fontSize: d * 0.17,
              height: 1.0,
              color: const Color(0xFF52391F))),
    );
  }

  // ---------- 装饰性循环 (无结果数据时的兜底) ----------

  Widget _decorative() {
    final d = widget.coinSize;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 3; i++) ...[
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) {
            final t = (_ctrl.value * 3 - i * 0.25).clamp(0.0, 1.0);
            final sy = cos(t * 2 * pi).abs().clamp(0.1, 1.0);
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(1.0, sy, 1.0),
              child: _coin(d, i.isEven),
            );
          },
        ),
        if (i < 2) const SizedBox(width: 12),
      ],
    ]);
  }
}

/// 背面满文双弧
class _ManwenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5E4526)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.26;
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), -0.9, 1.5, false, paint);
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.8), pi - 0.6, 1.3, false,
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
