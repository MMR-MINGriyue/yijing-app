import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/viewmodel/transform_viewmodel.dart';

void main() {
  group('HexRepository.transform — 与易道 YijingEngine 一致', () {
    late HexRepository repo;
    setUpAll(() {
      repo = HexRepository.instance
        ..init();
    });

    test('64 卦数据完整加载 (kHexLibrary = 64)', () {
      expect(repo.hexByNo(1).name, '乾');
      expect(repo.hexByNo(64).name, '未济');
      expect(repo.hexByNo(1).yangs.every((y) => y), isTrue); // 乾全阳
      expect(repo.hexByNo(2).yangs.every((y) => !y), isTrue); // 坤全阴
    });

    test('乾卦九三动 → 变卦履 (与易道默认一致)', () {
      final r = repo.transform(1, [2]); // 0-based 2 = 九三
      expect(r.ben.name, '乾');
      expect(r.changed.name, '履');
      expect(r.changed.no, 10);
    });

    test('坤卦初六动 → 变卦复', () {
      final r = repo.transform(2, [0]);
      expect(r.changed.name, '复');
    });

    test('互卦: 乾卦 2-4 爻为下/3-5 为上 → 互卦 = 乾', () {
      final r = repo.transform(1, [2]);
      expect(r.hu.name, '乾');
    });

    test('体用生克: 乾(金) 用坤(土) → 用生体大吉', () {
      // 需构造"用卦 = 土": 动爻在上卦 → 上卦为用。坤卦在上 = 否卦? 否 = 地天否 no.12
      // 用卦土, 体卦乾金: 土生金 → 用生体大吉
      final r = repo.transform(12, [5]); // 否卦 上爻动 → 用 = 上卦坤(土)
      expect(r.ben.name, '否');
      expect(r.yongWuxing, '土');
      expect(r.tiWuxing, '金');
      expect(r.relation, '用生体');
      expect(r.verdict, '大吉');
    });

    test('比和: 上下卦同五行 (乾乾金) → 比和吉', () {
      final r = repo.transform(1, []);
      expect(r.relation, '比和');
      expect(r.verdict, '吉');
    });
  });

  group('TransformViewModel — MVVM 状态管理', () {
    late TransformViewModel vm;
    setUp(() {
      HexRepository.instance.init();
      vm = TransformViewModel();
    });

    test('默认状态: 乾卦九三动', () {
      expect(vm.state.benNo, 1);
      expect(vm.state.moving, [2]);
      expect(vm.state.result.changed.name, '履');
    });

    test('toggleMoving: 点击爻切换动爻并重算', () {
      vm.toggleMoving(2); // 关闭九三动 → 无动爻 → 变卦 = 乾
      expect(vm.state.moving, isEmpty);
      expect(vm.state.result.changed.name, '乾');

      vm.toggleMoving(5); // 上九动 → 变卦 = 夬?
      expect(vm.state.moving, [5]);
      expect(vm.state.result.changed.name, '夬');
    });

    test('selectHex: 换卦', () {
      vm.selectHex(2);
      expect(vm.state.benNo, 2);
      expect(vm.state.moving, isEmpty);
    });

    test('notifyListeners 触发', () {
      var notified = 0;
      vm.addListener(() => notified++);
      vm.toggleMoving(2);
      expect(notified, greaterThan(0));
    });

    test('yaoChanges 明细正确', () {
      final cs = vm.yaoChanges();
      expect(cs.length, 1);
      expect(cs.first.from, '九三');
      expect(cs.first.to, '六三');
    });
  });
}
