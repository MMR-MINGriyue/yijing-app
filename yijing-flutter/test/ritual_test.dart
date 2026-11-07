import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/model/hex.dart';
import 'package:yijing_transform/view/cast_screen.dart';
import 'package:yijing_transform/view/widgets/divination_ritual.dart';
import 'package:yijing_transform/viewmodel/cast_viewmodel.dart';

void main() {
  setUpAll(() => HexRepository.instance.init());

  Widget shell(Widget child, {bool reduced = false}) => MaterialApp(
        builder: (c, ch) => MediaQuery(
          data: MediaQuery.of(c).copyWith(disableAnimations: reduced),
          child: ch!,
        ),
        home: Scaffold(body: child),
      );

  testWidgets('小六壬仪式: 六宫标签 + 1.5s 后回调一次', (tester) async {
    var done = 0;
    await tester.pumpWidget(shell(DivinationRitual(
      kind: RitualKind.xiaoLiuRen,
      path: const ['大安', '速喜', '小吉'],
      onDone: () => done++,
    )));
    await tester.pump();
    expect(find.text('掐 指 起 课'), findsOneWidget);
    expect(find.textContaining('月宫'), findsOneWidget);
    expect(find.textContaining('时宫'), findsOneWidget);
    expect(done, 0);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(done, 1);
  });

  testWidgets('梅花仪式: 分爻文案 + 1.2s 后回调一次', (tester) async {
    var done = 0;
    await tester.pumpWidget(shell(DivinationRitual(
      kind: RitualKind.meiHua,
      onDone: () => done++,
    )));
    await tester.pump();
    expect(find.text('梅 花 分 爻'), findsOneWidget);
    expect(find.textContaining('三爻'), findsOneWidget);
    expect(done, 0);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(done, 1);
  });

  testWidgets('系统减少动画 → 仪式直接完成', (tester) async {
    var done = 0;
    await tester.pumpWidget(shell(
      DivinationRitual(
        kind: RitualKind.xiaoLiuRen,
        path: const ['大安', '速喜', '小吉'],
        onDone: () => done++,
      ),
      reduced: true,
    ));
    await tester.pump();
    await tester.pump();
    expect(done, 1);
  });

  testWidgets('CastScreen 小六壬: 仪式结束才落库', (tester) async {
    final vm = CastViewModel();
    await tester.pumpWidget(MaterialApp(
      home: CastScreen(
        vm: vm,
        onOpenDetail: (Hex _, {String? question}) {},
      ),
    ));
    await tester.pump();
    await tester.tap(find.text('小六壬').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('即时起课'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('掐 指 起 课'), findsOneWidget);
    expect(vm.state.xlr, isNull); // 动画中未写历史
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('掐 指 起 课'), findsNothing);
    expect(vm.state.xlr, isNotNull);
  });

  testWidgets('CastScreen 梅花: 仪式结束才切结果页', (tester) async {
    final vm = CastViewModel();
    await tester.pumpWidget(MaterialApp(
      home: CastScreen(
        vm: vm,
        onOpenDetail: (Hex _, {String? question}) {},
      ),
    ));
    await tester.pump();
    await tester.tap(find.text('梅花易数').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('今日时辰起卦'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('梅 花 分 爻'), findsOneWidget);
    expect(vm.state.phase, isNot(CastPhase.done));
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.text('梅 花 分 爻'), findsNothing);
    expect(vm.state.phase, CastPhase.done);
  });
}
