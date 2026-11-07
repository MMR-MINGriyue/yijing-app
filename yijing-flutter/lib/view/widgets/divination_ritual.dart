import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/xiaoliuren.dart' show kXlrPalaces;
import '../../theme/yijing_theme.dart';
import '../../theme/yi_ornament.dart';

/// 其他占法起课仪式 (iter64) — 小六壬掐指轮转 / 梅花分爻显化.
/// UI 层拦截点击, 动画结束后回调 onDone 才落库写历史, VM 状态机不动.
/// 尊重系统「减少动画」: 直接完成.
enum RitualKind { xiaoLiuRen, meiHua }

class DivinationRitual extends StatefulWidget {
  const DivinationRitual({
    super.key,
    required this.kind,
    required this.onDone,
    this.path = const [],
  });

  final RitualKind kind;
  final List<String> path; // 小六壬三宫名 (月/日/时)
  final VoidCallback onDone;

  @override
  State<DivinationRitual> createState() => _DivinationRitualState();
}

class _DivinationRitualState extends State<DivinationRitual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _started = false;
  bool _done = false;

  static const Map<RitualKind, Duration> _durations = {
    RitualKind.xiaoLiuRen: Duration(milliseconds: 1500),
    RitualKind.meiHua: Duration(milliseconds: 1200),
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _durations[widget.kind]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return;
    }
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
    _ctrl.forward();
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const List<String> _stageLabels = ['月宫', '日宫', '时宫'];

  double _spin(double from, int to, double u) {
    final delta = 12 + (((to - from) % 6) + 6) % 6; // 多转 2 圈再停位
    return from + delta * Curves.easeOut.transform(u.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = _ctrl.value;
        final isXlr = widget.kind == RitualKind.xiaoLiuRen;
        final stage = t < 0.3 ? 0 : t < 0.6 ? 1 : t < 0.9 ? 2 : 3;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Text(isXlr ? '掐 指 起 课' : '梅 花 分 爻',
              style: const TextStyle(
                  fontSize: 14, letterSpacing: 6, color: YiColors.gold)),
          const SizedBox(height: 18),
          if (isXlr) _xlrWheel(t, stage) else _meihuaLines(t),
          const SizedBox(height: 16),
          if (isXlr)
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${_stageLabels[i]} · ${i < widget.path.length ? widget.path[i] : '—'}',
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      color: stage > i
                          ? (i == 2 ? YiColors.pine : YiColors.gold)
                          : YiColors.textMuted),
                ),
              )
          else
            Text(stage >= 2 ? '动爻既定 · 合卦将成' : '三爻自上落下 · 三爻自下升起',
                style: const TextStyle(
                    fontSize: 11, letterSpacing: 2, color: YiColors.textTertiary)),
        ]);
      },
    );
  }

  Widget _xlrWheel(double t, int stage) {
    final targets = <int>[
      for (final name in widget.path)
        kXlrPalaces.indexWhere((p) => p.name == name).clamp(0, 5)
    ];
    while (targets.length < 3) {
      targets.add(targets.isEmpty ? 0 : targets.last);
    }
    double cursor;
    if (stage == 0) {
      cursor = _spin(0, targets[0], t / 0.3);
    } else if (stage == 1) {
      cursor = _spin(targets[0].toDouble(), targets[1], (t - 0.3) / 0.3);
    } else if (stage == 2) {
      cursor = _spin(targets[1].toDouble(), targets[2], (t - 0.6) / 0.3);
    } else {
      cursor = targets[2].toDouble();
    }
    return SizedBox(
      width: 250,
      height: 250,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _XlrWheelPainter(
            cursor: cursor,
            targets: targets,
            stage: stage,
            ripple: stage >= 3 ? ((t - 0.9) / 0.1).clamp(0.0, 1.0) : 0.0,
          ),
        ),
      ),
    );
  }

  Widget _meihuaLines(double t) {
    const List<double> ys = [6, 26, 46, 120, 140, 160]; // 上三 / 下三 (中间留出太极位)
    return SizedBox(
      width: 210,
      height: 172,
      child: Stack(children: [
        Positioned(
          left: 15,
          right: 15,
          top: 82,
          child: Divider(color: YiColors.goldDark, height: 1, thickness: 1),
        ),
        const Positioned(
          left: 87,
          top: 68,
          child: SizedBox(
            width: 36,
            height: 36,
            child: RepaintBoundary(child: CustomPaint(painter: _MiniTaijiPainter())),
          ),
        ),
        for (var i = 0; i < 6; i++) _line(i, ys[i], t),
      ]),
    );
  }

  Widget _line(int i, double top, double t) {
    final eased = Interval(i * 0.06, i * 0.06 + 0.42,
            curve: YiMotion.easeOutExpo)
        .transform(t);
    final fromY = i < 3 ? -20.0 : 20.0;
    final flash = t < 0.9 ? sin(Interval(0.55, 0.8).transform(t) * pi) : 0.0;
    final color = Color.lerp(
        YiColors.gold, YiColors.cinnabar,
        i == 4 ? flash.clamp(0.0, 1.0).toDouble() : 0.0)!;
    return Positioned(
      left: 45,
      top: top,
      child: Opacity(
        opacity: eased,
        child: Transform.translate(
          offset: Offset(0, fromY * (1 - eased)),
          child: i == 2
              ? Row(children: [
                  _bar(52, color),
                  const SizedBox(width: 16),
                  _bar(52, color),
                ])
              : _bar(120, color),
        ),
      ),
    );
  }

  Widget _bar(double w, Color color) => Container(
        width: w,
        height: 7,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3.5),
        ),
      );
}

class _MiniTaijiPainter extends CustomPainter {
  const _MiniTaijiPainter();

  @override
  void paint(Canvas canvas, Size size) =>
      paintTaiji(canvas, Offset(size.width / 2, size.height / 2), size.width / 2);

  @override
  bool shouldRepaint(covariant _MiniTaijiPainter old) => false;
}

/// 六宫轮盘 — 朱砂光标跳格 / 三段停位 / 定盘涟漪
class _XlrWheelPainter extends CustomPainter {
  const _XlrWheelPainter({
    required this.cursor,
    required this.targets,
    required this.stage,
    required this.ripple,
  });

  final double cursor;
  final List<int> targets;
  final int stage;
  final double ripple;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final R = min(size.width, size.height) / 2;
    final ring = Paint()
      ..color = YiColors.goldDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final faint = Paint()
      ..color = YiColors.stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(c, R * 0.94, ring);
    canvas.drawCircle(c, R * 0.52, ring);
    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + (i + 0.5) * pi / 3;
      canvas.drawLine(
          c + Offset(cos(a) * R * 0.52, sin(a) * R * 0.52),
          c + Offset(cos(a) * R * 0.94, sin(a) * R * 0.94),
          faint);
    }
    // 六宫名
    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + i * pi / 3;
      final p = c + Offset(cos(a) * R * 0.73, sin(a) * R * 0.73);
      final stopped = stage > 0 && targets.indexWhere((v) => v == i) < stage &&
          targets.indexWhere((v) => v == i) >= 0;
      final tp = TextPainter(
        text: TextSpan(
            text: kXlrPalaces[i].name,
            style: TextStyle(
                fontSize: R * 0.115,
                color: stopped ? YiColors.gold : YiColors.textTertiary)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
      if (stopped) {
        canvas.drawCircle(
            p,
            R * 0.16,
            Paint()
              ..color = YiColors.gold
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4);
      }
    }
    // 中心太极
    paintTaiji(canvas, c, R * 0.20);
    // 朱砂光标 (沿环快速跳格)
    final a = -pi / 2 + (cursor % 6) * pi / 3;
    final cp = c + Offset(cos(a) * R * 0.94, sin(a) * R * 0.94);
    canvas.drawCircle(cp, R * 0.075, Paint()..color = YiColors.cinnabar);
    // 定盘涟漪
    if (stage >= 3) {
      final tp = c +
          Offset(cos(-pi / 2 + targets[2] * pi / 3) * R * 0.73,
              sin(-pi / 2 + targets[2] * pi / 3) * R * 0.73);
      canvas.drawCircle(
          tp,
          R * (0.16 + ripple * 0.24),
          Paint()
            ..color = YiColors.pine.withValues(alpha: ripple * 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _XlrWheelPainter old) =>
      old.cursor != cursor || old.stage != stage || old.ripple != ripple;
}
