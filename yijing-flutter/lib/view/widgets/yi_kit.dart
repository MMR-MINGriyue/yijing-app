import 'package:flutter/material.dart';

import '../../theme/yijing_theme.dart';
import '../../theme/yi_ornament.dart';
import 'pressable.dart';

/// iter74 (v1.65.0): 共享设计组件 — 抽取各屏复制粘贴的「激活态 chip / 空状态 /
/// 分组标题」骨架. 参数化保留各屏既有视觉差异 (圆角/透明度/圆点/计数), 严格视觉等价;
/// 近似色合并属设计变更, 不在本轮范围.

/// 筛选 chip — 激活态朱砂 + 非激活墨底 + 圆角描边 + 按压反馈.
///
/// 变体: [dot] 左侧小圆点 (卦库宫筛选), [count] 右侧计数 (历史筛选),
/// [inkWell] 用 InkWell 而非 PressableScale (详情方向选择).
class YiFilterChip extends StatelessWidget {
  const YiFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.accent = YiColors.cinnabar,
    this.count,
    this.dot = false,
    this.radius = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    this.activeFill,
    this.inactiveTextColor = YiColors.textTertiary,
    this.inactiveBorderColor = YiColors.strokeSoft,
    this.letterSpacing = 1,
    this.inkWell = false,
    this.center = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color accent;
  final int? count;
  final bool dot;
  final double radius;
  final EdgeInsets padding;
  final Color? activeFill;
  final Color inactiveTextColor;
  final Color inactiveBorderColor;
  final double letterSpacing;
  final bool inkWell;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final fg = active ? accent : inactiveTextColor;
    final content = Row(mainAxisSize: MainAxisSize.min, children: [
      if (dot)
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: active ? accent : YiColors.textMuted,
            shape: BoxShape.circle,
          ),
        ),
      if (dot) const SizedBox(width: YiSpacing.sm),
      Text(
        count == null ? label : '$label  $count',
        style: YiType.chip.copyWith(letterSpacing: letterSpacing, color: fg),
      ),
    ]);
    final box = AnimatedContainer(
      duration: YiMotion.base,
      curve: YiMotion.easeOutExpo,
      padding: padding,
      alignment: center ? Alignment.center : null,
      decoration: BoxDecoration(
        color: active
            ? (activeFill ?? accent.withValues(alpha: 0.2))
            : YiColors.inkCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
            color: active ? accent : inactiveBorderColor),
      ),
      child: content,
    );
    if (inkWell) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: box,
      );
    }
    return PressableScale(onTap: onTap, scale: 0.94, child: box);
  }
}

/// 空状态 — 可选印章 + 主文案 + 提示行.
class YiEmptyState extends StatelessWidget {
  const YiEmptyState({
    super.key,
    required this.message,
    this.hint,
    this.seal,
    this.messageStyle = const TextStyle(
        fontSize: 13, letterSpacing: 2, color: YiColors.textSecondary),
  });

  final String message;
  final String? hint;
  final String? seal;
  final TextStyle messageStyle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (seal != null) YiSeal(text: seal!, size: 34),
        if (seal != null) const SizedBox(height: YiSpacing.xl),
        Text(message, style: messageStyle),
        if (hint != null) ...[
          const SizedBox(height: YiSpacing.sm),
          Text(hint!, style: YiType.hint),
        ],
      ]),
    );
  }
}

/// 分组小标题 — 可选图标 + 尾部细线 (设置面板) 或纯文字 (我的 / 历史).
class YiSectionTitle extends StatelessWidget {
  const YiSectionTitle(
    this.text, {
    super.key,
    this.icon,
    this.color = YiColors.textTertiary,
    this.fontSize = 11,
    this.letterSpacing = 3,
    this.divider = false,
    this.padding,
  });

  final String text;
  final IconData? icon;
  final Color color;
  final double fontSize;
  final double letterSpacing;
  final bool divider;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        fontSize: fontSize, letterSpacing: letterSpacing, color: color);
    // 纯文字变体直接返回 Text: 调用方常把它嵌在 Row 里,
    // 再套一层 Row 会在无界横向约束下出问题.
    if (icon == null && !divider) {
      final label = Text(text, style: style);
      return padding == null
          ? label
          : Padding(padding: padding!, child: label);
    }
    final row = Row(children: [
      if (icon != null) ...[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: YiSpacing.md),
      ],
      Text(text, style: style),
      if (divider) ...[
        const SizedBox(width: YiSpacing.lg),
        Expanded(
          child: Divider(
              color: color.withValues(alpha: 0.28),
              height: 1,
              thickness: 1),
        ),
      ],
    ]);
    return padding == null
        ? row
        : Padding(padding: padding!, child: row);
  }
}
