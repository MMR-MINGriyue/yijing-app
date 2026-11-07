import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/data/bazi_store.dart';
import 'package:yijing_transform/viewmodel/settings_viewmodel.dart';

void main() {
  BaziBirth birth(int y, int m, int d, String gender) =>
      BaziBirth(dt: DateTime(y, m, d, 8), gender: gender);

  test('导出 JSON 含命盘册 profiles (iter63)', () {
    final store = MemoryBaziBirthStore();
    store.writeProfiles({'本人': birth(1990, 5, 15, 'male')});
    final vm = SettingsViewModel(baziStore: store);
    final j = jsonDecode(vm.exportJson()) as Map<String, dynamic>;
    expect(j.containsKey('profiles'), isTrue);
    final profiles = j['profiles'] as Map<String, dynamic>;
    expect(profiles.containsKey('本人'), isTrue);
  });

  test('导入合并命盘: 同名不覆盖, 新名新增', () {
    final dst = MemoryBaziBirthStore();
    dst.writeProfiles({'本人': birth(1990, 5, 15, 'male')});
    final vm = SettingsViewModel(baziStore: dst);
    final payload = jsonEncode({
      'app': 'yijing-app',
      'profiles': {
        '本人': birth(2000, 1, 1, 'female').toJson(),
        '母亲': birth(1960, 5, 1, 'female').toJson(),
      },
    });
    final msg = vm.importJson(payload);
    expect(msg, contains('1 个命盘'));
    final p = dst.readProfiles();
    expect(p.length, 2);
    expect(p['本人']!.dt, DateTime(1990, 5, 15, 8)); // 同名保留本地
    expect(p['母亲']!.dt, DateTime(1960, 5, 1, 8));
  });

  test('旧版 PWA 导出 (无 profiles) 仍可导入', () {
    final vm = SettingsViewModel(baziStore: MemoryBaziBirthStore());
    final msg = vm.importJson(jsonEncode({
      'app': 'yijing-app',
      'history': [],
      'favorites': [1, 2],
    }));
    expect(msg, contains('收藏'));
  });

  test('只有空 profiles 时提示无可导入数据', () {
    final vm = SettingsViewModel(baziStore: MemoryBaziBirthStore());
    expect(vm.importJson(jsonEncode({'app': 'yijing-app', 'profiles': {}})),
        '没有可导入的数据');
  });
}
