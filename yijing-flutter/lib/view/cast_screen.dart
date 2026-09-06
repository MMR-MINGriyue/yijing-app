import 'dart:async';

import 'package:flutter/material.dart';

import '../core/xiaoliuren.dart';
import '../model/hex.dart';
import '../theme/yijing_theme.dart';
import '../viewmodel/cast_viewmodel.dart';
import 'widgets/hex_glyph.dart';

/// 屏 2 赐卦 — 三种起卦方式 + 推演动画 + 结果 + 更多占法子页 (小六壬/梅花)
class CastScreen extends StatefulWidget {
  final CastViewModel vm;
  final void Function(Hex hex, {String? question}) onOpenDetail;

  const CastScreen({super.key, required this.vm, required this.onOpenDetail});

  @override
  State<CastScreen> createState() => _CastScreenState();
}

class _CastScreenState extends State<CastScreen> {
  Timer? _timer;
  final _qController = TextEditingController();
  final _mh1Controller = TextEditingController();
  final _mh2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_onVm);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVm);
    _timer?.cancel();
    _qController.dispose();
    _mh1Controller.dispose();
    _mh2Controller.dispose();
    super.dispose();
  }

  void _onVm() {
    final phase = widget.vm.state.phase;
    // 推演动画: ~1s 后落真实卦象
    if (phase == CastPhase.casting && _timer == null) {
      _timer = Timer(const Duration(milliseconds: 1100), () {
        _timer = null;
        widget.vm.finishCast();
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.vm.state;
    return Scaffold(
      backgroundColor: YiColors.ink,
      appBar: AppBar(
        backgroundColor: YiColors.ink,
        foregroundColor: YiColors.gold,
        centerTitle: true,
        title: Text(s.morePage ? '更 多 占 法' : '起 卦',
            style: const TextStyle(letterSpacing: 6, fontSize: 17)),
        leading: s.morePage
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.vm.backToMain,
              )
            : null,
      ),
      body: s.morePage ? _morePage(s) : _mainPage(s),
    );
  }

  // ================= 主页: 问题 + 方向 + 三式 =================
  Widget _mainPage(CastState s) {
    return switch (s.phase) {
      CastPhase.form => _form(s),
      CastPhase.casting => _casting(),
      CastPhase.done => _done(s),
    };
  }

  Widget _form(CastState s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _questionInput(s),
        const SizedBox(height: 14),
        _directionChips(s),
        const SizedBox(height: 16),
        for (final m in CastMethod.values) ...[
          _methodCard(m, s),
          const SizedBox(height: 10),
        ],
        _moreEntry(),
      ],
    );
  }

  Widget _questionInput(CastState s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: _card(),
      child: TextField(
        controller: _qController,
        style: const TextStyle(color: YiColors.textPrimary, fontSize: 14),
        maxLength: 60,
        onChanged: widget.vm.setQuestion,
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          hintText: '写下所占之事，心诚则灵 (可留空)',
          hintStyle: TextStyle(color: YiColors.textMuted, fontSize: 13),
        ),
      ),
    );
  }

  Widget _directionChips(CastState s) {
    return Row(children: [
      for (final d in kDirections) ...[
        Expanded(
          child: InkWell(
            onTap: () => widget.vm.setDirection(d.dir),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: s.direction == d.dir
                    ? _dirColor(d.color).withValues(alpha: 0.18)
                    : YiColors.inkCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: s.direction == d.dir ? _dirColor(d.color) : YiColors.strokeSoft,
                ),
              ),
              child: Text(d.dir, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, letterSpacing: 2,
                      color: s.direction == d.dir ? _dirColor(d.color) : YiColors.textTertiary)),
            ),
          ),
        ),
        if (d != kDirections.last) const SizedBox(width: 8),
      ],
    ]);
  }

  Widget _methodCard(CastMethod m, CastState s) {
    final active = s.method == m;
    return InkWell(
      onTap: () => widget.vm.setMethod(m),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: YiColors.inkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? YiColors.cinnabar : YiColors.strokeSoft),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x22C9A876),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_methodGlyph(m),
                style: const TextStyle(fontSize: 18, color: YiColors.gold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.label, style: const TextStyle(
                fontSize: 14, letterSpacing: 2, color: YiColors.textPrimary)),
            const SizedBox(height: 3),
            Text(m.sub, style: const TextStyle(fontSize: 11, color: YiColors.textTertiary)),
          ])),
          Icon(active ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20, color: active ? YiColors.cinnabar : YiColors.textMuted),
        ]),
      ),
    );
  }

  String _methodGlyph(CastMethod m) => switch (m) {
        CastMethod.numeric => '数',
        CastMethod.yarrow => '蓍',
        CastMethod.coin => '钱',
      };

  Widget _moreEntry() {
    return InkWell(
      onTap: widget.vm.openMorePage,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0x33D04D3E), Color(0x22C9A876)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: YiColors.stroke),
        ),
        child: const Row(children: [
          Expanded(
            child: Text('更多占法 ›  八字 · 小六壬 · 梅花易数',
                style: TextStyle(fontSize: 13, letterSpacing: 1, color: YiColors.textPrimary)),
          ),
          Icon(Icons.chevron_right, size: 18, color: YiColors.gold),
        ]),
      ),
    );
  }

  // ---------- 推演动画 ----------
  Widget _casting() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(
          width: 44, height: 44,
          child: CircularProgressIndicator(color: YiColors.cinnabar, strokeWidth: 2.5),
        ),
        const SizedBox(height: 22),
        const Text('卦 象 推 演 中', style: TextStyle(
            fontSize: 14, letterSpacing: 4, color: YiColors.gold)),
        const SizedBox(height: 8),
        const Text('乾坤位定，爻象将成', style: TextStyle(fontSize: 11, color: YiColors.textTertiary)),
      ]),
    );
  }

  // ---------- 结果 ----------
  Widget _done(CastState s) {
    final hex = s.hex;
    if (hex == null) return _form(s);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _card(),
          child: Column(children: [
            const Text('卦 象 已 成',
                style: TextStyle(fontSize: 12, letterSpacing: 4, color: YiColors.gold)),
            const SizedBox(height: 16),
            HexGlyph(lines: hex.yangs, moving: s.result?.moving ?? [], width: 60, lineH: 7, gap: 5),
            const SizedBox(height: 16),
            Text('${hex.name} 卦',
                style: const TextStyle(fontSize: 30, letterSpacing: 6, color: YiColors.textPrimary)),
            const SizedBox(height: 6),
            Text('第 ${hex.no} 卦 · ${hex.desc}',
                style: const TextStyle(fontSize: 12, color: YiColors.cinnabar)),
            if ((s.result?.moving ?? []).isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('动爻: ${s.result!.moving.map((i) => hex.yaoName(i)).join('、')}',
                  style: const TextStyle(fontSize: 12, color: YiColors.gold)),
            ],
            const SizedBox(height: 12),
            Text('「${hex.guaci}」', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.6, color: YiColors.textSecondary)),
          ]),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => widget.onOpenDetail(hex, question: s.question),
          style: FilledButton.styleFrom(
            backgroundColor: YiColors.cinnabar,
            foregroundColor: const Color(0xFFFFF6EC),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('查看卦辞解析', style: TextStyle(letterSpacing: 4, fontSize: 14)),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () {
            _qController.clear();
            widget.vm.reset();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: YiColors.gold,
            side: const BorderSide(color: YiColors.goldDark),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('再占一卦', style: TextStyle(letterSpacing: 4, fontSize: 14)),
        ),
      ],
    );
  }

  // ================= 更多占法子页 =================
  Widget _morePage(CastState s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _directionChips(s),
        const SizedBox(height: 14),
        _xlrCard(s),
        const SizedBox(height: 12),
        _meihuaCard(s),
        const SizedBox(height: 12),
        _baziLocked(),
        const SizedBox(height: 12),
        if (s.xlr != null) ...[
          _xlrResult(s.xlr!),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _xlrCard(CastState s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('小六壬', style: TextStyle(fontSize: 14, letterSpacing: 2, color: YiColors.textPrimary)),
          SizedBox(width: 8),
          Text('月 · 日 · 时 三数落宫',
              style: TextStyle(fontSize: 10, color: YiColors.textTertiary)),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.vm.castXlr,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0x225BA88A),
              foregroundColor: YiColors.pine,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('即时起课', style: TextStyle(letterSpacing: 4, fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  Widget _xlrResult(XiaoLiuRenResult x) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1A5BA88A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x555BA88A)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(x.summary, style: const TextStyle(fontSize: 12, color: YiColors.pine)),
        const SizedBox(height: 8),
        Text('${x.result.name} · ${x.result.luck} · 宜${x.result.dir}',
            style: const TextStyle(fontSize: 16, letterSpacing: 2, color: YiColors.textPrimary)),
        const SizedBox(height: 6),
        Text(x.result.text,
            style: const TextStyle(fontSize: 11, height: 1.7, color: YiColors.textSecondary)),
      ]),
    );
  }

  Widget _meihuaCard(CastState s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('梅花易数 · 数字式', style: TextStyle(fontSize: 14, letterSpacing: 2, color: YiColors.textPrimary)),
          SizedBox(width: 8),
          Text('两数起卦', style: TextStyle(fontSize: 10, color: YiColors.textTertiary)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(
            controller: _mh1Controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: YiColors.textPrimary, fontSize: 14),
            decoration: _numInput('数一'),
          )),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('·', style: TextStyle(color: YiColors.gold, fontSize: 18))),
          Expanded(child: TextField(
            controller: _mh2Controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: YiColors.textPrimary, fontSize: 14),
            decoration: _numInput('数二'),
          )),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              final n1 = int.tryParse(_mh1Controller.text) ?? 0;
              final n2 = int.tryParse(_mh2Controller.text) ?? 0;
              if (n1 <= 0 || n2 <= 0) return;
              widget.vm.castMeihua(n1, n2);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0x22C9A876),
              foregroundColor: YiColors.gold,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('以数起卦', style: TextStyle(letterSpacing: 4, fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  InputDecoration _numInput(String hint) => InputDecoration(
        filled: true,
        fillColor: const Color(0xFF161209),
        counterText: '',
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: YiColors.strokeSoft),
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: YiColors.textMuted, fontSize: 12),
      );

  Widget _baziLocked() {
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
  }

  Color _dirColor(String c) => switch (c) {
        'pine' => YiColors.pine,
        'cinnabar' => YiColors.cinnabar,
        _ => YiColors.gold,
      };

  BoxDecoration _card() => BoxDecoration(
        color: YiColors.inkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: YiColors.strokeSoft),
      );
}
