import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/data/history_repository.dart';
import 'package:yijing_transform/data/history_store.dart';
import 'package:yijing_transform/theme/yijing_theme.dart';
import 'package:yijing_transform/view/home_screen.dart';
import 'package:yijing_transform/viewmodel/home_viewmodel.dart';

/// iter69 (v1.61.0): 首页今日卦卡 → 全屏详解 双 Hero 转场
void main() {
  setUp(() {
    HexRepository.instance.init();
  });

  HomeViewModel newVm() => HomeViewModel(
        hexRepo: HexRepository.instance,
        history: HistoryRepository(
            store: MemoryHistoryStore(), seedSamples: false),
      );

  Widget app() => MaterialApp(
        home: HomeScreen(
          vm: newVm(),
          onOpenDetail: (_, {question}) {},
          onGoCast: () {},
          onGoGrid: () {},
          onGoHistory: () {},
          onOpenSettings: () {},
        ),
      );

  int heroCount(WidgetTester tester, {Object? tag}) =>
      tester.widgetList<Hero>(find.byWidgetPredicate(
        (w) => w is Hero && (tag == null || w.tag == tag),
        skipOffstage: false, // 过渡期 home 路由处于 offstage
      )).length;

  testWidgets('首页卡与全屏页 Hero 配对 (卦象 + 卦名)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // 首页: 卦象 + 卦名 两个 Hero
    expect(heroCount(tester, tag: YiMotion.dailyHexHero), 1);
    expect(heroCount(tester, tag: YiMotion.dailyHexNameHero), 1);
  });

  testWidgets('点击今日卦卡 → 全屏页: 过渡期两路由 Hero 同现, 落位后打开', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('今日一卦 ·')); // 卡内卦名/卦辞皆可命中卡片
    await tester.pump(const Duration(milliseconds: 120)); // 飞行中段

    // 过渡期: 首页 2 + 全屏 2 = 4 个 Hero 同树
    expect(heroCount(tester, tag: YiMotion.dailyHexHero), 2);
    expect(heroCount(tester, tag: YiMotion.dailyHexNameHero), 2);
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    // 全屏落位: 六爻互动区 / 操作按钮可见
    expect(find.text('点 击 任 意 爻 查 看 爻 辞'), findsOneWidget);
    expect(find.text('分享卦象'), findsOneWidget);
    // 首页 (covered) + 全屏 各 1
    expect(heroCount(tester, tag: YiMotion.dailyHexNameHero), 2);
  });

  testWidgets('全屏页关闭 → 反向回到首页卡 (Hero 回飞)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('今日一卦 ·'));
    await tester.pumpAndSettle();
    expect(find.text('分享卦象'), findsOneWidget);

    await tester.tap(find.byTooltip('关闭'));
    await tester.pump(const Duration(milliseconds: 100)); // 回飞中段
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('分享卦象'), findsNothing);
    // 回到首页: Hero 配对仍在
    expect(heroCount(tester, tag: YiMotion.dailyHexHero), 1);
    expect(heroCount(tester, tag: YiMotion.dailyHexNameHero), 1);
  });
}
