import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/data/favorites_store.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/view/detail_screen.dart';
import 'package:yijing_transform/view/transform_screen.dart';
import 'package:yijing_transform/viewmodel/detail_viewmodel.dart';
import 'package:yijing_transform/viewmodel/transform_viewmodel.dart';

/// iter66 (v1.58.0): 详情入场编排 + 变卦推演体用生克联动动效
void main() {
  setUp(() {
    HexRepository.instance.init();
  });

  DetailViewModel newVm({int hexNo = 1}) => DetailViewModel(
        hexNo: hexNo,
        favs: FavoritesRepository(store: MemoryFavoritesStore()),
      );

  group('DetailScreen — 入场编排', () {
    testWidgets('卦辞 Tab: hero/tabs/文卡/建议 错峰 key 齐全', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(home: DetailScreen(vm: newVm())));
      await tester.pump(const Duration(milliseconds: 50));

      // 分段 key 存在 (hero 无显式 key, 用内容断言)
      expect(find.text('乾 卦'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dc-0-DetailTab.guaci')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('切爻辞 Tab: 六张卡重新接力入场 (key 变更触发)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final vm = newVm();
      await tester.pumpWidget(MaterialApp(home: DetailScreen(vm: vm)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('爻辞'));
      await tester.pump(const Duration(milliseconds: 30));

      // 六张卡的错峰 key 全部就位
      for (var i = 0; i < 6; i++) {
        expect(
          find.byKey(ValueKey('dc-$i-DetailTab.yaoci')),
          findsOneWidget,
          reason: '爻辞卡 $i 缺失',
        );
      }
      await tester.pumpAndSettle();
      // 爻辞卡标题可见 (乾卦: 初九..上九)
      expect(find.text('初九'), findsWidgets);
      expect(find.text('上九'), findsWidgets);
    });

    testWidgets('六爻解读展开: 新行错峰入场 (yl-2..yl-5)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(home: DetailScreen(vm: newVm())));
      await tester.pumpAndSettle();

      // 折叠态只有前两行
      expect(find.byKey(const ValueKey('yl-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('yl-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('yl-5')), findsNothing);

      await tester.scrollUntilVisible(
        find.text('展 开 全 部 六 爻'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('展 开 全 部 六 爻'));
      await tester.pump(const Duration(milliseconds: 30));

      expect(find.byKey(const ValueKey('yl-5')), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('TransformScreen — 体用生克联动动效', () {
    TransformViewModel newTvm() => TransformViewModel();

    testWidgets('三卦列错峰入场 key 存在', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(home: TransformScreen(vm: newTvm())));
      await tester.pump(const Duration(milliseconds: 40));

      // 默认: 本卦乾 (九三动) 变卦履 互卦乾
      // (卦名断言用 key — 选卦网格里也有同名文本, 不能按 text 计数)
      expect(find.byKey(const ValueKey('hn-10')), findsOneWidget); // 履 no=10
      expect(find.byKey(const ValueKey('hn-1')), findsNWidgets(2)); // 乾×2
      await tester.pumpAndSettle();
    });

    testWidgets('点动爻: 卦名/爻变明细/断语联动更新', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final vm = newTvm();
      await tester.pumpWidget(MaterialApp(home: TransformScreen(vm: vm)));
      await tester.pumpAndSettle();

      // 关闭九三 → 无动爻 → 变卦 = 乾
      vm.toggleMoving(2);
      await tester.pump(const Duration(milliseconds: 30));
      expect(vm.state.result.changed.no, 1);
      expect(find.byKey(const ValueKey('hn-1')), findsNWidgets(3)); // 本/变/互全乾
      // 无动爻明细占位
      expect(find.text('点击上方本卦任意爻，生成变卦推演'), findsOneWidget);
      await tester.pumpAndSettle();
      // 退场动画结束后旧动爻标注消失
      expect(find.byKey(const ValueKey('mv-九三')), findsNothing);

      // 上九动 → 变卦夬 (no=43)
      vm.toggleMoving(5);
      await tester.pump(const Duration(milliseconds: 30));
      expect(vm.state.result.changed.no, 43);
      expect(find.byKey(const ValueKey('hn-43')), findsOneWidget);
      // 爻变明细错峰 key (上九 → 上六)
      expect(
        find.byKey(const ValueKey('diff-5-上九-上六')),
        findsOneWidget,
      );
      // 动爻标注滑入
      expect(find.byKey(const ValueKey('mv-上九')), findsOneWidget);
      // 体用生克断语 key
      expect(find.byKey(const ValueKey('verdict-吉')), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('动爻标注: mvnote 文案随动爻切换', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final vm = newTvm();
      await tester.pumpWidget(MaterialApp(home: TransformScreen(vm: vm)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('mvnote-九三 动')), findsOneWidget);
      // toggleMoving 是增删语义: 先关九三再开初九, 保证单动爻
      vm.toggleMoving(2);
      await tester.pumpAndSettle();
      vm.toggleMoving(0);
      await tester.pump(const Duration(milliseconds: 30));
      // 切换中: 新文案已入场
      expect(find.byKey(const ValueKey('mvnote-初九 动')), findsOneWidget);
      await tester.pumpAndSettle();
      // 退场结束后旧文案消失
      expect(find.byKey(const ValueKey('mvnote-九三 动')), findsNothing);
    });
  });
}
