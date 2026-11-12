// iter73 (v1.64.0) P1 性能迭代回归 — 证明重建热点确实被消除
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/core/bazi.dart';
import 'package:yijing_transform/data/favorites_store.dart';
import 'package:yijing_transform/data/history_repository.dart';
import 'package:yijing_transform/data/history_store.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/model/history.dart';
import 'package:yijing_transform/view/hexgrid_screen.dart';
import 'package:yijing_transform/view/history_screen.dart';
import 'package:yijing_transform/view/widgets/swipe_back.dart';
import 'package:yijing_transform/viewmodel/hexgrid_viewmodel.dart';
import 'package:yijing_transform/viewmodel/history_viewmodel.dart';
import 'package:yijing_transform/viewmodel/home_viewmodel.dart';

class _BuildCounter {
  int builds = 0;
}

class _CountedChild extends StatefulWidget {
  const _CountedChild(this.counter);

  final _BuildCounter counter;

  @override
  State<_CountedChild> createState() => _CountedChildState();
}

class _CountedChildState extends State<_CountedChild> {
  @override
  Widget build(BuildContext context) {
    widget.counter.builds++;
    return const SizedBox.expand();
  }
}

void main() {
  setUpAll(() => HexRepository.instance.init());

  group('搜索不再销毁网格', () {
    testWidgets('hexgrid: 输入关键词后 GridView key 不变, 结果数下降',
        (tester) async {
      final vm = HexGridViewModel();
      await tester.pumpWidget(MaterialApp(
        home: HexGridScreen(vm: vm, onOpenDetail: (_) {}),
      ));
      await tester.pump(const Duration(milliseconds: 400));
      final keyBefore = tester.widget<GridView>(find.byType(GridView)).key;
      final countBefore = (tester
              .widget<GridView>(find.byType(GridView))
              .childrenDelegate as SliverChildBuilderDelegate)
          .childCount;
      expect(countBefore, 64);

      await tester.enterText(find.byType(TextField), '乾');
      await tester.pump(const Duration(milliseconds: 100));
      final grid = tester.widget<GridView>(find.byType(GridView));
      expect(grid.key, keyBefore, reason: '搜索不得换掉网格子树 (否则 64 格重播动画)');
      final countAfter =
          (grid.childrenDelegate as SliverChildBuilderDelegate).childCount!;
      expect(countAfter, lessThan(64), reason: '搜索本身仍要生效');
      expect(vm.keyword, '乾');
    });
  });

  group('拖拽返回不重建整页', () {
    testWidgets('swipe_back: 多帧拖拽后页面内容 build 次数不增加',
        (tester) async {
      final counter = _BuildCounter();
      await tester.pumpWidget(MaterialApp(
        home: SwipeBackPage(child: _CountedChild(counter)),
      ));
      expect(counter.builds, 1);

      final gesture = await tester.startGesture(const Offset(5, 300));
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(30, 0));
        await tester.pump();
      }
      final slide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
      expect(slide.offset.dx, greaterThan(0), reason: '拖拽确实推动了位移');
      expect(counter.builds, 1,
          reason: '位移只重建 Stack 外壳, 页面内容零重建');

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('历史屏惰性列表', () {
    testWidgets('ListView.builder 而非全量 children', (tester) async {
      final vm = HistoryViewModel(
        repo: HistoryRepository(
            store: MemoryHistoryStore(), seedSamples: false),
        favs: FavoritesRepository(store: MemoryFavoritesStore()),
      );
      await tester.pumpWidget(MaterialApp(home: HistoryScreen(vm: vm)));
      expect(
        tester.widget<ListView>(find.byType(ListView)).childrenDelegate,
        isA<SliverChildBuilderDelegate>(),
      );
      expect(find.byType(IntrinsicHeight), findsNothing,
          reason: '时间轴改用 Stack 定高, 去掉双次布局');
    });
  });

  group('派生缓存正确性', () {
    test('外部写入 (无 notify) 也能让 VM 派生结果立刻刷新', () {
      final repo = HistoryRepository(
          store: MemoryHistoryStore(), seedSamples: false);
      final vm = HistoryViewModel(
        repo: repo,
        favs: FavoritesRepository(store: MemoryFavoritesStore()),
      );
      expect(vm.totalCount, 0);
      expect(vm.filtered, isEmpty);

      final now = DateTime.now();
      repo.add(HistoryRecord(
        hexNo: 1,
        name: '乾',
        question: '外部落库',
        direction: '事业',
        directionColor: 'cinnabar',
        ts: DateTime(now.year, now.month, 15, 10),
      ));
      // 没有调用 notifyListeners: version 失效键必须让缓存刷新
      expect(vm.totalCount, 1);
      expect(vm.filtered, hasLength(1));
      expect(vm.hexChips.single.name, '乾');
      expect(vm.monthCount, 1);
      expect(vm.dirChips.single.dir, '事业');
    });

    test('筛选变化后同一缓存键不串数据', () {
      final now = DateTime.now();
      final repo = HistoryRepository(
          store: MemoryHistoryStore(), seedSamples: false);
      repo.add(HistoryRecord(
        hexNo: 1,
        name: '乾',
        question: '甲',
        direction: '事业',
        directionColor: 'cinnabar',
        ts: DateTime(now.year, now.month, 15, 10),
      ));
      repo.add(HistoryRecord(
        hexNo: 2,
        name: '坤',
        question: '乙',
        direction: '感情',
        directionColor: 'pine',
        ts: DateTime(now.year, now.month, 16, 10),
      ));
      final vm = HistoryViewModel(
        repo: repo,
        favs: FavoritesRepository(store: MemoryFavoritesStore()),
      );
      expect(vm.filtered, hasLength(2));
      vm.setKeyword('乙');
      expect(vm.filtered, hasLength(1));
      expect(vm.filtered.single.name, '坤');
      vm.setKeyword('');
      expect(vm.filtered, hasLength(2));
    });
  });

  group('查表与黄历缓存', () {
    test('纳音查表: 常见干支非空, 未知干支空串', () {
      expect(nayinOf('甲子'), isNotEmpty);
      expect(nayinOf('乙丑'), isNotEmpty);
      expect(nayinOf('ZZZZ'), isEmpty);
    });

    test('黄历同日期同时辰复用同一对象, 跨时辰重算', () {
      var now = DateTime(2026, 11, 12, 10);
      final vm = HomeViewModel(
        hexRepo: HexRepository.instance,
        history: HistoryRepository(
            store: MemoryHistoryStore(), seedSamples: false),
        now: () => now,
      );
      final a = vm.almanac;
      expect(identical(vm.almanac, a), isTrue);
      now = DateTime(2026, 11, 12, 16); // 换时辰
      expect(identical(vm.almanac, a), isFalse);
    });
  });
}
