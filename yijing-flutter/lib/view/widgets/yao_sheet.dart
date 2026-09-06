import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../model/hex.dart';
import '../../theme/yijing_theme.dart';

/// 爻辞弹窗 — PWA 屏4/屏5 爻行弹窗对应物 (原文 + 白话 + 复制)
void showYaoSheet(BuildContext context, Hex hex, int i) {
  final yao = hex.yao[i];
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: YiColors.inkCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('${yao.n} · ${hex.name}卦',
                  style: const TextStyle(
                      fontSize: 16, letterSpacing: 2, color: YiColors.gold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: YiColors.textTertiary),
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: '${yao.n} · ${hex.name}卦\n${yao.q}\n${yao.d}'));
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content:
                          Text('爻辞已复制', style: TextStyle(color: YiColors.textPrimary)),
                      backgroundColor: Color(0xFF231A11),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ));
                  }
                },
                tooltip: '复制爻辞',
              ),
            ]),
            const SizedBox(height: 8),
            Text(yao.q,
                style: const TextStyle(
                    fontSize: 15, height: 1.7, color: YiColors.textPrimary)),
            const SizedBox(height: 8),
            Text(yao.d,
                style: const TextStyle(
                    fontSize: 13, height: 1.7, color: YiColors.textSecondary)),
          ]),
    ),
  );
}
