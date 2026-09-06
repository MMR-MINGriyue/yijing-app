import 'package:flutter/material.dart';

import '../theme/yijing_theme.dart';
import '../viewmodel/me_viewmodel.dart';
import 'widgets/hex_glyph.dart';

/// 屏 7 我的 — 统计概览 + 收藏卦 + 方向/占法分布 + 快捷入口
class MeScreen extends StatefulWidget {
  final MeViewModel vm;
  final void Function(int hexNo) onOpenDetail;
  final VoidCallback onGoHistory;
  final VoidCallback onGoGrid;
  final VoidCallback onOpenSettings;

  const MeScreen({
    super.key,
    required this.vm,
    required this.onOpenDetail,
    required this.onGoHistory,
    required this.onGoGrid,
    required this.onOpenSettings,
  });

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_onVm);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVm);
    super.dispose();
  }

  void _onVm() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YiColors.ink,
      appBar: AppBar(
        backgroundColor: YiColors.ink,
        foregroundColor: YiColors.gold,
        centerTitle: true,
        title: const Text('我 的', style: TextStyle(letterSpacing: 6, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: widget.onOpenSettings,
            tooltip: '设置与数据管理',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _stats(),
          const SizedBox(height: 16),
          _favorites(),
          const SizedBox(height: 16),
          _distribution('问 卦 方 向', widget.vm.directionDist.map((d) =>
              (label: d.dir, count: d.count, color: _dirColor(d.color))).toList()),
          const SizedBox(height: 16),
          _distribution('起 卦 方 式', widget.vm.methodDist.map((m) =>
              (label: m.method, count: m.count, color: YiColors.gold)).toList()),
          const SizedBox(height: 16),
          _entries(),
        ],
      ),
    );
  }

  // ---------- 统计概览 ----------
  Widget _stats() {
    final since = widget.vm.since;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('占 卜 概 览',
            style: TextStyle(fontSize: 11, letterSpacing: 3, color: YiColors.textTertiary)),
        const SizedBox(height: 12),
        Row(children: [
          _stat('总占卜', widget.vm.totalCount, YiColors.textPrimary),
          _stat('连续天数', widget.vm.streak, YiColors.cinnabar),
          _stat('收藏', widget.vm.favCount, YiColors.gold),
        ]),
        if (since != null) ...[
          const SizedBox(height: 10),
          Text('始于 ${since.month}月${since.day}日 · 心诚则灵',
              style: const TextStyle(fontSize: 10, color: YiColors.textMuted)),
        ],
      ]),
    );
  }

  Widget _stat(String label, int n, Color color) {
    return Expanded(child: Column(children: [
      Text('$n', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: color)),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(fontSize: 10, letterSpacing: 2, color: YiColors.textTertiary)),
    ]));
  }

  // ---------- 收藏卦横滑 ----------
  Widget _favorites() {
    final favs = widget.vm.favorites;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('收 藏 卦',
          style: TextStyle(fontSize: 11, letterSpacing: 3, color: YiColors.textTertiary)),
      const SizedBox(height: 10),
      if (favs.isEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _card(),
          child: const Text('屏 4 卦辞解析中点 ☆ 收藏心仪之卦',
              style: TextStyle(fontSize: 11, color: YiColors.textMuted)),
        )
      else
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: favs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final h = favs[i];
              return InkWell(
                onTap: () => widget.onOpenDetail(h.no),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 92,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: _card(),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    HexGlyph(lines: h.yangs, width: 28, lineH: 3, gap: 2.6),
                    const SizedBox(height: 8),
                    Text(h.name, style: const TextStyle(
                        fontSize: 14, letterSpacing: 2, color: YiColors.textPrimary)),
                    Text('第${h.no}卦', style: const TextStyle(fontSize: 9, color: YiColors.textMuted)),
                  ]),
                ),
              );
            },
          ),
        ),
    ]);
  }

  // ---------- 分布条形图 ----------
  Widget _distribution(String title, List<({String label, int count, Color color})> items) {
    final maxCount = items.fold<int>(1, (m, e) => e.count > m ? e.count : m);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 11, letterSpacing: 3, color: YiColors.textTertiary)),
      const SizedBox(height: 10),
      if (items.isEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _card(),
          child: const Text('暂无数据', style: TextStyle(fontSize: 11, color: YiColors.textMuted)),
        )
      else
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _card(),
          child: Column(children: [
            for (final e in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  SizedBox(width: 44,
                      child: Text(e.label, style: const TextStyle(fontSize: 12, color: YiColors.textSecondary))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: e.count / maxCount,
                        child: Container(height: 10, color: e.color.withValues(alpha: 0.75)),
                      ),
                    ),
                  ),
                  SizedBox(width: 30,
                      child: Text('${e.count}', textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 12, color: e.color))),
                ]),
              ),
          ]),
        ),
    ]);
  }

  // ---------- 快捷入口 ----------
  Widget _entries() {
    return Row(children: [
      Expanded(child: OutlinedButton.icon(
        onPressed: widget.onGoHistory,
        style: OutlinedButton.styleFrom(
          foregroundColor: YiColors.gold,
          side: const BorderSide(color: YiColors.goldDark),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.history, size: 18),
        label: const Text('历史记录', style: TextStyle(fontSize: 13)),
      )),
      const SizedBox(width: 10),
      Expanded(child: OutlinedButton.icon(
        onPressed: widget.onGoGrid,
        style: OutlinedButton.styleFrom(
          foregroundColor: YiColors.gold,
          side: const BorderSide(color: YiColors.goldDark),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.grid_view_outlined, size: 18),
        label: const Text('六十四卦', style: TextStyle(fontSize: 13)),
      )),
    ]);
  }

  Color _dirColor(String c) => switch (c) {
        'pine' => YiColors.pine,
        'cinnabar' => YiColors.cinnabar,
        _ => YiColors.gold,
      };

  Decoration _card() => yiCardDecoration();
}
