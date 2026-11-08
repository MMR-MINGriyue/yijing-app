import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/data/favorites_store.dart';
import 'package:yijing_transform/data/history_repository.dart';
import 'package:yijing_transform/data/history_store.dart';
import 'package:yijing_transform/model/history.dart';
import 'package:yijing_transform/view/history_screen.dart';
import 'package:yijing_transform/viewmodel/history_viewmodel.dart';

/// iter67 (v1.59.0): 历史屏时间轴可视化
void main() {
  testWidgets('时间轴: 每日首条出日期徽章, 同日其余为圆点, 组尾不出轨', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final ym = DateTime(now.year, now.month);
    final repo = HistoryRepository(
      seedSamples: false,
      store: MemoryHistoryStore([
        // 同一天 (20 号) 三条 → 1 徽章 + 2 圆点
        HistoryRecord(
          hexNo: 1, name: '乾', question: '晚课复盘', direction: '事业',
          directionColor: 'cinnabar',
          ts: ym.add(const Duration(days: 19, hours: 21)),
          lines: List.filled(6, true),
        ),
        HistoryRecord(
          hexNo: 2, name: '坤', question: '午后静观', direction: '感情',
          directionColor: 'pine',
          ts: ym.add(const Duration(days: 19, hours: 15, minutes: 30)),
          lines: List.filled(6, false),
        ),
        HistoryRecord(
          question: '生辰盘推演', direction: '事业', directionColor: 'gold',
          type: 'bazi', ts: ym.add(const Duration(days: 19, hours: 10)),
        ),
        // 另一天 (8 号) 单条 → 徽章, 组尾无轨
        HistoryRecord(
          question: '出门问吉', direction: '感情', directionColor: 'pine',
          type: 'xlr', ts: ym.add(const Duration(days: 7, hours: 8)),
        ),
      ]),
    );
    await tester.pumpWidget(MaterialApp(
      home: HistoryScreen(
        vm: HistoryViewModel(repo: repo, favs: FavoritesRepository(
          store: MemoryFavoritesStore(),
        )),
      ),
    ));
    await tester.pumpAndSettle();

    // 20 号徽章一个 (三条同日只出一次)
    expect(find.byKey(const ValueKey('tl_day_20')), findsOneWidget);
    // 圆点两个 (组内除首条外各一)
    expect(find.byKey(ValueKey('tl_dot_${ym.add(const Duration(days: 19, hours: 15, minutes: 30)).millisecondsSinceEpoch}_午后静观')), findsOneWidget);
    expect(find.byKey(ValueKey('tl_dot_${ym.add(const Duration(days: 19, hours: 10)).millisecondsSinceEpoch}_生辰盘推演')), findsOneWidget);
    // 8 号徽章
    expect(find.byKey(const ValueKey('tl_day_8')), findsOneWidget);
    // 轨道: 近期组 3 条 → 2 段; 同月早些组 1 条 → 0 段
    expect(find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key as ValueKey<String>).value.startsWith('tl_rail_')), findsNWidgets(2));
    // stagger key 保留
    expect(find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key as ValueKey<String>).value.startsWith('hist_')), findsNWidgets(4));
    // 记录卡内容仍渲染
    expect(find.text('问：晚课复盘'), findsOneWidget);
    expect(find.text('问：出门问吉'), findsOneWidget);
  });

  testWidgets('长按进入多选仍可用 (时间轴行内)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final ym = DateTime(now.year, now.month);
    final repo = HistoryRepository(
      seedSamples: false,
      store: MemoryHistoryStore([
        HistoryRecord(
          hexNo: 1, name: '乾', question: '今冬蓄势', direction: '事业',
          directionColor: 'cinnabar',
          ts: ym.add(const Duration(days: 4, hours: 9)),
          lines: List.filled(6, true),
        ),
      ]),
    );
    await tester.pumpWidget(MaterialApp(
      home: HistoryScreen(
        vm: HistoryViewModel(repo: repo, favs: FavoritesRepository(
          store: MemoryFavoritesStore(),
        )),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('问：今冬蓄势'));
    await tester.pumpAndSettle();
    expect(find.text('已选 1 条'), findsOneWidget);
  });
}
