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
  );
}
