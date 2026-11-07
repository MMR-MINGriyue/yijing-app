import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/app/app_shell.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/theme/yijing_theme.dart';
import 'package:yijing_transform/view/splash/bagua_splash.dart';
import 'package:yijing_transform/view/widgets/stagger_in.dart';

void main() {
  setUpAll(() => HexRepository.instance.init());

  Finder heroFinder() => find.byWidgetPredicate(
      (w) => w is Hero && w.tag == YiMotion.dailyHexHero);

  testWidgets('底栏朱砂指示条随 Tab 滑动 (iter60)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pump(const Duration(milliseconds: 400));
    final ind = find.byKey(const Key('tab_indicator'));
    final before = tester.widget<AnimatedPositioned>(ind).left!;
    await tester.tap(find.descendant(
        of: find.byType(BottomNavigationBar), matching: find.text('八字')));
    await tester.pump(const Duration(milliseconds: 400));
    final after = tester.widget<AnimatedPositioned>(ind).left!;
    expect(after - before, greaterThan(150)); // 800 宽屏 /4 = 200, 跨两格 = 400
  });

  testWidgets('启动转盘进入: hero 卡免淡入, 六爻 Hero 落点稳定', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BaguaSplash(now: DateTime(2026, 9, 19, 10, 30)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2900));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AppShell), findsOneWidget);
    expect(tester.widget<AppShell>(find.byType(AppShell)).fromSplash, isTrue);
    // hero 六爻不在 StaggerIn 子树里 (免淡入)
    expect(
        find
            .ancestor(of: heroFinder(), matching: find.byType(StaggerIn))
            .evaluate(),
        isEmpty);
  });

  testWidgets('普通进入 AppShell: hero 仍走错峰入场', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pump(const Duration(milliseconds: 600)); // 让五段 stagger delay Timer 全部跑完
    expect(tester.widget<AppShell>(find.byType(AppShell)).fromSplash, isFalse);
    expect(
        find
            .ancestor(of: heroFinder(), matching: find.byType(StaggerIn))
            .evaluate(),
        isNotEmpty);
  });
}
