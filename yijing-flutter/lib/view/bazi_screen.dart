import 'package:flutter/material.dart';

import '../core/bazi.dart';
import '../core/bazi_reading.dart';
import '../core/dayun.dart';
import '../theme/ink_wash.dart';
import '../theme/yijing_theme.dart';
import '../viewmodel/bazi_viewmodel.dart';

/// 屏「八字」— 命盘输入 + 排盘 + 大运流年 + 解读 (iter47)
class BaziScreen extends StatefulWidget {
  final BaziViewModel vm;

  const BaziScreen({super.key, required this.vm});

  @override
  State<BaziScreen> createState() => _BaziScreenState();
}

class _BaziScreenState extends State<BaziScreen> {
  TimeOfDay _time = const TimeOfDay(hour: 12, minute: 0);

  Future<void> _pick() async {
    final s = widget.vm.state;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: s.birth ?? DateTime(1995, 6, 15),
      firstDate: DateTime(1901),
      lastDate: now,
      helpText: '选择出生日期',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: '选择出生时间',
    );
    if (!mounted) return;
    final t = time ?? _time;
    setState(() => _time = t);
    widget.vm.setBirth(
        DateTime(date.year, date.month, date.day, t.hour, t.minute));
  }

  String get _birthLabel {
    final b = widget.vm.state.birth;
    if (b == null) return '点击选择出生日期与时辰';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${b.year}-${two(b.month)}-${two(b.day)}  ${two(b.hour)}:${two(b.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final s = vm.state;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: YiColors.gold,
        centerTitle: true,
        title: const Text('八 字', style: TextStyle(letterSpacing: 6, fontSize: 17)),
      ),
      body: YiInkWash(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _inputCard(s, vm),
            if (s.hasResult) ...[
              const SizedBox(height: 14),
              _chartCard(s),
              const SizedBox(height: 14),
              _metaCard(s),
              const SizedBox(height: 14),
              _dayunCard(s, vm),
              const SizedBox(height: 14),
              ..._readingCards(s.readings),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- 输入 ----------
  Widget _inputCard(BaziState s, BaziViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: yiCardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('排 盘 输 入', style: TextStyle(fontSize: 13, letterSpacing: 3, color: YiColors.textPrimary)),
          SizedBox(width: 8),
          Text('公历出生时间 · 记忆上次输入',
              style: TextStyle(fontSize: 10, color: YiColors.textTertiary)),
        ]),
        const SizedBox(height: 10),
        InkWell(
          onTap: _pick,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF161209),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: YiColors.strokeSoft),
            ),
            child: Row(children: [
              const Icon(Icons.event_outlined, size: 16, color: YiColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_birthLabel,
                    style: TextStyle(fontSize: 13,
                        color: s.birth == null ? YiColors.textMuted : YiColors.textPrimary)),
              ),
              if (s.restored)
                const Text('已载入', style: TextStyle(fontSize: 10, color: YiColors.pine)),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          for (final g in const [('male', '乾造'), ('female', '坤造')]) ...[
            Expanded(
              child: InkWell(
                onTap: () => vm.setGender(g.$1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: s.gender == g.$1
                        ? YiColors.gold.withValues(alpha: 0.15)
                        : YiColors.inkCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: s.gender == g.$1 ? YiColors.goldDark : YiColors.strokeSoft),
                  ),
                  child: Text(g.$2, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, letterSpacing: 2,
                          color: s.gender == g.$1 ? YiColors.gold : YiColors.textTertiary)),
                ),
              ),
            ),
            if (g.$1 != 'female') const SizedBox(width: 8),
          ],
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: s.birth == null ? null : vm.compute,
            style: FilledButton.styleFrom(
              disabledBackgroundColor: const Color(0x22D04D3E),
              backgroundColor: const Color(0x55D04D3E),
              foregroundColor: const Color(0xFFE8A79E),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('排 盘', style: TextStyle(letterSpacing: 6, fontSize: 14)),
          ),
        ),
      ]),
    );
  }

  // ---------- 命盘 ----------
  Widget _chartCard(BaziState s) {
    final c = s.chart!;
    final ex = s.extra;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: yiCardDecoration(border: const Color(0x55D04D3E)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('命 盘', style: TextStyle(fontSize: 13, letterSpacing: 3, color: YiColors.textPrimary)),
          const Spacer(),
          Text('${s.gender == 'male' ? '乾造' : '坤造'} · 日主 ${c.dayGan}${c.dayElement} · ${c.strength}',
              style: const TextStyle(fontSize: 10, color: YiColors.textTertiary)),
        ]),
        const SizedBox(height: 12),
        // 四柱表
        Row(children: [
          for (final p in c.pillars)
            Expanded(child: Column(children: [
              Text(p.pos, style: const TextStyle(fontSize: 10, color: YiColors.textMuted)),
              const SizedBox(height: 4),
              Text(p.gz, style: const TextStyle(fontSize: 19, letterSpacing: 1,
                  color: YiColors.textPrimary)),
              const SizedBox(height: 3),
              Text(p.ganGod, style: TextStyle(fontSize: 10,
                  color: p.ganGod == '日主' ? YiColors.cinnabar : YiColors.gold)),
              const SizedBox(height: 3),
              Text(nayinOf(p.gz), style: const TextStyle(fontSize: 9, color: YiColors.textMuted)),
              const SizedBox(height: 5),
              Text(p.hidden.map((h) => h.gan).join(' '),
                  style: const TextStyle(fontSize: 10, color: YiColors.textSecondary)),
              Text(p.hidden.map((h) => h.god).join('/'),
                  style: const TextStyle(fontSize: 8, color: YiColors.textMuted)),
            ])),
        ]),
        if (ex != null) ...[
          const SizedBox(height: 8),
          // 十二长生行
          Row(children: [
            const SizedBox(width: 24, child: Text('长生',
                style: TextStyle(fontSize: 9, color: YiColors.textMuted))),
            for (final cs in ex.changSheng)
              Expanded(child: Text(cs, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: YiColors.gold))),
          ]),
        ],
        const SizedBox(height: 10),
        _wuxingBars(c.wuxing),
        const SizedBox(height: 6),
        Text(c.wuxing.entries.map((e) => '${e.key}${e.value}').join(' · '),
            style: const TextStyle(fontSize: 11, color: YiColors.textSecondary)),
        const SizedBox(height: 4),
        Text('十神统计  ${tenGodStats(c).entries.map((e) => '${e.key}${e.value}').join(' · ')}',
            style: const TextStyle(fontSize: 10, color: YiColors.textTertiary)),
        ..._shenShaChips(c),
      ]),
    );
  }

  Widget _wuxingBars(Map<String, int> wx) {
    final colors = {
      '木': YiColors.pine, '火': YiColors.cinnabar, '土': const Color(0xFFC9A876),
      '金': const Color(0xFFD8D3C8), '水': const Color(0xFF7A9CC6),
    };
    final maxV = wx.values.fold(1, (a, b) => a > b ? a : b);
    return Column(children: [
      for (final e in wx.entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            SizedBox(width: 14, child: Text(e.key,
                style: const TextStyle(fontSize: 10, color: YiColors.textSecondary))),
            const SizedBox(width: 6),
            Expanded(child: Stack(children: [
              Container(height: 6, decoration: BoxDecoration(
                  color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                widthFactor: e.value / maxV,
                child: Container(height: 6, decoration: BoxDecoration(
                    color: colors[e.key] ?? YiColors.gold, borderRadius: BorderRadius.circular(3))),
              ),
            ])),
            SizedBox(width: 18, child: Text('${e.value}', textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 10, color: YiColors.textTertiary))),
          ]),
        ),
    ]);
  }

  List<Widget> _shenShaChips(BaZiChart c) {
    final list = shenShaOf(c);
    if (list.isEmpty) return [];
    return [
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final name in list)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: YiColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: YiColors.goldDark),
            ),
            child: Text(name, style: const TextStyle(fontSize: 10, color: YiColors.gold)),
          ),
      ]),
    ];
  }

  // ---------- 命元/旬空/胎元/命宫 + 起运 ----------
  Widget _metaCard(BaziState s) {
    final ex = s.extra;
    final d = s.dayun;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: yiCardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('命 元', style: TextStyle(fontSize: 13, letterSpacing: 3, color: YiColors.textPrimary)),
        const SizedBox(height: 10),
        if (ex != null)
          Wrap(spacing: 18, runSpacing: 8, children: [
            _metaItem('旬空', ex.xunKong.isEmpty ? '—' : ex.xunKong.join(' ')),
            _metaItem('胎元', ex.taiYuan.isEmpty ? '—' : ex.taiYuan),
            _metaItem('命宫', ex.mingGong.isEmpty ? '—' : ex.mingGong),
            _metaItem('时辰', s.chart?.shichen ?? '—'),
          ]),
        if (d?.qiYunInfo != null) ...[
          const SizedBox(height: 10),
          Text(
            '${d!.forward ? '顺排' : '逆排'} · ${d.qiYunInfo!.years}岁${d.qiYunInfo!.months}个月起运'
            ' (@${d.qiYunInfo!.termName})',
            style: const TextStyle(fontSize: 11, color: YiColors.gold),
          ),
        ],
      ]),
    );
  }

  Widget _metaItem(String label, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label ', style: const TextStyle(fontSize: 10, color: YiColors.textMuted)),
      Text(value, style: const TextStyle(fontSize: 12, color: YiColors.gold)),
    ]);
  }

  // ---------- 大运 + 流年 ----------
  Widget _dayunCard(BaziState s, BaziViewModel vm) {
    final d = s.dayun;
    if (d == null || d.steps.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: yiCardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('大 运 · 流 年', style: TextStyle(fontSize: 13, letterSpacing: 3, color: YiColors.textPrimary)),
        const SizedBox(height: 10),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: d.steps.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final st = d.steps[i];
              final selected = s.selectedStep == i;
              return InkWell(
                onTap: () => vm.selectStep(selected ? null : i),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected || st.current
                        ? const Color(0x33D04D3E) : const Color(0x22C9A876),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: selected || st.current ? YiColors.cinnabar : YiColors.strokeSoft),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(st.gz, style: TextStyle(fontSize: 13,
                        color: selected || st.current ? YiColors.cinnabar : YiColors.gold)),
                    Text('${st.startAge}岁 · ${st.ganGod}',
                        style: const TextStyle(fontSize: 8, color: YiColors.textMuted)),
                  ]),
                ),
              );
            },
          ),
        ),
        if (s.selectedStep != null && s.selectedStep! < d.steps.length) ...[
          const SizedBox(height: 10),
          ..._liuNianList(d.steps[s.selectedStep!]),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('点击任一步大运展开流年',
                style: TextStyle(fontSize: 10, color: YiColors.textMuted)),
          ),
      ]),
    );
  }

  List<Widget> _liuNianList(DaYunStep step) {
    return [
      for (final y in step.liuNian)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            SizedBox(width: 34, child: Text('${y.year}',
                style: TextStyle(fontSize: 10,
                    color: y.current ? YiColors.cinnabar : YiColors.textTertiary))),
            SizedBox(width: 30, child: Text(y.gz,
                style: TextStyle(fontSize: 11,
                    color: y.current ? YiColors.cinnabar : YiColors.gold))),
            SizedBox(width: 40, child: Text(y.god,
                style: const TextStyle(fontSize: 9, color: YiColors.textMuted))),
            Expanded(child: Text(y.text, style: TextStyle(fontSize: 10,
                color: y.current ? YiColors.textPrimary : YiColors.textSecondary))),
          ]),
        ),
    ];
  }

  // ---------- 解读 ----------
  List<Widget> _readingCards(List<BaziReading> readings) {
    return [
      for (var i = 0; i < readings.length; i++) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: yiCardDecoration(border: const Color(0x334D8A6B)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(readings[i].title, style: const TextStyle(
                fontSize: 12, letterSpacing: 2, color: YiColors.pine)),
            const SizedBox(height: 6),
            Text(readings[i].body,
                style: const TextStyle(fontSize: 12, height: 1.8, color: YiColors.textSecondary)),
          ]),
        ),
        if (i < readings.length - 1) const SizedBox(height: 10),
      ],
    ];
  }
}
