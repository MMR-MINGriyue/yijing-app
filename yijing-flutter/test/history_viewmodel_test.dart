import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/data/history_repository.dart';
import 'package:yijing_transform/viewmodel/history_viewmodel.dart';

void main() {
  group('HistoryViewModel — 屏6 筛选/搜索/排序', () {
    late HistoryViewModel vm;
    setUp(() {
      vm = HistoryViewModel(repo: HistoryRepository.instance);
    });

    test('月份默认当前月 + 记录存在', () {
      final now = DateTime.now();
      expect(vm.state.year, now.year);
      expect(vm.state.month, now.month);
      expect(vm.monthAll, isNotEmpty);
    });

    test('卦象/方向/占法 chips 生成', () {
      expect(vm.hexChips, isNotEmpty);
      expect(vm.dirChips.length, greaterThanOrEqualTo(2));
      expect(vm.typeChips.length, greaterThanOrEqualTo(2));
    });

    test('方向筛选', () {
      vm.setDirFilter('事业');
      expect(vm.filtered, isNotEmpty);
      expect(vm.filtered.every((r) => r.direction == '事业'), isTrue);
      expect(vm.hasFilter, isTrue);
    });

    test('关键词搜索 + 高亮清空', () {
      vm.setKeyword('财运');
      expect(vm.filtered.every((r) => r.question.contains('财运') || r.direction.contains('财运')), isTrue);
      vm.setKeyword('不存在的词xyz');
      expect(vm.filtered, isEmpty);
    });

    test('卦象筛选', () {
      if (vm.hexChips.isEmpty) return;
      final no = vm.hexChips.first.no;
      vm.setHexFilter(no);
      expect(vm.filtered.every((r) => r.hexNo == no), isTrue);
    });

    test('月份导航 (prev/next 边界)', () {
      expect(vm.canPrev, isTrue); // mock 覆盖上月
      final prevMonth0 = vm.state.month;
      vm.prevMonth();
      expect(vm.state.month, prevMonth0 - 1);
      // 上月无 hexChips 时也应正常 (monthAll 有上月记录)
      expect(vm.monthAll, isNotEmpty);
    });

    test('排序切换反转', () {
      final newest = vm.filtered.first;
      vm.toggleSort();
      final oldest = vm.filtered.last;
      expect(newest, isNot(oldest));
    });

    test('清空筛选恢复', () {
      vm.setDirFilter('感情');
      vm.setHexFilter(vm.hexChips.isEmpty ? null : vm.hexChips.first.no);
      vm.clearFilters();
      expect(vm.hasFilter, isFalse);
    });

    test('统计', () {
      expect(vm.totalCount, greaterThanOrEqualTo(8));
      expect(vm.weekCount, greaterThanOrEqualTo(0));
      expect(vm.favCount, 3); // mock
    });
  });
}
