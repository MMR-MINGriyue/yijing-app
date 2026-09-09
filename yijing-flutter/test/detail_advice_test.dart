import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/data/favorites_store.dart';
import 'package:yijing_transform/data/hex_advice.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/view/detail_screen.dart';
import 'package:yijing_transform/viewmodel/detail_viewmodel.dart';

void main() {
  setUp(() {
    HexRepository.instance.init();
  });

  DetailViewModel newVm({int hexNo = 1, String direction = ''}) =>
      DetailViewModel(
        hexNo: hexNo,
        favs: FavoritesRepository(store: MemoryFavoritesStore()),
        direction: direction,
      );

  group('kHexAdvice — 方向建议数据源', () {
    test('覆盖 1..64 全部卦', () {
      expect(kHexAdvice.keys.toSet(), {for (var i = 1; i <= 64; i++) i});
    });

    test('每卦三方向齐全且文案非空', () {
      for (final entry in kHexAdvice.entries) {
        expect(entry.value.keys.toSet(), kAdviceDirections.toSet(),
            reason: '卦 ${entry.key} 方向不齐');
        for (final text in entry.value.values) {
          expect(text.trim(), isNotEmpty, reason: '卦 ${entry.key} 有空文案');
          expect(text.length, lessThan(40), reason: '卦 ${entry.key} 文案过长');
        }
      }
    });
  });

  group('DetailViewModel — 方向建议状态', () {
    test('默认选中事业', () {
      expect(newVm().adviceDir, '事业');
    });

    test('构造方向合法时预选, 非法回退事业', () {
      expect(newVm(direction: '感情').adviceDir, '感情');
      expect(newVm(direction: '健康').adviceDir, '事业');
    });

    test('setAdviceDir 切换并通知, 非法值忽略', () {
      final vm = newVm();
      var notified = 0;
      vm.addListener(() => notified++);
      vm.setAdviceDir('财运');
      expect(vm.adviceDir, '财运');
      expect(notified, 1);
      vm.setAdviceDir('财运'); // 同值不通知
      vm.setAdviceDir(' bogus '); // 非法不通知
      expect(vm.adviceDir, '财运');
      expect(notified, 1);
    });
  });

  group('DetailScreen — 方向建议三分栏', () {
    testWidgets('默认事业 + 点击财运切换文案', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final vm = newVm();
      await tester.pumpWidget(MaterialApp(home: DetailScreen(vm: vm)));

      // 乾卦事业建议默认可见
      expect(find.textContaining('主动谋局'), findsOneWidget);
      // 三分栏 chips 齐全
      expect(find.text('事业'), findsOneWidget);
      expect(find.text('感情'), findsOneWidget);
      expect(find.text('财运'), findsOneWidget);

      await tester.tap(find.text('财运'));
      await tester.pumpAndSettle();
      expect(vm.adviceDir, '财运');
      expect(find.textContaining('忌盈满而贪'), findsOneWidget);
      expect(find.textContaining('主动谋局'), findsNothing);
    });

    testWidgets('历史记录方向预选 (感情)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final vm = newVm(direction: '感情');
      await tester.pumpWidget(MaterialApp(home: DetailScreen(vm: vm)));
      expect(vm.adviceDir, '感情');
      expect(find.textContaining('以柔和相待'), findsOneWidget);
    });
  });
}
