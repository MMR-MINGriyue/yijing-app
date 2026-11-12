// iter72 (v1.63.0) 正确性迭代回归 — P0 六项修复 + 落盘队列 + 64 卦库完整性
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yijing_transform/data/bazi_store.dart';
import 'package:yijing_transform/data/history_repository.dart';
import 'package:yijing_transform/data/history_store.dart';
import 'package:yijing_transform/data/history_store_prefs.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/data/prefs_io.dart';
import 'package:yijing_transform/data/profile_store.dart';
import 'package:yijing_transform/model/history.dart';
import 'package:yijing_transform/viewmodel/bazi_viewmodel.dart';
import 'package:yijing_transform/viewmodel/cast_viewmodel.dart';
import 'package:yijing_transform/viewmodel/home_viewmodel.dart';
import 'package:yijing_transform/viewmodel/settings_viewmodel.dart';

void main() {
  setUp(() {
    HexRepository.instance.init();
    SharedPreferences.setMockInitialValues({});
  });

  HistoryRepository newHist() =>
      HistoryRepository(store: MemoryHistoryStore(), seedSamples: false);

  HistoryRecord rec(String q) => HistoryRecord(
        question: q,
        direction: '事业',
        directionColor: 'cinnabar',
        ts: DateTime(2026, 11, 12, 10),
      );

  group('P0-1 冷启动不再污染历史', () {
    test('恢复命盘只排盘不落库; 手动 compute 才落一条', () async {
      final store = MemoryBaziBirthStore();
      store.write(BaziBirth(dt: DateTime(1990, 5, 15, 14, 30), gender: 'male'));
      final hist = newHist();
      final vm = BaziViewModel(store: store, historyRepo: hist);
      await vm.ready;
      expect(vm.state.chart, isNotNull, reason: '恢复后仍需展示命盘');
      expect(vm.state.restored, isTrue);
      expect(hist.load(), isEmpty, reason: '冷启动不得新增历史记录');
      vm.compute();
      expect(hist.load(), hasLength(1));
      expect(hist.load().single.type, 'bazi');
    });
  });

  group('P0-2 当日卦语跨日失效', () {
    test('同日稳定, 跨日重算, retime 不复活旧卦', () {
      var now = DateTime(2026, 11, 12, 10);
      final vm = HomeViewModel(
        hexRepo: HexRepository.instance,
        history: newHist(),
        now: () => now,
      );
      final day1 = vm.quoteHex.no;
      now = DateTime(2026, 11, 12, 22); // 同日换时辰
      expect(vm.quoteHex.no, day1);
      now = DateTime(2026, 11, 13, 10); // 跨日
      final day2 = vm.quoteHex.no;
      expect(day2, isNot(day1), reason: '日期哈希随 day 递增必变');
      vm.retime();
      expect(vm.quoteHex.no, day2);
    });
  });

  group('P0-4 起卦状态机', () {
    test('form 阶段 finishCast 不落库; 换占法丢弃 pending', () {
      final hist = newHist();
      final vm = CastViewModel(
          hexRepo: HexRepository.instance,
          history: hist,
          rand: () => 0.5,
          now: () => DateTime(2026, 11, 12, 10));
      vm.finishCast(); // 未起卦 → 直接挡住
      expect(hist.load(), isEmpty);
      expect(vm.state.phase, CastPhase.form);

      vm.startCast();
      vm.setMethod(CastMethod.coin); // 换占法 → 清 pending + 回 form
      expect(vm.state.phase, CastPhase.form);
      vm.finishCast();
      expect(hist.load(), isEmpty, reason: '不能用上一轮的预计算结果落库');

      vm.startCast();
      vm.finishCast(); // 正常闭环
      expect(hist.load(), hasLength(1));
      expect(vm.state.phase, CastPhase.done);
      vm.finishCast(); // 重复回调也不重复落库
      expect(hist.load(), hasLength(1));
    });

    test('reset 清空 pending', () {
      final hist = newHist();
      final vm = CastViewModel(
          hexRepo: HexRepository.instance,
          history: hist,
          rand: () => 0.5,
          now: () => DateTime(2026, 11, 12, 10));
      vm.startCast();
      vm.reset();
      expect(vm.state.phase, CastPhase.form);
      vm.finishCast();
      expect(hist.load(), isEmpty);
    });
  });

  group('P0-5 问候称呼', () {
    test('设置页改名后首页立即生效; 空名回落默认', () {
      final profile = MemoryProfileStore();
      final home = HomeViewModel(
        hexRepo: HexRepository.instance,
        history: newHist(),
        profile: profile,
        now: () => DateTime(2026, 9, 6, 10), // 巳时
      );
      final settings = SettingsViewModel(
        history: newHist(),
        profile: profile,
      );
      expect(home.greeting, '巳时安，慕白');
      settings.setGreetingName('青禾');
      expect(settings.greetingName, '青禾');
      expect(home.greeting, '巳时安，青禾');
      settings.setGreetingName('   ');
      expect(home.greeting, '巳时安，$kDefaultGreetingName');
    });
  });

  group('P0-3 落盘队列', () {
    test('write 后 flush 可见真实持久化值, 连续写以最后一次为准', () async {
      final store = PrefsHistoryStore();
      await store.warmUp();
      store.write([rec('甲')]);
      store.write([rec('甲'), rec('乙')]);
      await flushPrefsWrites();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('yijing.history.v1');
      expect(raw, isNotNull);
      final list = jsonDecode(raw!) as List;
      expect(list, hasLength(2));
      expect((list.last as Map)['question'], '乙');
      expect(store.read(), hasLength(2));
    });

    test('收藏 / 八字写入走同一队列', () async {
      final favsStore = PrefsFavoritesStore();
      await favsStore.warmUp();
      favsStore.write([1, 7, 64]);
      await flushPrefsWrites();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('yijing.favHexes'), ['1', '7', '64']);
    });

    test('落盘异常经 onPersistenceError 上报而非静默', () async {
      final errors = <Object>[];
      onPersistenceError = (Object e, StackTrace st) => errors.add(e);
      addTearDown(() => onPersistenceError = null);
      await enqueuePrefsWrite('bad.key', 42); // 非法类型 → 队列内抛错
      expect(errors, hasLength(1));
      expect(errors.single, isA<ArgumentError>());
    });
  });

  group('64 卦库完整性', () {
    test('1..64 编号齐全: 卦名/卦辞/大象/六爻均非空', () {
      final repo = HexRepository.instance..init();
      for (var no = 1; no <= 64; no++) {
        final h = repo.hexByNo(no);
        expect(h.no, no);
        expect(h.name.trim(), isNotEmpty, reason: '卦 $no 缺卦名');
        expect(h.guaci.trim(), isNotEmpty, reason: '卦 $no 缺卦辞');
        expect(h.daxiang.trim(), isNotEmpty, reason: '卦 $no 缺大象传');
        expect(h.yao, hasLength(6), reason: '卦 $no 爻辞不齐');
        expect(h.yangs, hasLength(6), reason: '卦 $no 爻线不齐');
        for (var i = 0; i < 6; i++) {
          expect(h.yao[i].q.trim(), isNotEmpty, reason: '卦 $no 第 $i 爻辞为空');
        }
      }
    });
  });
}
