# -*- coding: utf-8 -*-
# iter34: cast_screen 更多占法子页 — 八字排盘卡 + 梅花时间式按钮
import io

p = 'lib/view/cast_screen.dart'
s = io.open(p, encoding='utf-8').read()

# state fields for bazi form
s = s.replace("""  final _mh1Controller = TextEditingController();
  final _mh2Controller = TextEditingController();""",
"""  final _mh1Controller = TextEditingController();
  final _mh2Controller = TextEditingController();
  DateTime? _baziBirth;
  TimeOfDay _baziTime = const TimeOfDay(hour: 14, minute: 30);
  String _baziGender = 'male'; // male=乾造 female=坤造""")

# meihua card: add time-cast button before numeric inputs
s = s.replace("""        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(
            controller: _mh1Controller,""",
"""        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.vm.castMeihuaTime,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0x22C9A876),
              foregroundColor: YiColors.gold,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('今日时辰起卦', style: TextStyle(letterSpacing: 4, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 8),
        const Align(alignment: Alignment.centerLeft, child: Text('或以两数起卦',
            style: TextStyle(fontSize: 10, color: YiColors.textMuted))),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: TextField(
            controller: _mh1Controller,""")

# bazi locked card → full bazi card
s = s.replace("""  Widget _baziLocked() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: const Row(children: [
        Text('八字解析', style: TextStyle(fontSize: 14, letterSpacing: 2, color: YiColors.textTertiary)),
        SizedBox(width: 8),
        Text('四柱 · 大运 · 流年 (iter34 接入)',
            style: TextStyle(fontSize: 10, color: YiColors.textMuted)),
        Spacer(),
        Icon(Icons.lock_outline, size: 16, color: YiColors.textMuted),
      ]),
    );
  }""",
"""  // ---------- 八字排盘 (iter34: 真实农历 + 分钟级节气) ----------
  Future<void> _pickBaziBirth() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _baziBirth ?? DateTime(1995, 6, 15),
      firstDate: DateTime(1901),
      lastDate: now,
      helpText: '选择出生日期',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _baziTime,
      helpText: '选择出生时间',
    );
    if (!mounted) return;
    setState(() {
      _baziBirth = DateTime(date.year, date.month, date.day,
          time?.hour ?? _baziTime.hour, time?.minute ?? _baziTime.minute);
      if (time != null) _baziTime = time;
    });
  }

  String get _baziBirthLabel {
    final b = _baziBirth;
    if (b == null) return '点击选择出生日期时辰';
    final hh = _baziTime.hour.toString().padLeft(2, '0');
    final mm = _baziTime.minute.toString().padLeft(2, '0');
    return '${b.year}-${b.month.toString().padLeft(2, '0')}-${b.day.toString().padLeft(2, '0')} $hh:$mm';
  }

  Widget _baziCard(CastState s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('八字排盘', style: TextStyle(fontSize: 14, letterSpacing: 2, color: YiColors.textPrimary)),
          SizedBox(width: 8),
          Text('四柱 · 十神 · 大运', style: TextStyle(fontSize: 10, color: YiColors.textTertiary)),
        ]),
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickBaziBirth,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF161209),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: YiColors.strokeSoft),
            ),
            child: Text(_baziBirthLabel,
                style: TextStyle(
                    fontSize: 13,
                    color: _baziBirth == null ? YiColors.textMuted : YiColors.textPrimary)),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          for (final g in const [('male', '乾造'), ('female', '坤造')]) ...[
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _baziGender = g.$1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _baziGender == g.$1
                        ? YiColors.gold.withValues(alpha: 0.15)
                        : YiColors.inkCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _baziGender == g.$1 ? YiColors.goldDark : YiColors.strokeSoft),
                  ),
                  child: Text(g.$2, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, letterSpacing: 2,
                          color: _baziGender == g.$1 ? YiColors.gold : YiColors.textTertiary)),
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
            onPressed: _baziBirth == null
                ? null
                : () => widget.vm.computeBazi(_baziBirth!, _baziGender),
            style: FilledButton.styleFrom(
              disabledBackgroundColor: const Color(0x22D04D3E),
              backgroundColor: const Color(0x55D04D3E),
              foregroundColor: const Color(0xFFE8A79E),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('排 盘', style: TextStyle(letterSpacing: 6, fontSize: 14)),
          ),
        ),
        if (s.bazi != null) ...[
          const SizedBox(height: 12),
          _baziResult(s),
        ],
      ]),
    );
  }

  Widget _baziResult(CastState s) {
    final b = s.bazi!;
    final d = s.dayun;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1AD04D3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x55D04D3E)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 四柱: 干支 + 天干十神 + 藏干
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in b.pillars)
              Expanded(child: Column(children: [
                Text(p.pos, style: const TextStyle(fontSize: 10, color: YiColors.textMuted)),
                const SizedBox(height: 4),
                Text(p.gz, style: const TextStyle(fontSize: 17, letterSpacing: 1,
                    color: YiColors.textPrimary)),
                const SizedBox(height: 3),
                Text(p.ganGod, style: TextStyle(fontSize: 10,
                    color: p.ganGod == '日主' ? YiColors.cinnabar : YiColors.gold)),
                const SizedBox(height: 5),
                Text(p.hidden.map((h) => h.gan).join(' '),
                    style: const TextStyle(fontSize: 10, color: YiColors.textSecondary)),
                Text(p.hidden.map((h) => h.god).join('/'),
                    style: const TextStyle(fontSize: 8, color: YiColors.textMuted)),
              ])),
          ],
        ),
        const SizedBox(height: 10),
        // 五行 + 强弱
        Text(b.wuxing.entries.map((e) => '${e.key}${e.value}').join(' · '),
            style: const TextStyle(fontSize: 11, color: YiColors.textSecondary)),
        const SizedBox(height: 3),
        Text('日主 ${b.dayGan}${b.dayElement} · ${b.strength} · ${b.shichen}',
            style: const TextStyle(fontSize: 11, color: YiColors.textSecondary)),
        if (d?.qiYunInfo != null) ...[
          const SizedBox(height: 3),
          Text('${d!.forward ? '顺排' : '逆排'} · ${d.qiYunInfo!.years}岁${d.qiYunInfo!.months}个月起运 (@${d.qiYunInfo!.termName})',
              style: const TextStyle(fontSize: 11, color: YiColors.gold)),
        ],
        // 大运 chips
        if (d != null && d.steps.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: d.steps.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final st = d.steps[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: st.current ? const Color(0x33D04D3E) : const Color(0x22C9A876),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: st.current ? YiColors.cinnabar : YiColors.strokeSoft),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(st.gz, style: TextStyle(fontSize: 13,
                        color: st.current ? YiColors.cinnabar : YiColors.gold)),
                    Text('${st.startAge}岁', style: const TextStyle(fontSize: 9, color: YiColors.textMuted)),
                  ]),
                );
              },
            ),
          ),
        ],
      ]),
    );
  }""")

# more page: replace _baziLocked() call with _baziCard(s)
s = s.replace("""        _meihuaCard(s),
        const SizedBox(height: 12),
        _baziLocked(),""",
"""        _meihuaCard(s),
        const SizedBox(height: 12),
        _baziCard(s),""")

io.open(p, 'w', encoding='utf-8', newline='').write(s)
print('patched cast_screen')
