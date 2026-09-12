/// 八字出生信息存储 (iter47) — 记忆上次排盘输入, 免于重复选择
/// 抽象 + 内存实现 (测试/桌面); 真机 Prefs 实现见 bazi_store_prefs.dart
library;

import '../core/bazi.dart';

/// 出生信息 (公历时刻 + 乾坤造 + 流派选项)
class BaziBirth {
  final DateTime dt;
  final String gender; // male=乾造 female=坤造
  final BaZiOptions options; // 流派选项 (iter48)

  const BaziBirth({
    required this.dt,
    required this.gender,
    this.options = const BaZiOptions(),
  });

  Map<String, dynamic> toJson() => {
        'ts': dt.millisecondsSinceEpoch,
        'gender': gender,
        'opts': options.toJson(),
      };

  static BaziBirth? fromJson(Map<String, dynamic> j) {
    final ts = j['ts'];
    if (ts is! int) return null;
    final g = j['gender'] is String ? j['gender'] as String : 'male';
    final opts = j['opts'] is Map<String, dynamic>
        ? BaZiOptions.fromJson(j['opts'] as Map<String, dynamic>)
        : const BaZiOptions();
    return BaziBirth(
        dt: DateTime.fromMillisecondsSinceEpoch(ts), gender: g, options: opts);
  }
}

abstract class BaziBirthStore {
  BaziBirth? read();
  void write(BaziBirth birth);
  Future<void> warmUp();
}

class MemoryBaziBirthStore implements BaziBirthStore {
  BaziBirth? _cache;

  @override
  BaziBirth? read() => _cache;

  @override
  void write(BaziBirth birth) => _cache = birth;

  @override
  Future<void> warmUp() async {}
}

/// 全局工厂: main() 里切到 Prefs 实现
BaziBirthStore Function() baziBirthStoreFactory = () => MemoryBaziBirthStore();
