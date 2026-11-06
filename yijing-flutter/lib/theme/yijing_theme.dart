import 'package:flutter/material.dart';

/// 国风配色 — 与易道 PWA 设计系统一致
class YiColors {
  static const ink = Color(0xFF14100B);      // 墨: 底色
  static const inkCard = Color(0xFF1D1813);  // 卡片底
  static const inkElevated = Color(0xFF262019);
  static const cinnabar = Color(0xFFD04D3E); // 朱砂
  static const cinnabarSoft = Color(0x3320844E);
  static const gold = Color(0xFFC9A876);     // 暗金
  static const goldDark = Color(0xFF8A7148);
  static const pine = Color(0xFF5BA88A);     // 松绿
  static const textPrimary = Color(0xFFEDE6D8);
  static const textSecondary = Color(0xFFB8AB97);
  static const textTertiary = Color(0xFF94836A);
  static const textMuted = Color(0xFF6E6353);
  static const stroke = Color(0xFF3A3127);
  static const strokeSoft = Color(0xFF2A241D);

  // iter58 复古玄幻层: 古铜 / 符箓金 / 星银 / 旧纸
  static const bronze = Color(0xFF7A5C34);      // 古铜 (外郭)
  static const talisman = Color(0xFFD8B25A);    // 符箓金
  static const starSilver = Color(0xFF9AA6A2);  // 星宿银
  static const parchment = Color(0xFFE8D9BC);   // 旧纸米
}

/// 动效 token — PWA v1.17 全站 ease-out-expo 曲线体系 (iter38)
class YiMotion {
  YiMotion._();

  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 450);

  /// PWA 统一缓动: ease-out-expo (快速起步, 柔和收尾)
  static const Curve easeOutExpo = Cubic(0.16, 1.0, 0.3, 1.0);

  /// 全站按压反馈缩放 (PWA v1.14: 11 类可点元素 scale 0.96)
  static const double pressScale = 0.96;

  /// 动爻呼吸动画周期
  static const Duration breathCycle = Duration(milliseconds: 1400);

  /// 启动转盘六爻 → 主页今日一卦卡 共享 Hero tag (iter57)
  static const String dailyHexHero = 'daily-hex';

  /// 系统「减少动画」时把时长/延迟压零 (iter59 全站统一)
  static Duration reduced(BuildContext context, Duration d) =>
      MediaQuery.of(context).disableAnimations ? Duration.zero : d;

  /// 首屏入场编排五段 (iter59: 节气/四柱与卦语错峰)
  static const List<Duration> homeStagger = [
    Duration(milliseconds: 0),
    Duration(milliseconds: 110),
    Duration(milliseconds: 260),
    Duration(milliseconds: 380),
    Duration(milliseconds: 500),
  ];
}

/// 卡片装饰 (iter58 复古化) — 做旧墨渐变 + 古金细线 + 外圈第二道金线.
/// 双层描边由 boxShadow(spread) 形成, 全应用卡片一处生效.
Decoration yiCardDecoration({Color? border, double radius = 14}) {
  return BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF241D15), Color(0xFF17120E)],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border ?? YiColors.bronze, width: 1.0),
    boxShadow: [
      BoxShadow(
        color: YiColors.goldDark.withValues(alpha: 0.26),
        blurRadius: 0,
        spreadRadius: 1.5,
      ),
      BoxShadow(
        color: const Color(0xFF000000).withValues(alpha: 0.35),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

ThemeData buildYiTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: YiColors.ink,
    colorScheme: ColorScheme.fromSeed(
      seedColor: YiColors.cinnabar,
      brightness: Brightness.dark,
      surface: YiColors.inkCard,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: YiColors.textPrimary,
      displayColor: YiColors.textPrimary,
      fontFamily: 'NotoSerifSC',
    ),
    // 页面转场: 下层轻微后退 + 上层滑入 (与 PWA 屏间滑动观感一致)
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: _SlideFadePageTransitionsBuilder(),
      TargetPlatform.iOS: _SlideFadePageTransitionsBuilder(),
    }),
  );
}

class _SlideFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _SlideFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: YiMotion.easeOutExpo);
    return SlideTransition(
      position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(curved),
      child: FadeTransition(opacity: curved, child: child),
    );
  }
}
