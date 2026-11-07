import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/app/app_shell.dart';
import 'package:yijing_transform/core/bagua.dart';
import 'package:yijing_transform/core/daily_hex.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/theme/yijing_theme.dart';
import 'package:yijing_transform/view/splash/bagua_splash.dart';

void main() {
  setUpAll(() => HexRepository.instance.init());

  test('启动卦与主页同源: dailyHex(now) 且上下卦落先天八卦位', () {
    final now = DateTime(2026, 9, 19, 10, 30);
    final hex = BaguaSplash.hexOf(now);
    expect(hex.no, dailyHex(now).no); // 与 HomeViewModel.todayHex 同源
    final up = baguaIndexOf(hex.triUN);
    final down = baguaIndexOf(hex.triDN);
    expect(up, inInclusiveRange(0, 7));
    expect(down, inInclusiveRange(0, 7));
    expect(kBaguaXiantian[up].nature, hex.triUN);
    expect(kBaguaXiantian[down].nature, hex.triDN);
  });

  testWidgets('转盘动画完成 → 进入主页 (HexGlyph 共享 Hero)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BaguaSplash(now: DateTime(2026, 9, 19, 10, 30)),
    ));
    await tester.pump(); // 进入 didChangeDependencies, 启动控制器
    expect(find.text('今 时 起 卦'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(AppShell), findsNothing);
    await tester.pump(const Duration(milliseconds: 2900)); // 动画完成
    await tester.pump(const Duration(milliseconds: 500)); // Hero 飞入
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Hero && w.tag == YiMotion.dailyHexHero), findsWidgets);
  });

  testWidgets('点跳过 → 立即进主页', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BaguaSplash(now: DateTime(2026, 9, 19, 10, 30)),
    ));
    await tester.pump();
    await tester.tap(find.byType(TextButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('系统减少动画 → 跳过转盘直接进主页', (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: BaguaSplash(now: DateTime(2026, 9, 19, 10, 30)),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(AppShell), findsOneWidget);
  });
}
