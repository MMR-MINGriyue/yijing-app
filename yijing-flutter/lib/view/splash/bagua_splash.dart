import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/app_shell.dart';
import '../../core/bagua.dart';
import '../../core/cast_engine.dart';
import '../../data/hex_repository.dart';
import '../../model/hex.dart';
import '../../theme/yijing_theme.dart';
import '../widgets/hex_glyph.dart';
import 'bagua_painter.dart';

/// 启动动画 (iter57) — 先天八卦双层转盘演算今时卦, 六爻 Hero 飞入主页.
/// 卦象由 hourHex(now) 预先算出 (与主页 todayHex 同源), 转盘只是仪式化呈现.
class BaguaSplash extends StatefulWidget {
  const BaguaSplash({super.key, this.now});

  /// 可注入时钟 (测试); 缺省 DateTime.now()
  final DateTime? now;

  /// 纯函数: 今时卦 (供测试断言与主页一致性)
  static Hex hexOf(DateTime now) =>
      HexRepository.instance.hexByNo(hourHex(now).no);

  @override
  State<BaguaSplash> createState() => _BaguaSplashState();
}

class _BaguaSplashState extends State<BaguaSplash>
    with SingleTickerProviderStateMixin {
  static const Duration _total = Duration(milliseconds: 2850);
  static const Duration _watchdogDelay = Duration(seconds: 4);

  late final AnimationController _ctrl;
  late final Animation<double> _spin;
  late final Animation<double> _reveal;
  Timer? _watchdog;
  bool _started = false;
  bool _entered = false;

  late final Hex _hex;
  late final int _upIndex;
  late final int _downIndex;

  @override
  void initState() {
    super.initState();
    _hex = BaguaSplash.hexOf(widget.now ?? DateTime.now());
    _upIndex = baguaIndexOf(_hex.triUN);
    _downIndex = baguaIndexOf(_hex.triDN);
    _ctrl = AnimationController(vsync: this, duration: _total);
    _spin = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.09, 0.65, curve: YiMotion.easeOutExpo));
    _reveal = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.65, 0.82, curve: Curves.easeOut));
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _enter();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      // 无障碍「减少动画」: 直接进主页
      WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
      return;
    }
    _ctrl.forward();
    _watchdog = Timer(_watchdogDelay, _enter);
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _enter() {
    if (_entered || !mounted) return;
    _entered = true;
    _watchdog?.cancel();
    Navigator.of(context).pushReplacement(_heroRoute());
  }

  /// 裸路由: 页面本身不做淡入, 由 Hero 六爻飞入承担过渡
  Route<void> _heroRoute() => PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const AppShell(),
        transitionsBuilder: (_, anim, _, child) => child,
      );

  @override
  Widget build(BuildContext context) {
    final step = pi / 4;
    // 外环顺时针 2 圈停上卦, 内环逆时针 2 圈停下卦
    final outerTarget = 2 * 2 * pi - _upIndex * step;
    final innerTarget = -(2 * 2 * pi) - _downIndex * step;
    return Scaffold(
      backgroundColor: YiColors.ink,
      body: SafeArea(
        child: Stack(children: [
          // 略偏上 + 高度限幅: 矮屏/横屏不与底部六爻重叠
          Align(
            alignment: const Alignment(0, -0.18),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) {
                final size = MediaQuery.of(context).size;
                final d = min(
                    min(size.width - 40, 340.0), size.height * 0.46);
                return SizedBox(
                  width: d,
                  height: d,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: BaguaPainter(
                        outerTurns: _spin.value * outerTarget,
                        innerTurns: _spin.value * innerTarget,
                        upIndex: _upIndex,
                        downIndex: _downIndex,
                        reveal: _reveal.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Positioned(
            top: 16,
            left: 24,
            child: Text('今 时 起 卦',
                style: TextStyle(
                    fontSize: 12, letterSpacing: 4, color: YiColors.gold)),
          ),
          Positioned(
            top: 8,
            right: 12,
            child: TextButton(
              onPressed: _enter,
              child: const Text('跳过 ›',
                  style: TextStyle(fontSize: 12, color: YiColors.textTertiary)),
            ),
          ),
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) => Opacity(
                opacity: _reveal.value,
                child: Column(children: [
                  Text('${_hex.name} · ${_hex.desc}',
                      style: const TextStyle(
                          fontSize: 16,
                          letterSpacing: 2,
                          color: YiColors.textPrimary)),
                  const SizedBox(height: 12),
                  Hero(
                    tag: YiMotion.dailyHexHero,
                    child: HexGlyph(
                        lines: _hex.yangs,
                        width: 76,
                        lineH: 8,
                        gap: 6,
                        animated: true),
                  ),
                  const SizedBox(height: 12),
                  const Text('今 日 一 卦',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 4,
                          color: YiColors.textTertiary)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
