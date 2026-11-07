import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/data/history_repository.dart';
import 'package:yijing_transform/data/history_store.dart';
import 'package:yijing_transform/model/hex.dart';
import 'package:yijing_transform/model/history.dart';
import 'package:yijing_transform/view/cast_screen.dart';
import 'package:yijing_transform/view/history_screen.dart';
import 'package:yijing_transform/view/me_screen.dart';
import 'package:yijing_transform/viewmodel/cast_viewmodel.dart';
import 'package:yijing_transform/viewmodel/history_viewmodel.dart';
import 'package:yijing_transform/viewmodel/me_viewmodel.dart';

void main() {
  setUpAll(() => HexRepository.instance.init());

  Widget app(Widget child, {bool reduced = false}) => MaterialApp(
        builder: (c, ch) => MediaQuery(
          data: MediaQuery.of(c).copyWith(disableAnimations: reduced),
          child: ch!,
        ),
        home: child,
      );

  HistoryRepository seeded() => HistoryRepository(
        store: MemoryHistoryStore([
          HistoryRecord(
            question: '测试一',
            direction: '事业',
            directionColor: 'gold',
            ts: DateTime(2026, 11, 6, 10),
            hexNo: 1,
            name: '乾',
          ),
          HistoryRecord(
            question: '测试二',
            direction: '感情',
            directionColor: 'pine',
            ts: DateTime(2026, 11, 5, 10),
            hexNo: 2,
            name: '坤',
          ),
        ]),
      );

  Finder bars(String prefix) => find.byWidgetPredicate((w) =>
      w is TweenAnimationBuilder<double> &&
      (w.key?.toString().contains(prefix) ?? false));

  testWidgets('分段器金色胶囊随选中滑动 (iter65)', (tester) async {
    await tester.pumpWidget(app(CastScreen(
      vm: CastViewModel(),
      onOpenDetail: (Hex _, {String? question}) {},
    )));
    await tester.pump();
    final ind = find.byKey(const Key('cast_segment_indicator'));
    final before = tester.widget<AnimatedPositioned>(ind).left!;
    await tester.tap(find.text('小六壬'));
    await tester.pump(const Duration(milliseconds: 350));
    final after = tester.widget<AnimatedPositioned>(ind).left!;
    expect(after - before, greaterThan(100));
  });

  testWidgets('分段器减少动画 → 滑动时长压零', (tester) async {
    await tester.pumpWidget(app(
      CastScreen(
        vm: CastViewModel(),
        onOpenDetail: (Hex _, {String? question}) {},
      ),
      reduced: true,
    ));
    await tester.pump();
    final ind = tester.widget<AnimatedPositioned>(
        find.byKey(const Key('cast_segment_indicator')));
    expect(ind.duration, Duration.zero);
  });

  testWidgets('我的页分布条为生长动画, 减少动画压零', (tester) async {
    final repo = seeded();
    final vm = MeViewModel(history: repo);
    await tester.pumpWidget(app(
      MeScreen(
        vm: vm,
        onOpenDetail: (_) {},
        onGoHistory: () {},
        onGoGrid: () {},
        onOpenSettings: () {},
      ),
      reduced: true,
    ));
    await tester.pump();
    expect(bars('dist_'), findsWidgets);
    final tb = tester.widget<TweenAnimationBuilder<double>>(bars('dist_').first);
    expect(tb.duration, Duration.zero);
  });

  testWidgets('分布条确实在生长: 中途短于终值, 结束到位', (tester) async {
    final repo = seeded();
    await tester.pumpWidget(app(MeScreen(
      vm: MeViewModel(history: repo),
      onOpenDetail: (_) {},
      onGoHistory: () {},
      onGoGrid: () {},
      onOpenSettings: () {},
    )));
    await tester.pump();
    final tb = tester
        .widgetList<TweenAnimationBuilder<double>>(bars('dist_'))
        .first;
    final target = tb.tween.end!;
    double fsbs() => tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .first
        .widthFactor!;
    await tester.pump(const Duration(milliseconds: 120));
    expect(fsbs(), lessThan(target));
    await tester.pump(const Duration(milliseconds: 900));
    expect(fsbs(), closeTo(target, 0.001));
  });

  testWidgets('历史记录逐项入场, 减少动画压零', (tester) async {
    final repo = seeded();
    await tester.pumpWidget(app(
      HistoryScreen(vm: HistoryViewModel(repo: repo)),
      reduced: true,
    ));
    await tester.pump();
    expect(bars('hist_'), findsWidgets);
    final tb = tester.widget<TweenAnimationBuilder<double>>(bars('hist_').first);
    expect(tb.duration, Duration.zero);
  });
}
