import 'package:flutter/services.dart';

/// 触觉反馈统一入口 (iter70) — 全站同类交互同一触感.
///
/// - [tap]    轻点: 分段切换 / chips / 换一卦
/// - [light]  确认: 收藏星 / 投币逐爻落定
/// - [settle] 落定完成: 起卦出结果 / 仪式结束
/// - [warn]   破坏性操作: 删除记录
abstract final class Haptics {
  static void tap() => HapticFeedback.selectionClick();
  static void light() => HapticFeedback.lightImpact();
  static void settle() => HapticFeedback.mediumImpact();
  static void warn() => HapticFeedback.heavyImpact();
}
