import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/data/favorites_store.dart';
import 'package:yijing_transform/data/history_repository.dart';
import 'package:yijing_transform/data/history_store.dart';
import 'package:yijing_transform/model/history.dart';
import 'package:yijing_transform/viewmodel/history_viewmodel.dart';

/// 屏6 测试 — 注入内存仓库 + 固定日期 (确定性, 不依赖单例/相对日期)
void main() {
  late HistoryRepository repo;
  late HistoryViewModel vm;

  setUp(() {
    final now = DateTime.now();
    final ym = DateTime(now.year, now.month);
    final prev = DateTime(now.year, now.month - 1);
    List<bool> yangs(List<int> ones) {
      final l = List<bool>.filled(6, false);
      for (final i in ones) {
        if (i >= 0 && i < 6) l[i] = true;
      }
      return l;
    }

    repo = HistoryRepository(
      seedSamples: false, // 确定性: 不叠加内置示例
      store: MemoryHistoryStore([
        // 当月: 3 方向 × 3 占法 × 3 卦
        HistoryRecord(
          hexNo: 1, name: '乾', question: '近期事业运筹方向', direction: '事业',
          directionColor: 'cinnabar', ts: ym.add(const Duration(days: 5, hours: 9)),
          lines: yangs([0, 1, 2, 3, 4, 5]), moving: [2],
        ),
        HistoryRecord(
          hexNo: 31, name: '咸', question: '与TA关系走向', direction: '感情',
          directionColor: 'pine', ts: ym.add(const Duration(days: 4, hours: 19)),
          lines: yangs([0]),
        ),
        HistoryRecord(
          hexNo: 14, name: '大有', question: '近期财运转机', direction: '财运',
          directionColor: 'gold', ts: ym.add(const Duration(days: 3, hours: 14)),
          lines: yangs([0, 1, 2, 3, 4, 5]), moving: [3],
        ),
        HistoryRecord(
          question: '个人运势总览', direction: '事业', directionColor: 'gold',
          type: 'bazi', ts: ym.add(const Duration(days: 2, hours: 20)),
        ),
        HistoryRecord(
          question: '今日出门吉凶', direction: '感情', directionColor: 'pine',
          type: 'xlr', ts: ym.add(const Duration(days: 1, hours: 8)),
        ),
        // 上月
        HistoryRecord(
          hexNo: 53, name: '渐', question: '换工作机会评估', direction: '事业',
          directionColor: 'cinnabar', ts: prev.add(const Duration(days: 12, hours: 15)),
          lines: yangs([1, 2, 3, 5]),
        ),
        HistoryRecord(
          hexNo: 60, name: '节', question: '节制开支计划', direction: '财运',
          directionColor: 'gold', ts: prev.add(const Duration(days: 3, hours: 10)),
          lines: yangs([0, 1, 4]),
        ),
      ]),
    );
    vm = HistoryViewModel(repo: repo, favs: FavoritesRepository(
      store: MemoryFavoritesStore([5, 14, 31]),
    ));
  });

  group('HistoryViewModel — 屏6 筛选/搜索/排序', () {
    test('月份默认当前月 + 记录存在', () {
      final now = DateTime.now();
      expect(vm.state.year, now.year);
      expect(vm.state.month, now.month);
      expect(vm.monthAll.length, 5);
    });

    test('卦象/方向/占法 chips 生成', () {
      expect(vm.hexChips.length, 3); // 乾 / 咸 / 大有
      expect(vm.dirChips.length, 3); // 事业/感情/财运
      expect(vm.typeChips.length, 3); // 易经/八字/小六壬
    });

    test('方向筛选', () {
      vm.setDirFilter('事业');
      expect(vm.filtered, isNotEmpty);
      expect(vm.filtered.every((r) => r.direction == '事业'), isTrue);
      expect(vm.hasFilter, isTrue);
    });

    test('占法筛选 (非卦类)', () {
      vm.setTypeFilter('bazi');
      expect(vm.filtered.length, 1);
      expect(vm.filtered.single.type, 'bazi');
      expect(vm.filtered.single.hexNo, isNull);
    });

    test('关键词搜索', () {
      vm.setKeyword('财运');
      expect(vm.filtered.every((r) => r.question.contains('财运') || r.direction.contains('财运')), isTrue);
      vm.setKeyword('不存在的词xyz');
      expect(vm.filtered, isEmpty);
    });

    test('卦象筛选', () {
      final no = vm.hexChips.first.no;
      vm.setHexFilter(no);
      expect(vm.filtered.every((r) => r.hexNo == no), isTrue);
    });

    test('月份导航 (prev/next 边界)', () {
      expect(vm.canPrev, isTrue); // 上月有记录
      final m0 = vm.state.month;
      vm.prevMonth();
      expect(vm.state.month, m0 == 1 ? 12 : m0 - 1);
      expect(vm.monthAll.length, 2); // 上月 2 条
      expect(vm.canNext, isTrue);
      vm.nextMonth();
      expect(vm.state.month, m0);
      // 已到最新月, canNext 为假
      expect(vm.canNext, isFalse);
    });

    test('排序切换反转', () {
      final before = vm.filtered;
      final firstBefore = before.first;
      vm.toggleSort();
      final after = vm.filtered;
      expect(after.first.ts.isBefore(firstBefore.ts), isTrue); // 最早在前
      expect(after.last.ts.isAfter(firstBefore.ts), isFalse);
      vm.toggleSort();
      expect(vm.filtered.first.ts.isAfter(firstBefore.ts), isFalse);
      expect(identical(vm.filtered.first, firstBefore), isTrue); // 恢复最新在前
    });

    test('清空筛选恢复', () {
      vm.setDirFilter('感情');
      vm.setHexFilter(vm.hexChips.first.no);
      vm.clearFilters();
      expect(vm.hasFilter, isFalse);
    });

    test('统计 (真实收藏数)', () {
      expect(vm.totalCount, 7);
      expect(vm.weekCount, greaterThanOrEqualTo(0));
      expect(vm.favCount, 3); // 来自 FavoritesRepository
      expect(vm.monthCount, 5);
    });

    test('removeRecords: 删除选中记录后总数减少', () {
      final before = vm.totalCount;
      final toDelete = vm.filtered.take(2).toList();
      expect(toDelete.length, 2);
      vm.removeRecords(toDelete);
      expect(vm.totalCount, before - 2);
      expect(vm.monthCount, 3); // 当月原5条删2条
    });

    test('removeRecords: 空列表不报错', () {
      vm.removeRecords([]);
      expect(vm.totalCount, 7);
    });
  });
}
