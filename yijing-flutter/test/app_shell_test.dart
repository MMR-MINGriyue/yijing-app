import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/app/app_shell.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/view/widgets/share_card.dart';
import 'package:yijing_transform/viewmodel/detail_viewmodel.dart';
import 'package:yijing_transform/view/detail_screen.dart';
import 'package:yijing_transform/view/hero_fullscreen.dart';
import 'package:yijing_transform/data/favorites_store.dart';
import 'package:yijing_transform/service/reminder_service.dart';

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

  testWidgets('壳层 4 Tab 默认今日屏 (问候 + 今日一卦 + 最近占卜)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();
    expect(find.text('最 近 占 卜'), findsOneWidget);
    // 4 个 tab (grid/history 图标与我的页快捷入口共用, 允许多处)
    expect(find.byIcon(Icons.wb_twilight_outlined), findsWidgets);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    expect(find.byIcon(Icons.grid_view_outlined), findsWidgets);
    expect(find.byIcon(Icons.history), findsWidgets);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
  });

  testWidgets('今日一卦 hero 点击 → 全屏详解 → 依此卦起卦落起卦屏', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('今日一卦 · 依时而定'));
    await tester.pumpAndSettle();
    // iter38: hero 进全屏详解 (不再是直接推详情页)
    expect(find.text('本 卦 · 详 解'), findsOneWidget);
    // 全屏页 ListView 是唯一可滚动体 (壳层 IndexedStack 另有 5 个屏的 Scrollable)
    final fsScroll = find.descendant(
      of: find.byType(HeroFullscreen),
      matching: find.byType(Scrollable),
    );
    // 六爻手风琴: 滚到爻区 → 点初爻展开 (ListView 只构建可见 children)
    await tester.scrollUntilVisible(find.text('点 击 任 意 爻 查 看 爻 辞'), 300, scrollable: fsScroll);
    expect(find.text('点 击 任 意 爻 查 看 爻 辞'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('初'), 300, scrollable: fsScroll);
    await tester.tap(find.text('初'));
    await tester.pumpAndSettle();
    // 底部「依此卦起卦」→ 关闭全屏 + 切到起卦 Tab
    await tester.scrollUntilVisible(find.text('依此卦起卦'), 300, scrollable: fsScroll);
    await tester.tap(find.text('依此卦起卦'));
    await tester.pumpAndSettle();
    expect(find.text('本 卦 · 详 解'), findsNothing);
    expect(tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex, 1);
  });

  testWidgets('点通知 → 直达起卦屏 (iter41 每日提醒 payload)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();
    BottomNavigationBar bar() =>
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(bar().currentIndex, 0);
    NotificationTapBus.instance.emit(kRemindPayloadCast);
    await tester.pumpAndSettle();
    expect(bar().currentIndex, 1); // 屏2 起卦
  });

  testWidgets('设置面板: 备份为文件 / 从文件导入 (iter41)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();
    await goTab(tester, '我的');
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('备份为文件'), findsOneWidget);
    expect(find.text('从文件导入'), findsOneWidget);
  });

  testWidgets('Tab 切换: 我的 → 卦库/历史推入; 占卜页占法内联 (iter46)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();

    // 我的 → 六十四卦 (推入路由)
    await goTab(tester, '我的');
    expect(find.text('占 卜 概 览'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('六十四卦'), 250);
    await tester.tap(find.text('六十四卦'));
    await tester.pumpAndSettle();
    expect(find.text('六 十 四 卦'), findsOneWidget);
    expect(find.text('共 64 卦'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 我的 → 历史记录 (推入路由)
    await tester.tap(find.text('历史记录'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left), findsOneWidget); // 月份导航
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 占卜页: 三式 + 小六壬/梅花/八字 内联 (iter46 不再折叠)
    await goTab(tester, '占卜');
    expect(find.text('占  卜'), findsOneWidget);
    // 三占法卡在 ListView 折叠线下: 直接拖拽列表滚到底
    for (var i = 0; i < 8 && find.text('八字排盘').evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pumpAndSettle();
    }
    expect(find.text('小六壬'), findsOneWidget);
    expect(find.text('梅花易数'), findsOneWidget);
    expect(find.text('更多占法'), findsNothing);

    // iter47: 八字独立 Tab
    await goTab(tester, '八字');
    expect(find.text('八 字'), findsOneWidget);
    expect(find.text('排 盘 输 入'), findsOneWidget);
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
    // iter39: 每日提醒区块
    expect(find.text('每日占卜提醒'), findsOneWidget);
    expect(find.text('提醒时间'), findsOneWidget);
  });

  testWidgets('起卦闭环: CTA → 推演动画 → 结果 (iter37 回归)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();
    await goTab(tester, '占卜');
    // 表单必须有起卦 CTA (iter36 实测缺失)
    await tester.tap(find.text('起  卦'));
    await tester.pump(); // 进入 casting (六爻逐爻点亮动画)
    expect(find.text('卦 象 推 演 中'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300)); // 推过 1.1s 动画 → done
    await tester.pump(const Duration(milliseconds: 100));
    // 结果页动爻呼吸动画永不静止, 不能 pumpAndSettle — 用定长 pump
    expect(find.text('卦 象 已 成'), findsOneWidget);
    expect(find.text('查看卦辞解析'), findsOneWidget);
  });

  testWidgets('卦库点卦 → 详情; 详情 → 变卦推演路由', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();

    await goTab(tester, '我的');
    await tester.scrollUntilVisible(find.text('六十四卦'), 250);
    await tester.tap(find.text('六十四卦'));
    await tester.pumpAndSettle();
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
