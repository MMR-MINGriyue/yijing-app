import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../model/hex.dart';
import '../theme/yijing_theme.dart';
import 'widgets/hex_glyph.dart';
import 'widgets/share_card.dart';

/// 今日一卦 · 全屏展开 (PWA hero-fullscreen 对齐)
/// 沉浸式本卦详解: 卦象 + 卦辞 + 象传 + 六爻互动(手风琴) + 分享/起卦
class HeroFullscreen extends StatefulWidget {
  final Hex hex;
  final VoidCallback? onGoCast;

  const HeroFullscreen({super.key, required this.hex, this.onGoCast});

  static Route<void> route(Hex hex, {VoidCallback? onGoCast}) =>
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => HeroFullscreen(hex: hex, onGoCast: onGoCast),
        transitionsBuilder: (_, anim, __, child) {
          final curve = Curves.easeOutCubic.transform(anim.value);
          return FadeTransition(
            opacity: anim,
            child: Transform.scale(
              scale: 0.94 + 0.06 * curve,
              child: child,
            ),
          );
        },
      );

  @override
  State<HeroFullscreen> createState() => _HeroFullscreenState();
}

class _HeroFullscreenState extends State<HeroFullscreen> {
  int? _expandedYao; // 当前展开的爻索引 (0=初 … 5=上), null=全部收起

  @override
  Widget build(BuildContext context) {
    final h = widget.hex;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A140D), Color(0xFF0D0A06)],
          ),
        ),
        child: SafeArea(
          child: Stack(children: [
            // 关闭按钮
            Positioned(
              top: 8,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, size: 24, color: YiColors.textTertiary),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: '关闭',
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 52, 24, 32),
              children: [
                _tag(),
                const SizedBox(height: 20),
                _hero(h),
                const SizedBox(height: 22),
                _quote(h),
                const SizedBox(height: 20),
                _divider('卦 辞 释 义'),
                const SizedBox(height: 12),
                _section(body: h.intro),
                const SizedBox(height: 20),
                _divider('象 传'),
                const SizedBox(height: 12),
                _daxiang(h),
                const SizedBox(height: 24),
                _divider('六 爻 互 动'),
                const SizedBox(height: 10),
                _yaoSummary(h),
                const SizedBox(height: 12),
                ..._yaoRows(h),
                const SizedBox(height: 28),
                _actions(h),
                const SizedBox(height: 16),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  // ---------- 标签 ----------
  Widget _tag() => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
            decoration: const BoxDecoration(color: YiColors.cinnabar, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        const Text('本 卦 · 详 解',
            style: TextStyle(fontSize: 11, letterSpacing: 4, color: YiColors.textTertiary)),
      ]);

  // ---------- hero: 八卦 + 卦象 + 卦名 ----------
  Widget _hero(Hex h) => Column(children: [
        Text('${h.triU} 上·${h.triUN}   ${h.triD} 下·${h.triDN}',
            style: const TextStyle(fontSize: 12, letterSpacing: 2, color: YiColors.textTertiary)),
        const SizedBox(height: 18),
        HexGlyph(lines: h.yangs, width: 120, lineH: 9, gap: 8),
        const SizedBox(height: 20),
        Text('${h.name} 卦',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w500,
                letterSpacing: 10, color: YiColors.textPrimary)),
        const SizedBox(height: 6),
        Text('${h.en} · 第 ${h.no} 卦',
            style: const TextStyle(fontSize: 11, letterSpacing: 2, color: YiColors.gold)),
        const SizedBox(height: 6),
        Text(h.desc,
            style: const TextStyle(fontSize: 12, letterSpacing: 1, color: YiColors.cinnabar)),
      ]);

  // ---------- 卦辞引文 ----------
  Widget _quote(Hex h) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: YiColors.inkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: YiColors.strokeSoft),
        ),
        child: Text('「${h.guaci}」',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.7,
                letterSpacing: 1, color: YiColors.textPrimary)),
      );

  // ---------- 分隔线 ----------
  Widget _divider(String text) => Row(children: [
        Expanded(child: Container(height: 1, color: YiColors.strokeSoft)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(text, style: const TextStyle(fontSize: 11, letterSpacing: 3, color: YiColors.textTertiary)),
        ),
        Expanded(child: Container(height: 1, color: YiColors.strokeSoft)),
      ]);

  // ---------- 通用段落 ----------
  Widget _section({required String body}) => Text(body,
      style: const TextStyle(fontSize: 13, height: 1.8, color: YiColors.textSecondary));

  // ---------- 象传 ----------
  Widget _daxiang(Hex h) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(h.daxiang,
            style: const TextStyle(fontSize: 14, letterSpacing: 1, color: YiColors.gold)),
        const SizedBox(height: 8),
        Text(_daxiangMeaning(h),
            style: const TextStyle(fontSize: 12, height: 1.7, color: YiColors.textSecondary)),
      ]);

  /// 象传白话释义 (从 intro 派生, 避免重复造数据)
  String _daxiangMeaning(Hex h) {
    // 大象格式: "天行健，君子以自强不息。"
    // 提取"君子以X"部分做白话
    final m = RegExp(r'君子以(.+)。').firstMatch(h.daxiang);
    if (m != null) {
      return '观此卦象，君子当${m.group(1)}。';
    }
    return h.intro;
  }

  // ---------- 六爻互动 ----------
  Widget _yaoSummary(Hex h) => Row(children: [
        Container(width: 6, height: 6,
            decoration: const BoxDecoration(color: YiColors.gold, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(_expandedYao == null
            ? '点 击 任 意 爻 查 看 爻 辞'
            : '${h.yaoName(_expandedYao!)} · ${h.yao[_expandedYao!].n}',
            style: const TextStyle(fontSize: 11, letterSpacing: 2, color: YiColors.gold)),
      ]);

  List<Widget> _yaoRows(Hex h) {
    // 上爻在上: 5,4,3,2,1,0
    return [for (var i = 5; i >= 0; i--) _yaoRow(h, i)];
  }

  Widget _yaoRow(Hex h, int i) {
    final y = h.yao[i];
    final expanded = _expandedYao == i;
    final posLabel = i == 0 ? '初' : (i == 5 ? '上' : '${i + 1}');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: expanded ? const Color(0xFF1E1810) : YiColors.inkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: expanded ? YiColors.goldDark : YiColors.strokeSoft),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _expandedYao = expanded ? null : i);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: h.isYang(i) ? YiColors.gold.withValues(alpha: 0.12) : YiColors.cinnabar.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(posLabel,
                      style: TextStyle(fontSize: 12, color: h.isYang(i) ? YiColors.gold : YiColors.cinnabar)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(y.n,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                          letterSpacing: 1, color: YiColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(y.q, maxLines: expanded ? null : 1,
                      overflow: expanded ? null : TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: YiColors.textSecondary)),
                ])),
                AnimatedRotation(
                  turns: expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.chevron_right, size: 18, color: YiColors.textTertiary),
                ),
              ]),
              if (expanded) ...[
                const SizedBox(height: 12),
                Container(height: 1, color: YiColors.strokeSoft),
                const SizedBox(height: 10),
                Text('「${y.q}」',
                    style: const TextStyle(fontSize: 12, letterSpacing: 0.5, color: YiColors.gold)),
                const SizedBox(height: 6),
                Text(y.d,
                    style: const TextStyle(fontSize: 12, height: 1.7, color: YiColors.textSecondary)),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  // ---------- 底部操作 ----------
  Widget _actions(Hex h) => Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _share(h),
            style: OutlinedButton.styleFrom(
              foregroundColor: YiColors.gold,
              side: const BorderSide(color: YiColors.goldDark),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.ios_share, size: 17),
            label: const Text('分享卦象', style: TextStyle(letterSpacing: 3, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onGoCast?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: YiColors.cinnabar,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.auto_awesome, size: 17),
            label: const Text('依此卦起卦', style: TextStyle(letterSpacing: 3, fontSize: 13)),
          ),
        ),
      ]);

  // ---------- 分享 ----------
  Future<void> _share(Hex hex) async {
    final img = await renderShareCardImage(ShareCardData(
      hex: hex,
      moving: const [],
      question: '今日一卦 · ${hex.name}卦',
      now: DateTime.now(),
    ));
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/yijing_hero_$stamp.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    await Share.shareXFiles([XFile(file.path)], text: '易道 · 今日一卦 ${hex.name}卦');
  }
}
