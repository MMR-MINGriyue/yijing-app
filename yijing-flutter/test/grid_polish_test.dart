import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/data/favorites_store.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/view/hexgrid_screen.dart';
import 'package:yijing_transform/view/widgets/pressable.dart';
import 'package:yijing_transform/viewmodel/hexgrid_viewmodel.dart';

void main() {
  setUpAll(() => HexRepository.instance.init());

  Widget grid({FavoritesRepository? favs}) => HexGridScreen(
        vm: HexGridViewModel(),
        onOpenDetail: (_) {},
        favorites: favs,
      );

  testWidgets('卦库网格: 逐格浮现 / 按压 / 宫位印', (tester) async {
    await tester.pumpWidget(MaterialApp(home: grid()));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('共 64 卦'), findsOneWidget);
    expect(find.byType(PressableScale), findsWidgets);
    expect(find.byType(TweenAnimationBuilder<double>), findsWidgets);
    expect(find.byKey(const Key('grid_palace_1')), findsOneWidget);
  });

  testWidgets('收藏卦显示朱砂点, 未收藏不显示', (tester) async {
    final favs = FavoritesRepository(store: MemoryFavoritesStore());
    favs.mergeUnion([1]);
    await tester.pumpWidget(MaterialApp(home: grid(favs: favs)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('grid_fav_1')), findsOneWidget);
    expect(find.byKey(const Key('grid_fav_2')), findsNothing);
  });

  testWidgets('搜索无结果: 空态提示 + 共 0 卦', (tester) async {
    await tester.pumpWidget(MaterialApp(home: grid()));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('共 0 卦'), findsOneWidget);
    expect(find.text('未找到相关卦象'), findsOneWidget);
    expect(find.text('换个卦名 / 拼音 / 卦序试试'), findsOneWidget);
  });

  testWidgets('系统减少动画: 逐格浮现时长压零', (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: grid(),
    ));
    await tester.pump();
    final fade = tester.widget<TweenAnimationBuilder<double>>(
        find.byType(TweenAnimationBuilder<double>).first);
    expect(fade.duration, Duration.zero);
  });
}
