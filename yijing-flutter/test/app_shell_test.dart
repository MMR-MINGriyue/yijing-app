import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/app/app_shell.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/view/widgets/share_card.dart';
import 'package:yijing_transform/viewmodel/detail_viewmodel.dart';
import 'package:yijing_transform/view/detail_screen.dart';
import 'package:yijing_transform/data/favorites_store.dart';

/// App 壳层冒烟: 5 Tab 渲染 + 详情路由 (纯 App 架构 iter33)
void main() {
  setUpAll(() {
    HexRepository.instance.init();
  });

  // IndexedStack 离屏子树也会被 find 命中, Tab 一律经 BottomNavigationBar 定位
  Future<void> goTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text(label),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('壳层 5 Tab 默认今日屏 (问候 + 今日一卦 + 最近占卜)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();
    expect(find.text('最 近 占 卜'), findsOneWidget);
    // 5 个 tab 图标 (grid/history 与首页快捷入口共用图标, 允许多处)
    expect(find.byIcon(Icons.wb_twilight_outlined), findsWidgets);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    expect(find.byIcon(Icons.grid_view_outlined), findsWidgets);
    expect(find.byIcon(Icons.history), findsWidgets);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('今日一卦 hero 点击 → 推入卦辞解析路由', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('今日一卦 · 依时而定'));
    await tester.pumpAndSettle();
    expect(find.text('卦 辞 解 析'), findsOneWidget); // 详情页 AppBar
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('最 近 占 卜'), findsOneWidget);
  });

  testWidgets('Tab 切换: 卦库 64 卦 + 历史 + 我的 + 起卦', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();

    await goTab(tester, '卦库');
    expect(find.text('六 十 四 卦'), findsOneWidget);
    expect(find.text('共 64 卦'), findsOneWidget);

    await goTab(tester, '历史');
    expect(find.byIcon(Icons.chevron_left), findsOneWidget); // 月份导航

    await goTab(tester, '我的');
    expect(find.text('占 卜 概 览'), findsOneWidget);

    await goTab(tester, '起卦');
    expect(find.text('起 卦'), findsOneWidget);
    expect(find.text('更多占法 ›  八字 · 小六壬 · 梅花易数'), findsOneWidget);
  });

  testWidgets('分享卡预览渲染 (720×1040 painter 不抛异常)', (tester) async {
    HexRepository.instance.init();
    final hex = HexRepository.instance.hexByNo(31);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ShareCardPreview(
            data: ShareCardData(
            hex: hex,
            moving: const [0],
            question: '与TA关系走向',
            now: DateTime(2026, 9, 6),
          )),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byType(ShareCardPreview), findsOneWidget);
  });

  testWidgets('屏4 爻行点击 → 爻辞弹窗 (含复制按钮)', (tester) async {
    HexRepository.instance.init();
    await tester.pumpWidget(MaterialApp(
      home: DetailScreen(
        vm: DetailViewModel(hexNo: 1, favs: FavoritesRepository(store: MemoryFavoritesStore())),
      ),
    ));
    await tester.pumpAndSettle();
    // 爻辞 Tab → 点击初九
    await tester.tap(find.text('爻辞'));
    await tester.pumpAndSettle();
    // 底部爻行带 InkWell (Tab 卡片无点击), 在视口外需先滚动
    final yaoRow = find.descendant(of: find.byType(InkWell), matching: find.text('初九'));
    await tester.scrollUntilVisible(yaoRow, 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(yaoRow);
    await tester.pumpAndSettle();
    expect(find.text('初九 · 乾卦'), findsOneWidget);
    expect(find.text('潜龙勿用。'), findsWidgets);
    expect(find.byIcon(Icons.copy), findsOneWidget);
  });

  testWidgets('屏7 ⚙ → 设置面板 (导出/导入/清空/重置)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();

    await goTab(tester, '我的');
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('设 置'), findsOneWidget);
    expect(find.text('导出历史数据'), findsOneWidget);
    expect(find.text('导入历史数据'), findsOneWidget);
    // 危险项默认非确认态
    expect(find.text('清空本地历史'), findsOneWidget);
    expect(find.text('重置为示例数据'), findsOneWidget);
  });

  testWidgets('卦库点卦 → 详情; 详情 → 变卦推演路由', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();

    await goTab(tester, '卦库');
    await tester.tap(find.text('乾').first);
    await tester.pumpAndSettle();
    expect(find.text('卦 辞 解 析'), findsOneWidget);

    // 详情页「查看变卦推演」→ 推入屏 5
    await tester.scrollUntilVisible(find.text('查看变卦推演'), 300);
    await tester.tap(find.text('查看变卦推演'));
    await tester.pumpAndSettle();
    expect(find.text('变 卦 推 演'), findsOneWidget);
  });
}
