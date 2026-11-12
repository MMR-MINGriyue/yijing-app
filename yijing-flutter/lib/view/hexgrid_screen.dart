import 'package:flutter/material.dart';

import '../data/favorites_store.dart';
import '../theme/yijing_theme.dart';
import '../theme/yi_ornament.dart';
import '../viewmodel/hexgrid_viewmodel.dart';
import 'widgets/hex_glyph.dart';
import 'widgets/swipe_back.dart';
import 'widgets/pressable.dart';

/// 屏 3 六十四卦 — 网格浏览 + 八宫筛选 + 搜索
class HexGridScreen extends StatefulWidget {
  final HexGridViewModel vm;
  final void Function(int hexNo) onOpenDetail;
  final FavoritesRepository? favorites;

  const HexGridScreen({
    super.key,
    required this.vm,
    required this.onOpenDetail,
    this.favorites,
  });

  @override
  State<HexGridScreen> createState() => _HexGridScreenState();
}

class _HexGridScreenState extends State<HexGridScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_onVm);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVm);
    _searchController.dispose();
    super.dispose();
  }

  void _onVm() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final list = widget.vm.filtered;
    final favs = (widget.favorites ?? FavoritesRepository.instance)
        .load()
        .toSet(); // 一次读取, 避免每格 _store.read() 复制列表
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: YiColors.gold,
        centerTitle: true,
        title: const Text('六 十 四 卦',
            style: TextStyle(letterSpacing: 6, fontSize: 17)),
      ),
      body: SwipeBackPage(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: _searchBox(),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chip('全部', widget.vm.palaceFilter.isEmpty, () => widget.vm.setPalace('')),
              for (final p in widget.vm.palaceChips)
                _chip(p, widget.vm.palaceFilter == p, () => widget.vm.setPalace(p)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('共 ${list.length} 卦',
                style: const TextStyle(fontSize: 11, letterSpacing: 2, color: YiColors.textTertiary)),
          ),
        ),
        Expanded(
          // iter61: 空结果即时反馈 (不走切换动画, 避免旧网格残留过渡层);
          // 网格筛选/搜索仍保留 iter39 的淡入滑入
          child: list.isEmpty
              ? const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    YiSeal(text: '无', size: 34),
                    SizedBox(height: 12),
                    Text('未找到相关卦象',
                        style: TextStyle(
                            fontSize: 13,
                            letterSpacing: 2,
                            color: YiColors.textSecondary)),
                    SizedBox(height: 6),
                    Text('换个卦名 / 拼音 / 卦序试试',
                        style: TextStyle(
                            fontSize: 11, color: YiColors.textMuted)),
                  ]),
                )
              : AnimatedSwitcher(
                  duration: YiMotion.base,
                  switchInCurve: YiMotion.easeOutExpo,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position:
                          Tween(begin: const Offset(0, 0.02), end: Offset.zero)
                              .animate(anim),
                      child: child,
                    ),
                  ),
                  // iter73: key 不含 keyword/list.length — 搜索逐字符不再销毁整个网格
                  // Element 树并重播 64 格入场动画; 宫筛选变化才需要换子树
                  child: GridView.builder(
            key: ValueKey('hexgrid_${widget.vm.palaceFilter}'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final h = list[i];
              final palace = widget.vm.palaceOfHex(h.no);
              // iter61: 逐格错峰浮现 (隐式动画, 无控制器), 按压改全站 PressableScale
              return PressableScale(
                onTap: () => widget.onOpenDetail(h.no),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('grid_item_${h.no}'),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: YiMotion.reduced(context,
                      Duration(milliseconds: 180 + (i % 8) * 22)),
                  curve: YiMotion.easeOutExpo,
                  builder: (_, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                        offset: Offset(0, (1 - v) * 10), child: child!),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: yiCardDecoration(),
                    child: Stack(children: [
                      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        HexGlyph(lines: h.yangs, width: 26, lineH: 3.6, gap: 2.8),
                        const SizedBox(height: 8),
                        Text(h.name, style: const TextStyle(
                            fontSize: 15, letterSpacing: 2, color: YiColors.textPrimary)),
                        const SizedBox(height: 3),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          if (palace != null)
                            Container(
                              key: Key('grid_palace_${h.no}'),
                              width: 14,
                              height: 14,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: YiColors.bronze.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                    color: YiColors.goldDark, width: 0.5),
                              ),
                              child: Text(palace.substring(0, 1),
                                  style: const TextStyle(
                                      fontSize: 9, color: YiColors.gold)),
                            ),
                          if (palace != null) const SizedBox(width: 4),
                          Text('第${h.no}卦',
                              style: const TextStyle(
                                  fontSize: 9, color: YiColors.textMuted)),
                        ]),
                      ]),
                      if (favs.contains(h.no))
                        Positioned(
                          top: 4,
                          right: 4,
                          child: SizedBox(
                            key: Key('grid_fav_${h.no}'),
                            width: 6,
                            height: 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                  color: YiColors.cinnabar,
                                  shape: BoxShape.circle),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              );
            },
          ),
          ),
        ),
      ])),
    );
  }

  Widget _searchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: yiCardDecoration(radius: 12),
      child: Row(children: [
        const Icon(Icons.search, size: 18, color: YiColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: YiColors.textPrimary, fontSize: 13),
            onChanged: widget.vm.setKeyword,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: '搜卦名 / 拼音 / 卦序',
              hintStyle: TextStyle(color: YiColors.textMuted, fontSize: 12),
            ),
          ),
        ),
        if (widget.vm.keyword.isNotEmpty)
          InkWell(
            onTap: () {
              _searchController.clear();
              widget.vm.setKeyword('');
            },
            child: const Icon(Icons.close, size: 16, color: YiColors.textTertiary),
          ),
      ]),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PressableScale(
        onTap: onTap,
        scale: 0.94,
        child: AnimatedContainer(
          duration: YiMotion.base,
          curve: YiMotion.easeOutExpo,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? const Color(0x33D04D3E) : YiColors.inkCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: active ? YiColors.cinnabar : YiColors.strokeSoft),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: active ? YiColors.cinnabar : YiColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
                fontSize: 12, letterSpacing: 1,
                color: active ? YiColors.cinnabar : YiColors.textTertiary)),
          ]),
        ),
      ),
    );
  }
}
