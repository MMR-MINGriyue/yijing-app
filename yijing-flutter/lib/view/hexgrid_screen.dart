import 'package:flutter/material.dart';

import '../theme/yijing_theme.dart';
import '../viewmodel/hexgrid_viewmodel.dart';
import 'widgets/hex_glyph.dart';

/// 屏 3 六十四卦 — 网格浏览 + 八宫筛选 + 搜索
class HexGridScreen extends StatefulWidget {
  final HexGridViewModel vm;
  final void Function(int hexNo) onOpenDetail;

  const HexGridScreen({super.key, required this.vm, required this.onOpenDetail});

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
    return Scaffold(
      backgroundColor: YiColors.ink,
      appBar: AppBar(
        backgroundColor: YiColors.ink,
        foregroundColor: YiColors.gold,
        centerTitle: true,
        title: const Text('六 十 四 卦',
            style: TextStyle(letterSpacing: 6, fontSize: 17)),
      ),
      body: Column(children: [
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
          child: GridView.builder(
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
              return InkWell(
                onTap: () => widget.onOpenDetail(h.no),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: YiColors.inkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: YiColors.strokeSoft),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    HexGlyph(lines: h.yangs, width: 26, lineH: 3, gap: 2.4),
                    const SizedBox(height: 8),
                    Text(h.name, style: const TextStyle(
                        fontSize: 15, letterSpacing: 2, color: YiColors.textPrimary)),
                    Text('第${h.no}卦${palace == null ? '' : ' · ${palace.substring(0, 1)}宫'}',
                        style: const TextStyle(fontSize: 9, color: YiColors.textMuted)),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _searchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: YiColors.inkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: YiColors.strokeSoft),
      ),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? const Color(0x33D04D3E) : YiColors.inkCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: active ? YiColors.cinnabar : YiColors.strokeSoft),
          ),
          child: Text(label, style: TextStyle(
              fontSize: 12, letterSpacing: 1,
              color: active ? YiColors.cinnabar : YiColors.textTertiary)),
        ),
      ),
    );
  }
}
