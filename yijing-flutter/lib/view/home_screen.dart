import 'package:flutter/material.dart';

import '../model/hex.dart';
import '../model/history.dart';
import '../theme/yijing_theme.dart';
import '../viewmodel/home_viewmodel.dart';
import 'widgets/hex_glyph.dart';
import 'widgets/pressable.dart';
import 'widgets/stagger_in.dart';

/// 屏 1 今日一卦 — 时辰卦 + 干支问候 + 快捷入口 + 最近占卜
class HomeScreen extends StatefulWidget {
  final HomeViewModel vm;
  final void Function(int hexNo, {String? question}) onOpenDetail;
  final VoidCallback onGoCast;
  final VoidCallback onGoGrid;
  final VoidCallback onGoHistory;
  final VoidCallback onOpenSettings;

  const HomeScreen({
    super.key,
    required this.vm,
    required this.onOpenDetail,
    required this.onGoCast,
    required this.onGoGrid,
    required this.onGoHistory,
    required this.onOpenSettings,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    final h = widget.vm.todayHex;
    return Scaffold(
      backgroundColor: YiColors.ink,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            StaggerIn(delay: YiMotion.homeStagger[0], child: _greeting()),
            const SizedBox(height: 14),
            StaggerIn(delay: YiMotion.homeStagger[1], child: _hero(h)),
            const SizedBox(height: 14),
            StaggerIn(delay: YiMotion.homeStagger[2], child: _quickEntries()),
            const SizedBox(height: 16),
            StaggerIn(delay: YiMotion.homeStagger[3], child: _recent()),
          ],
        ),
      ),
    );
  }

  // ---------- 问候 + 干支日期 ----------
  Widget _greeting() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(widget.vm.greeting,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500,
                letterSpacing: 2, color: YiColors.textPrimary)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22, color: YiColors.textTertiary),
            onPressed: () => widget.vm.refreshHero(),
            tooltip: '换一卦',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20, color: YiColors.textTertiary),
            onPressed: widget.onOpenSettings,
            tooltip: '设置与数据管理',
          ),
        ]),
      ]),
      const SizedBox(height: 4),
      Text(widget.vm.dateLine,
          style: const TextStyle(fontSize: 12, letterSpacing: 1.5, color: YiColors.textTertiary)),
      const SizedBox(height: 8),
      Row(children: [
        Container(width: 6, height: 6,
            decoration: const BoxDecoration(color: YiColors.cinnabar, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(widget.vm.shichenTip,
            style: const TextStyle(fontSize: 12, letterSpacing: 2, color: YiColors.gold)),
      ]),
    ]);
  }

  // ---------- 今日一卦 hero ----------
  Widget _hero(Hex h) {
    return PressableScale(
      onTap: () => widget.onOpenDetail(h.no),
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [YiColors.inkCard, Color(0xFF221B14)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: YiColors.stroke),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            HexGlyph(lines: h.yangs, width: 42, lineH: 5, gap: 4),
            const SizedBox(width: 24),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.vm.isHourHex ? '今日一卦 · 依时而定' : '今日一卦 · 随机轮换',
                    style: const TextStyle(fontSize: 11, letterSpacing: 3, color: YiColors.textTertiary)),
                const SizedBox(height: 8),
                Text('${h.name} 卦',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500,
                        letterSpacing: 6, color: YiColors.textPrimary)),
                const SizedBox(height: 4),
                Text('${h.en} · 第 ${h.no} 卦',
                    style: const TextStyle(fontSize: 11, letterSpacing: 2, color: YiColors.gold)),
                const SizedBox(height: 4),
                Text(h.desc,
                    style: const TextStyle(fontSize: 12, letterSpacing: 1, color: YiColors.cinnabar)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Text('「${h.guaci}」', textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.6, color: YiColors.textPrimary)),
          const SizedBox(height: 8),
          Text(h.intro, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, height: 1.7, color: YiColors.textSecondary)),
        ]),
      ),
    );
  }


  // ---------- 快捷入口 ----------
  Widget _quickEntries() {
    return Row(children: [
      _quickItem('起卦', '占问之事', Icons.auto_awesome, widget.onGoCast),
      const SizedBox(width: 10),
      _quickItem('六十四卦', '卦象总览', Icons.grid_view_outlined, widget.onGoGrid),
      const SizedBox(width: 10),
      _quickItem('历史', '过往占卜', Icons.history, widget.onGoHistory),
    ]);
  }

  Widget _quickItem(String label, String sub, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: YiColors.inkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: YiColors.strokeSoft),
          ),
          child: Column(children: [
            Icon(icon, size: 20, color: YiColors.gold),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, letterSpacing: 1, color: YiColors.textPrimary)),
            Text(sub, style: const TextStyle(fontSize: 9, color: YiColors.textMuted)),
          ]),
        ),
      ),
    );
  }


  // ---------- 最近占卜 ----------
  Widget _recent() {
    final list = widget.vm.recent;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('最 近 占 卜',
            style: TextStyle(fontSize: 12, letterSpacing: 3, color: YiColors.textTertiary)),
        InkWell(
          onTap: widget.onGoHistory,
          child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text('查看全部 ›',
                  style: TextStyle(fontSize: 11, color: YiColors.cinnabar))),
        ),
      ]),
      const SizedBox(height: 10),
      if (list.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _card(),
          child: const Text('暂无占卜记录，心诚则灵',
              style: TextStyle(fontSize: 12, color: YiColors.textTertiary)),
        )
      else
        ...list.map(_recentCard),
    ]);
  }

  Widget _recentCard(HistoryRecord r) {
    final hex = r.hexNo != null ? widget.vm.hexByNo(r.hexNo!) : null;
    return PressableScale(
      onTap: () => widget.onOpenDetail(r.hexNo ?? 1, question: r.question),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _card(),
        child: Row(children: [
          if (hex != null)
            HexGlyph(lines: hex.yangs, width: 28, lineH: 3, gap: 2.4)
          else
            const SizedBox(width: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r.name ?? ''} · ${r.direction}',
                style: const TextStyle(fontSize: 13, color: YiColors.textPrimary)),
            const SizedBox(height: 3),
            Text(r.question, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: YiColors.textSecondary)),
          ])),
          Text(_fmtTime(r.ts),
              style: const TextStyle(fontSize: 10, color: YiColors.textMuted)),
        ]),
      ),
    );
  }


  String _fmtTime(DateTime ts) =>
      '${ts.month}/${ts.day} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}';

  Decoration _card() => yiCardDecoration();
}
