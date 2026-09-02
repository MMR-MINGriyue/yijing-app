import 'package:flutter/material.dart';

import '../model/history.dart';
import '../theme/yijing_theme.dart';
import '../viewmodel/history_viewmodel.dart';

/// 屏 6 历史记录 — View 层
class HistoryScreen extends StatefulWidget {
  final HistoryViewModel vm;
  const HistoryScreen({super.key, required this.vm});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
    final s = widget.vm.state;
    return Scaffold(
      backgroundColor: YiColors.ink,
      appBar: AppBar(
        backgroundColor: YiColors.ink,
        foregroundColor: YiColors.gold,
        centerTitle: true,
        title: const Text('历 史 记 录', style: TextStyle(letterSpacing: 6, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _stats(s),
          const SizedBox(height: 14),
          _monthNav(s),
          const SizedBox(height: 14),
          _searchBox(s),
          const SizedBox(height: 8),
          if (widget.vm.hexChips.isNotEmpty) _chips('卦象', widget.vm.hexChips
              .map((c) => _chip(label: c.name, count: c.count, active: s.hexFilter == c.no,
                  onTap: () => widget.vm.setHexFilter(s.hexFilter == c.no ? null : c.no))).toList(),
              s.hexFilter != null, () => widget.vm.setHexFilter(null)),
          if (widget.vm.dirChips.isNotEmpty) _chips('方向', widget.vm.dirChips
              .map((c) => _chip(label: c.dir, count: c.count, active: s.dirFilter == c.dir,
                  onTap: () => widget.vm.setDirFilter(s.dirFilter == c.dir ? '' : c.dir))).toList(),
              s.dirFilter.isNotEmpty, () => widget.vm.setDirFilter('')),
          if (widget.vm.typeChips.isNotEmpty) _chips('占法', widget.vm.typeChips
              .map((c) => _chip(label: c.label, count: c.count, active: s.typeFilter == c.type,
                  onTap: () => widget.vm.setTypeFilter(s.typeFilter == c.type ? '' : c.type))).toList(),
              s.typeFilter.isNotEmpty, () => widget.vm.setTypeFilter('')),
          const SizedBox(height: 6),
          ..._recordList(),
        ],
      ),
    );
  }

  // ---------- 统计卡 ----------
  Widget _stats(HistoryState s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: _card(),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _stat('起卦', widget.vm.totalCount, null),
        _stat('本周', widget.vm.weekCount, YiColors.cinnabar),
        _stat('收藏', widget.vm.favCount, YiColors.pine),
        _stat('本月', widget.vm.monthCount, YiColors.gold),
      ]),
    );
  }

  Widget _stat(String label, int n, Color? numColor) {
    return Column(children: [
      Text('$n', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500,
          color: numColor ?? YiColors.textPrimary)),
      Text(label, style: const TextStyle(fontSize: 10, color: YiColors.textTertiary)),
    ]);
  }

  // ---------- 月份导航 ----------
  Widget _monthNav(HistoryState s) {
    return Row(children: [
      IconButton(
        icon: const Icon(Icons.chevron_left, color: YiColors.gold),
        onPressed: widget.vm.canPrev ? widget.vm.prevMonth : null,
        color: widget.vm.canPrev ? YiColors.gold : YiColors.strokeSoft,
      ),
      Expanded(child: Center(child: Text('${s.year} 年 ${s.month} 月',
          style: const TextStyle(fontSize: 16, letterSpacing: 2, color: YiColors.textPrimary)))),
      IconButton(
        icon: const Icon(Icons.chevron_right, color: YiColors.gold),
        onPressed: widget.vm.canNext ? widget.vm.nextMonth : null,
        color: widget.vm.canNext ? YiColors.gold : YiColors.strokeSoft,
      ),
      const Spacer(),
      IconButton(
        icon: const Icon(Icons.swap_vert, color: YiColors.textTertiary, size: 20),
        onPressed: widget.vm.toggleSort,
        tooltip: s.newestFirst ? '最新在前' : '最早在前',
      ),
    ]);
  }

  // ---------- 搜索 ----------
  Widget _searchBox(HistoryState s) {
    return TextField(
      onChanged: widget.vm.setKeyword,
      style: const TextStyle(color: YiColors.textPrimary, fontSize: 13),
      cursorColor: YiColors.gold,
      decoration: InputDecoration(
        hintText: '搜索卦象、问题或方向',
        hintStyle: const TextStyle(color: YiColors.textTertiary, fontSize: 12),
        prefixIcon: const Icon(Icons.search, color: YiColors.textTertiary, size: 18),
        filled: true,
        fillColor: YiColors.inkCard,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: YiColors.strokeSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: YiColors.strokeSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: YiColors.gold),
        ),
      ),
    );
  }

  // ---------- 筛选 chips 行 ----------
  Widget _chips(String title, List<Widget> chips, bool active, VoidCallback clear) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: const TextStyle(fontSize: 10, color: YiColors.textTertiary, letterSpacing: 1)),
          if (active)
            InkWell(onTap: clear, child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('清除 ✕', style: const TextStyle(fontSize: 10, color: YiColors.cinnabar)),
            )),
        ]),
        const SizedBox(height: 4),
        SizedBox(height: 34, child: ListView(scrollDirection: Axis.horizontal, children: chips)),
      ]),
    );
  }

  Widget _chip({required String label, required int count, required bool active, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0x2AD04D3E) : YiColors.inkCard,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: active ? YiColors.cinnabar : YiColors.strokeSoft),
          ),
          child: Text('$label  $count', style: TextStyle(fontSize: 12,
              color: active ? YiColors.cinnabar : YiColors.textSecondary, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  // ---------- 历史记录列表 ----------
  List<Widget> _recordList() {
    final list = widget.vm.filtered;
    if (list.isEmpty) {
      return [
        const SizedBox(height: 60),
        Text(widget.vm.hasFilter ? '无 匹 配 记 录' : '本 月 尚 未 起 卦',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: YiColors.textTertiary)),
      ];
    }
    final group1 = list.where((r) => r.day >= 16).toList();
    final group2 = list.where((r) => r.day < 16).toList();
    return [
      _groupCap('近 期'),
      for (final r in group1) _recordCard(r),
      if (group2.isNotEmpty) _groupCap('同 月 早 些'),
      for (final r in group2) _recordCard(r),
    ];
  }

  Widget _groupCap(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 11, letterSpacing: 3, color: YiColors.textTertiary)),
    );
  }

  Widget _recordCard(HistoryRecord r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _card(),
      child: Row(children: [
        // 卦形缩略 (非卦类 → 占法徽标)
        SizedBox(
          width: 36,
          child: r.lines == null
              ? Text(r.direction[0], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500,
                  color: _dirColor(r.directionColor)))
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  for (var i = 5; i >= 0; i--)
                    Padding(padding: const EdgeInsets.symmetric(vertical: 1.2),
                        child: _miniLine(r.lines![i], r.moving?.contains(i) ?? false)),
                ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(r.name ?? r.methodName, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: YiColors.textPrimary)),
            const SizedBox(width: 8),
            Text(r.direction, style: TextStyle(fontSize: 10, color: _dirColor(r.directionColor))),
            if (r.type != 'iching')
              Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(border: Border.all(color: YiColors.stroke), borderRadius: BorderRadius.circular(4)),
                child: Text(r.methodName, style: const TextStyle(fontSize: 9, color: YiColors.textTertiary))),
          ]),
          const SizedBox(height: 4),
          Text('问：${r.question}', style: const TextStyle(fontSize: 11, color: YiColors.textSecondary)),
        ])),
        const SizedBox(width: 8),
        Text(_fmtTime(r), style: const TextStyle(fontSize: 10, color: YiColors.textMuted)),
      ]),
    );
  }

  Widget _miniLine(bool yang, bool moving) {
    final color = moving ? YiColors.cinnabar : YiColors.gold;
    return SizedBox(width: 30, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (yang)
        Container(width: 24, height: 2.5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)))
      else ...[
        Container(width: 10, height: 2.5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
        const SizedBox(width: 3),
        Container(width: 10, height: 2.5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
      ],
    ]));
  }

  Color _dirColor(String c) => switch (c) {
    'pine' => YiColors.pine,
    'cinnabar' => YiColors.cinnabar,
    _ => YiColors.gold,
  };

  String _fmtTime(HistoryRecord r) {
    final now = DateTime.now();
    final hh = r.ts.hour.toString().padLeft(2, '0');
    final mm = r.ts.minute.toString().padLeft(2, '0');
    final d = now.difference(DateTime(now.year, now.month, now.day)).inDays -
        r.ts.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (d == 0) return '今日 $hh:$mm';
    if (d == 1) return '昨日 $hh:$mm';
    return '${r.ts.month}/${r.ts.day} $hh:$mm';
  }

  BoxDecoration _card() {
    return BoxDecoration(
      color: YiColors.inkCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: YiColors.strokeSoft),
    );
  }
}
