// iter74 (v1.65.0): 设计组件抽取 — 锁定视觉参数与原实现完全一致
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/theme/yijing_theme.dart';
import 'package:yijing_transform/view/hexgrid_screen.dart';
import 'package:yijing_transform/view/widgets/yi_kit.dart';
import 'package:yijing_transform/viewmodel/hexgrid_viewmodel.dart';

void main() {
  setUpAll(() => HexRepository.instance.init());

  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  BoxDecoration decorationOf(WidgetTester tester) => tester
      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
      .decoration! as BoxDecoration;

  group('YiFilterChip — 三处调用点的旧视觉参数', () {
    testWidgets('卦库变体: 圆点 / 18 圆角 / 14×7 padding / 朱砂 20% 底',
        (tester) async {
      await tester.pumpWidget(wrap(YiFilterChip(
        label: '乾宫',
        active: true,
        onTap: () {},
        dot: true,
        activeFill: YiColors.activeTint,
      )));
      final box = decorationOf(tester);
      expect(box.color, YiColors.activeTint);
      expect(box.borderRadius, BorderRadius.circular(18));
      expect((box.border as Border).top.color, YiColors.cinnabar);
      final c = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(c.padding, const EdgeInsets.symmetric(horizontal: 14, vertical: 7));
      expect(c.duration, YiMotion.base);
      final t = tester.widget<Text>(find.text('乾宫'));
      expect(t.style?.fontSize, 12);
      expect(t.style?.letterSpacing, 1);
      expect(t.style?.color, YiColors.cinnabar);

      // 非激活态: 墨底 + 软描边 + tertiary 文字
      await tester.pumpWidget(wrap(YiFilterChip(
        label: '乾宫', active: false, onTap: () {}, dot: true,
      )));
      final off = decorationOf(tester);
      expect(off.color, YiColors.inkCard);
      expect((off.border as Border).top.color, YiColors.strokeSoft);
      expect(tester.widget<Text>(find.text('乾宫')).style?.color,
          YiColors.textTertiary);
    });

    testWidgets('历史变体: 计数文本 / 17 圆角 / 居中 / 0.5 字距',
        (tester) async {
      await tester.pumpWidget(wrap(YiFilterChip(
        label: '卦象',
        count: 3,
        active: true,
        onTap: () {},
        radius: 17,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        activeFill: YiColors.activeTintSoft,
        inactiveTextColor: YiColors.textSecondary,
        letterSpacing: 0.5,
        center: true,
      )));
      expect(find.text('卦象  3'), findsOneWidget);
      final box = decorationOf(tester);
      expect(box.color, YiColors.activeTintSoft);
      expect(box.borderRadius, BorderRadius.circular(17));
      final c = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(c.alignment, Alignment.center);
      final t = tester.widget<Text>(find.text('卦象  3'));
      expect(t.style?.letterSpacing, 0.5);
      expect(t.style?.color, YiColors.cinnabar);
    });

    testWidgets('详情变体: InkWell / 10 圆角 / accent 18% / 2 字距',
        (tester) async {
      await tester.pumpWidget(wrap(YiFilterChip(
        label: '财运',
        active: true,
        onTap: () {},
        accent: YiColors.gold,
        activeFill: YiColors.gold.withValues(alpha: 0.18),
        inactiveTextColor: YiColors.textSecondary,
        inactiveBorderColor: YiColors.stroke,
        radius: 10,
        padding: const EdgeInsets.symmetric(vertical: 8),
        letterSpacing: 2,
        inkWell: true,
        center: true,
      )));
      expect(find.byType(InkWell), findsOneWidget);
      final box = decorationOf(tester);
      expect(box.color, YiColors.gold.withValues(alpha: 0.18));
      expect(box.borderRadius, BorderRadius.circular(10));
      expect((box.border as Border).top.color, YiColors.gold);
      final t = tester.widget<Text>(find.text('财运'));
      expect(t.style?.letterSpacing, 2);
      expect(t.style?.color, YiColors.gold);
    });
  });

  group('YiEmptyState / YiSectionTitle', () {
    testWidgets('空状态: 印章 + 主文案 + 提示行样式', (tester) async {
      await tester.pumpWidget(wrap(const YiEmptyState(
        seal: '无',
        message: '未找到相关卦象',
        hint: '换个卦名试试',
      )));
      expect(find.text('无'), findsOneWidget);
      final main = tester.widget<Text>(find.text('未找到相关卦象'));
      expect(main.style?.fontSize, 13);
      expect(main.style?.letterSpacing, 2);
      expect(main.style?.color, YiColors.textSecondary);
      final hint = tester.widget<Text>(find.text('换个卦名试试'));
      expect(hint.style?.fontSize, 11);
      expect(hint.style?.color, YiColors.textMuted);
    });

    testWidgets('纯文字标题不引入 Row (可安全嵌在父 Row 里)', (tester) async {
      await tester.pumpWidget(wrap(const YiSectionTitle('近 期', fontSize: 10)));
      expect(
          find.descendant(
              of: find.byType(YiSectionTitle), matching: find.byType(Row)),
          findsNothing);
      expect(tester.widget<Text>(find.text('近 期')).style?.fontSize, 10);
    });

    testWidgets('设置面板标题: 图标 + 细线 + padding', (tester) async {
      await tester.pumpWidget(wrap(const YiSectionTitle(
        '数 据 管 理',
        icon: Icons.storage_outlined,
        color: YiColors.gold,
        divider: true,
        padding: EdgeInsets.fromLTRB(4, 6, 4, 6),
      )));
      expect(find.byIcon(Icons.storage_outlined), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
    });
  });

  group('各屏确实接上共享组件', () {
    testWidgets('卦库屏使用 YiFilterChip', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: HexGridScreen(vm: HexGridViewModel(), onOpenDetail: (_) {}),
      ));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(YiFilterChip), findsWidgets);
    });
  });
}
