/// 今日一卦 (iter63) — 日辰卦序法.
/// 真实连续日序 (UTC 天号) + 时辰索引 → 64 卦循环:
/// 每天同一时辰卦序 +1, 同一天不同时辰再按 12 时辰偏移, 覆盖全部 64 卦.
///
/// 设计取舍: 曾试梅花易数 meiHuaByTime (年月日时起卦), 但固定时辰时
/// 上下卦只随 (年+月+日)%8 变化, 60 天仅覆盖 8 卦 —— 比旧 hourHex 的
/// 16 卦循环更单调, 故不用。梅花时间起卦仍保留在占卜页作为门派算法。
///
/// 保留 cast_engine.hourHex 不动 (PWA 对拍基线), 主页与启动动画改用本函数.
library;

import '../data/hex_library.dart';
import 'lunar_calendar.dart' show shichenIndex;

HexEntry dailyHex(DateTime dt) {
  final daySerial = DateTime.utc(dt.year, dt.month, dt.day)
          .millisecondsSinceEpoch ~/
      86400000;
  final idx = (daySerial + shichenIndex(dt)) % kHexLibrary.length;
  return kHexLibrary[idx];
}
