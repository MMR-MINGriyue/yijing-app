import 'dart:async';

import 'package:flutter/material.dart';

import '../core/cast_engine.dart' show CastResult;
import '../core/meihua.dart';
import '../core/xiaoliuren.dart';
import 'widgets/casting_anim.dart';
import 'widgets/coin_toss_anim.dart';
import 'widgets/pressable.dart';
import '../model/hex.dart';
import '../theme/ink_wash.dart';
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
  String _xlrAskKind = '谋事'; // 小六壬问事分类 (iter44)

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: YiColors.gold,
        centerTitle: true,
        title: const Text('占  卜',
            style: TextStyle(letterSpacing: 6, fontSize: 17)),
      ),
      body: YiInkWash(child: _mainPage(s)),
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
        const SizedBox(height: 18),
        // 主 CTA: 开始起卦 (iter37 修复: 表单缺起卦入口)
        PressableScale(
          child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: widget.vm.startCast,
            style: FilledButton.styleFrom(
              backgroundColor: YiColors.cinnabar,
              foregroundColor: const Color(0xFFFFF6EC),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.auto_awesome, size: 20),
            label: const Text('起  卦', style: TextStyle(letterSpacing: 8, fontSize: 16)),
          ),
          ),
        ),
        const SizedBox(height: 14),
        for (final m in CastMethod.values) ...[
          _methodCard(m, s),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        _xlrCard(s),
        const SizedBox(height: 12),
        _meihuaCard(s),
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
    return PressableScale(
      onTap: () => widget.vm.setMethod(m),
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

  // ---------- 推演动画 (iter38: 六爻逐爻点亮) ----------
  Widget _casting() {
    // 铜钱法: 三枚铜钱翻掷 + 下方爻象点亮; 其他法保持爻象点亮 (iter46)
    final isCoin = widget.vm.state.method == CastMethod.coin;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (isCoin) ...[
          const CoinTossAnim(),
          const SizedBox(height: 22),
          const CastingAnim(size: 130),
        ] else
          const CastingAnim(),
        const SizedBox(height: 14),
        Text(isCoin ? '观三枚之背字，成六爻之象' : '乾坤位定，爻象将成',
            style: const TextStyle(fontSize: 11, color: YiColors.textTertiary)),
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
            HexGlyph(lines: hex.yangs, moving: s.result?.moving ?? [],
                width: 60, lineH: 9, gap: 7, animated: true),
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
        // 梅花体用互变断法卡 (iter44: 仅梅花起卦显示)
        if (s.result?.method == 'meihua' && (s.result?.moving.isNotEmpty ?? false))
          ...[
            _meihuaTiyongCard(s.result!),
            const SizedBox(height: 16),
          ],
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
        // 问事分类 (iter44): 断语按问而异
        Row(children: [
          for (final kind in kXlrAskKinds) ...[
            Expanded(child: InkWell(
              onTap: () => setState(() => _xlrAskKind = kind),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _xlrAskKind == kind
                      ? YiColors.pine.withValues(alpha: 0.18)
                      : YiColors.inkCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _xlrAskKind == kind ? YiColors.pine : YiColors.strokeSoft),
                ),
                child: Text(kind, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10,
                        color: _xlrAskKind == kind ? YiColors.pine : YiColors.textTertiary)),
              ),
            )),
            if (kind != kXlrAskKinds.last) const SizedBox(width: 4),
          ],
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => widget.vm.castXlr(_xlrAskKind),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0x225BA88A),
              foregroundColor: YiColors.pine,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('即时起课', style: TextStyle(letterSpacing: 4, fontSize: 13)),
          ),
        ),
        if (s.xlr != null) ...[
          const SizedBox(height: 12),
          _xlrResult(s.xlr!),
        ],
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
        // 三宫路径: 月 → 日 → 时 (iter44)
        Row(children: [
          for (var i = 0; i < x.path.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x225BA88A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(x.path[i], style: const TextStyle(fontSize: 11, color: YiColors.pine)),
            ),
            if (i < x.path.length - 1)
              const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('→', style: TextStyle(fontSize: 11, color: YiColors.textMuted))),
          ],
        ]),
        const SizedBox(height: 8),
        Text('${x.result.name} · ${x.result.luck} · 宜${x.result.dir}',
            style: const TextStyle(fontSize: 16, letterSpacing: 2, color: YiColors.textPrimary)),
        const SizedBox(height: 6),
        Text(x.result.text,
            style: const TextStyle(fontSize: 11, height: 1.7, color: YiColors.textSecondary)),
        if (x.askAdvice.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0x145BA88A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('问 · ${x.askKind}', style: const TextStyle(
                  fontSize: 10, letterSpacing: 2, color: YiColors.pine)),
              const SizedBox(height: 3),
              Text(x.askAdvice, style: const TextStyle(
                  fontSize: 12, height: 1.6, color: YiColors.textPrimary)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _meihuaCard(CastState s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('梅花易数', style: TextStyle(fontSize: 14, letterSpacing: 2, color: YiColors.textPrimary)),
          SizedBox(width: 8),
          Text('时间 · 数字 · 掷骰', style: TextStyle(fontSize: 10, color: YiColors.textTertiary)),
        ]),
        const SizedBox(height: 10),
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
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.vm.castMeihuaDice,
            style: OutlinedButton.styleFrom(
              foregroundColor: YiColors.gold,
              side: const BorderSide(color: YiColors.goldDark),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.casino, size: 16),
            label: const Text('掷骰起卦', style: TextStyle(letterSpacing: 4, fontSize: 13)),
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

  // ---------- 梅花体用互变 (iter44) ----------
  Widget _meihuaTiyongCard(CastResult r) {
    final a = analyzeMeiHua(r.lines, r.moving.first);
    final verdictColor = switch (a.verdict) {
      '大吉' || '吉' => YiColors.pine,
      '凶' => YiColors.cinnabar,
      _ => YiColors.gold,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1AC9A876),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x55C9A876)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('梅 花 断 法 · 体 用 生 克', style: TextStyle(
            fontSize: 11, letterSpacing: 3, color: YiColors.gold)),
        const SizedBox(height: 10),
        Row(children: [
          _tiyongPillar('体卦', a.tiName, a.tiWuxing),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: verdictColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: verdictColor),
            ),
            child: Text('${a.relation} · ${a.verdict}',
                style: TextStyle(fontSize: 11, color: verdictColor)),
          ),
          _tiyongPillar('用卦', a.yongName, a.yongWuxing),
        ]),
        const SizedBox(height: 10),
        Text(a.verdictText, style: const TextStyle(
            fontSize: 12, height: 1.7, color: YiColors.textSecondary)),
        const SizedBox(height: 10),
        Row(children: [
          Text('互卦 ', style: const TextStyle(fontSize: 11, color: YiColors.textTertiary)),
          Text('${a.huName} (第${a.huNo}卦)', style: const TextStyle(fontSize: 11, color: YiColors.gold)),
          const SizedBox(width: 16),
          Text('变卦 ', style: const TextStyle(fontSize: 11, color: YiColors.textTertiary)),
          Text('${a.bianName} (第${a.bianNo}卦)', style: const TextStyle(fontSize: 11, color: YiColors.gold)),
        ]),
      ]),
    );
  }

  Widget _tiyongPillar(String label, String name, String wx) {
    return Expanded(child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 10, color: YiColors.textMuted)),
      const SizedBox(height: 3),
      Text(name, style: const TextStyle(fontSize: 20, letterSpacing: 2, color: YiColors.textPrimary)),
      Text(wx, style: const TextStyle(fontSize: 10, color: YiColors.gold)),
    ]));
  }

  Color _dirColor(String name) => switch (name) {
        'gold' => YiColors.gold,
        'pine' => YiColors.pine,
        'cinnabar' => YiColors.cinnabar,
        _ => YiColors.gold,
      };

  Decoration _card() => yiCardDecoration();
}
