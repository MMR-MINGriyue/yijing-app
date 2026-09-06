import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/data/favorites_store.dart';
import 'package:yijing_transform/data/history_repository.dart';
import 'package:yijing_transform/data/history_store.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/viewmodel/me_viewmodel.dart';
import 'package:yijing_transform/viewmodel/settings_viewmodel.dart';
import 'package:yijing_transform/model/history.dart';
import 'package:yijing_transform/viewmodel/cast_viewmodel.dart';
import 'package:yijing_transform/viewmodel/hexgrid_viewmodel.dart';
import 'package:yijing_transform/viewmodel/history_viewmodel.dart';
import 'package:yijing_transform/viewmodel/home_viewmodel.dart';

void main() {
  late HexRepository repo;

  setUp(() {
    repo = HexRepository.instance..init();
  });

  HistoryRepository newHist({bool seed = true}) =>
      HistoryRepository(store: MemoryHistoryStore(), seedSamples: seed);

  group('HomeViewModel — 屏1 今日一卦', () {
    test('时辰卦 + 问候 + 干支日期', () {
      final fixed = DateTime(2026, 9, 6, 10); // 巳时
      final vm = HomeViewModel(
        hexRepo: repo,
        history: newHist(),
        now: () => fixed,
      );
      expect(vm.todayHex.no, 11); // hour 10 → 序号10 泰卦
      expect(vm.isHourHex, isTrue);
      expect(vm.greeting, '巳时安，慕白');
      expect(vm.shichenTip, '巳 · 隅 中');
      expect(vm.dateLine, '丙午年 丙申月 癸未日 · 9月6日');
    });

    test('刷新轮换 64 卦', () {
      final vm = HomeViewModel(
        hexRepo: repo,
        history: newHist(),
        now: () => DateTime(2026, 9, 6, 10),
      );
      vm.refreshHero();
      expect(vm.isHourHex, isFalse);
      expect(vm.todayHex.no, 2); // refresh 1 → 64 卦第 2 位 坤
      vm.refreshHero();
      expect(vm.todayHex.no, 3);
    });

    test('最近占卜取前 2 条卦类记录', () {
      final hist = newHist(seed: false);
      hist.add(HistoryRecord(
        hexNo: 5, name: '需', question: 'Q1', direction: '事业',
        directionColor: 'cinnabar', ts: DateTime(2026, 9, 5),
      ));
      hist.add(HistoryRecord(
        hexNo: 2, name: '坤', question: 'Q2', direction: '感情',
        directionColor: 'pine', ts: DateTime(2026, 9, 4),
      ));
      hist.add(HistoryRecord(
        question: '八字总览', direction: '事业', directionColor: 'gold',
        type: 'bazi', ts: DateTime(2026, 9, 3), // 非卦类 → 过滤
      ));
      final vm = HomeViewModel(hexRepo: repo, history: hist);
      expect(vm.recent.length, 2);
      expect(vm.recent.map((r) => r.hexNo), [2, 5]); // add() 置于最前: 坤后加 → 最新在前
    });
  });

  group('CastViewModel — 屏2 起卦闭环', () {
    test('numeric 起卦 → 落历史 → done', () {
      final hist = newHist(seed: false);
      final fixed = DateTime(2026, 9, 6, 10);
      final vm = CastViewModel(
        hexRepo: repo,
        history: hist,
        now: () => fixed,
      );
      vm.setQuestion('近期事业运筹方向');
      vm.setDirection('财运');
      vm.startCast();
      expect(vm.state.phase, CastPhase.casting);
      vm.finishCast();
      expect(vm.state.phase, CastPhase.done);
      expect(vm.state.hex, isNotNull);
      // numeric 由文本哈希定卦: numbers [4797, 2131]
      final recs = hist.load();
      expect(recs.length, 1);
      expect(recs.first.direction, '财运');
      expect(recs.first.directionColor, 'gold');
      expect(recs.first.type, 'iching');
      expect(recs.first.ts, fixed);
      expect(recs.first.hexNo, vm.state.hex!.no);
      expect(recs.first.lines, vm.state.hex!.yangs);
    });

    test('铜钱起卦用注入随机数 → 动爻正确落历史', () {
      final hist = newHist(seed: false);
      final vm = CastViewModel(
        hexRepo: repo,
        history: hist,
        rand: () => 0.1, // 全背 → 六爻全老阳动
        now: () => DateTime(2026, 9, 6),
      );
      vm.setMethod(CastMethod.coin);
      vm.startCast();
      vm.finishCast();
      expect(vm.state.result!.moving, [0, 1, 2, 3, 4, 5]);
      expect(vm.state.hex!.no, 1); // 全阳 乾
      expect(hist.load().first.moving, [0, 1, 2, 3, 4, 5]);
    });

    test('小六壬起课落历史', () {
      final hist = newHist(seed: false);
      final vm = CastViewModel(
        hexRepo: repo,
        history: hist,
        now: () => DateTime(2026, 9, 6, 10),
      );
      vm.castXlr();
      expect(vm.state.xlr, isNotNull);
      expect(vm.state.xlr!.result.name, '空亡');
      final rec = hist.load().single;
      expect(rec.type, 'xlr');
      expect(rec.hexNo, isNull);
      expect(rec.question, contains('空亡'));
    });

    test('梅花数字式起卦落历史', () {
      final hist = newHist(seed: false);
      final vm = CastViewModel(hexRepo: repo, history: hist);
      vm.castMeihua(3, 8);
      expect(vm.state.hex!.no, 35); // 火地晋
      final rec = hist.load().single;
      expect(rec.type, 'meihua');
      expect(rec.name, '晋');
    });

    test('八字排盘落历史 (真实四柱)', () {
      final hist = newHist(seed: false);
      final vm = CastViewModel(
        hexRepo: repo,
        history: hist,
        now: () => DateTime(2026, 9, 6),
      );
      vm.setDirection('事业');
      vm.computeBazi(DateTime(1990, 5, 15, 14, 30), 'male');
      expect(vm.state.bazi, isNotNull);
      expect(vm.state.dayun, isNotNull);
      expect(vm.state.bazi!.pillars.map((p) => p.gz).join(' '), '庚午 辛巳 庚辰 癸未');
      final rec = hist.load().single;
      expect(rec.type, 'bazi');
      expect(rec.hexNo, isNull);
      expect(rec.question, contains('庚午 辛巳 庚辰 癸未'));
      expect(rec.direction, '事业');
    });

    test('梅花时间式落历史 (真实农历)', () {
      final hist = newHist(seed: false);
      final vm = CastViewModel(
        hexRepo: repo,
        history: hist,
        now: () => DateTime(2026, 9, 6, 10, 30),
      );
      vm.castMeihuaTime();
      expect(vm.state.phase, CastPhase.done);
      expect(vm.state.hex!.no, 18); // 山风蛊
      expect(vm.state.result!.moving, [2]);
      final rec = hist.load().single;
      expect(rec.type, 'meihua');
      expect(rec.name, '蛊');
      expect(rec.question, contains('七月'));
    });

    test('更多占法子页开关', () {
      final vm = CastViewModel(hexRepo: repo, history: newHist());
      vm.openMorePage();
      expect(vm.state.morePage, isTrue);
      vm.backToMain();
      expect(vm.state.morePage, isFalse);
    });
  });

  group('HexGridViewModel — 屏3 卦库', () {
    late HexGridViewModel vm;
    setUp(() => vm = HexGridViewModel(repo: repo));

    test('全量 64 卦按卦序', () {
      expect(vm.filtered.length, 64);
      expect(vm.filtered.first.no, 1);
      expect(vm.filtered.last.no, 64);
    });

    test('宫筛选: 乾宫 8 卦按世位排序', () {
      vm.setPalace('乾宫');
      expect(vm.filtered.map((h) => h.no).toList(), [1, 44, 33, 12, 20, 23, 35, 14]);
    });

    test('搜索: 卦名/卦序/拼音', () {
      vm.setKeyword('咸');
      expect(vm.filtered.map((h) => h.no), [31]);
      vm.setKeyword('31');
      expect(vm.filtered.map((h) => h.no), [31]);
      vm.setKeyword('xian');
      expect(vm.filtered.map((h) => h.no), contains(31));
      vm.setKeyword('不存在');
      expect(vm.filtered, isEmpty);
    });

    test('宫位归属', () {
      expect(vm.palaceOfHex(1), '乾宫');
      expect(vm.palaceOfHex(29), '坎宫');
    });
  });

  group('MeViewModel — 屏7 我的', () {
    test('统计 + 连续天数 + 始于', () {
      final hist = newHist(seed: false);
      final now = DateTime.now();
      hist.add(HistoryRecord(
        hexNo: 1, name: '乾', question: 'Q', direction: '事业',
        directionColor: 'cinnabar', ts: now,
      ));
      hist.add(HistoryRecord(
        hexNo: 2, name: '坤', question: 'Q', direction: '事业',
        directionColor: 'cinnabar', ts: now.subtract(const Duration(days: 1)),
      ));
      hist.add(HistoryRecord(
        hexNo: 3, name: '屯', question: 'Q', direction: '感情',
        directionColor: 'pine',
        ts: now.subtract(const Duration(days: 9)),
      ));
      final vm = MeViewModel(hexRepo: repo, history: hist);
      expect(vm.totalCount, 3);
      expect(vm.streak, 2); // 今日 + 昨日连续
      expect(vm.since!.day, now.subtract(const Duration(days: 9)).day);
    });

    test('方向/方式分布', () {
      final hist = newHist(seed: false);
      hist.add(HistoryRecord(
        hexNo: 1, name: '乾', question: 'Q', direction: '事业',
        directionColor: 'cinnabar', ts: DateTime.now(),
      ));
      hist.add(HistoryRecord(
        hexNo: 6, name: '讼', question: 'Q', direction: '事业',
        directionColor: 'cinnabar', ts: DateTime.now(),
      ));
      hist.add(HistoryRecord(
        hexNo: 2, name: '坤', question: 'Q', direction: '财运',
        directionColor: 'gold', type: 'meihua', ts: DateTime.now(),
      ));
      final vm = MeViewModel(hexRepo: repo, history: hist);
      // 计数不等保证排序确定性: 事业 2 > 财运 1
      expect(vm.directionDist.map((d) => d.dir), ['事业', '财运']);
      // 易经 2 > 梅花 1
      expect(vm.methodDist.first.method, '易经');
      expect(vm.methodDist.map((m) => m.method), contains('梅花'));
    });

    test('收藏切换联动', () {
      final favs = FavoritesRepository(store: MemoryFavoritesStore());
      final vm = MeViewModel(hexRepo: repo, history: newHist(), favs: favs);
      expect(vm.favorites, isEmpty);
      vm.toggleFav(31);
      expect(vm.favorites.first.no, 31);
      expect(vm.favCount, 1);
      vm.toggleFav(31);
      expect(vm.favorites, isEmpty);
    });
  });

  group('HistoryRepository — 真实落盘 + 示例合并', () {
    test('新增记录在最前, 示例垫底', () {
      final hist = newHist();
      final total0 = hist.load().length; // 含种子
      expect(total0, greaterThanOrEqualTo(9));
      hist.add(HistoryRecord(
        hexNo: 9, name: '小畜', question: '新记录', direction: '事业',
        directionColor: 'cinnabar', ts: DateTime(2026, 9, 6),
      ));
      expect(hist.load().first.name, '小畜');
      expect(hist.load().length, total0 + 1);
    });

    test('clearReal 只清真实记录', () {
      final hist = newHist();
      hist.add(HistoryRecord(
        hexNo: 9, name: '小畜', question: 'Q', direction: '事业',
        directionColor: 'cinnabar', ts: DateTime(2026, 9, 6),
      ));
      hist.clearReal();
      expect(hist.load().where((r) => r.name == '小畜'), isEmpty);
      expect(hist.load(), isNotEmpty); // 示例仍在
    });

    test('JSON 序列化往返 + 容错', () {
      final rec = HistoryRecord(
        hexNo: 31, name: '咸', question: 'Q', direction: '感情',
        directionColor: 'pine', ts: DateTime(2026, 9, 6, 19, 8),
        lines: [true, false, false, false, false, false], moving: [0],
      );
      final back = HistoryRecord.fromJson(rec.toJson());
      expect(back.hexNo, 31);
      expect(back.lines, rec.lines);
      expect(back.moving, rec.moving);
      // 畸形数据不崩溃
      final bad = HistoryRecord.fromJson({'ts': 1757148000000});
      expect(bad.question, '');
      expect(bad.type, 'iching');
    });
  });

  group('SettingsViewModel — iter35 设置面板', () {
    test('导出 JSON 为 PWA 兼容格式', () {
      final hist = newHist(seed: false);
      hist.add(HistoryRecord(
        hexNo: 31, name: '咸', question: 'Q', direction: '感情',
        directionColor: 'pine', ts: DateTime(2026, 9, 6),
      ));
      final vm = SettingsViewModel(
        history: hist,
        favs: FavoritesRepository(store: MemoryFavoritesStore([1, 2])),
      );
      final json = vm.exportJson();
      expect(json, contains('"app": "yijing-app"'));
      expect(json, contains('"exportedAt"'));
      expect(json, contains('"favorites"'));
      expect(json, contains('咸'));
    });

    test('导入合并: 去重 + 收藏并集', () {
      final hist = newHist(seed: false);
      hist.add(HistoryRecord(
        hexNo: 31, name: '咸', question: 'Q', direction: '感情',
        directionColor: 'pine', ts: DateTime(2026, 9, 6),
      ));
      final favs = FavoritesRepository(store: MemoryFavoritesStore([5]));
      final vm = SettingsViewModel(history: hist, favs: favs);
      // 同 ts 重复 1 条 + 新增 1 条 + 收藏 [5(重复), 8(新)]
      final incoming = '''
      {
        "app": "yijing-app",
        "history": [
          {"hexNo": 31, "name": "咸", "question": "Q", "direction": "感情",
           "directionColor": "pine", "type": "iching",
           "ts": ${DateTime(2026, 9, 6).millisecondsSinceEpoch}, "lines": [1,0,0,0,0,0]},
          {"hexNo": 9, "name": "小畜", "question": "新记录", "direction": "事业",
           "directionColor": "cinnabar", "type": "iching",
           "ts": ${DateTime(2026, 9, 5).millisecondsSinceEpoch}, "lines": [1,1,0,1,1,1]}
        ],
        "favorites": [5, 8]
      }''';
      final msg = vm.importJson(incoming);
      expect(msg, contains('新增 1 条'));
      expect(msg, contains('1 卦收藏'));
      expect(hist.load().length, 2);
      expect(favs.load(), [5, 8]);
    });

    test('导入兼容 PWA 字符串 lines (yang/yin/moving)', () {
      final hist = newHist(seed: false);
      final vm = SettingsViewModel(history: hist, favs: FavoritesRepository(
        store: MemoryFavoritesStore(),
      ));
      vm.importJson('''
      {
        "history": [
          {"hexNo": 1, "name": "乾", "question": "PWA记录", "direction": "事业",
           "directionColor": "cinnabar", "type": "iching",
           "ts": ${DateTime(2026, 8, 1).millisecondsSinceEpoch},
           "lines": ["yang", "yin", "moving", "yin", "yang", "movingYin"]}
        ]
      }''');
      final rec = hist.load().single;
      expect(rec.lines, [true, false, true, false, true, false]); // moving=阳, movingYin=阴
      expect(rec.moving, isNull); // PWA 格式动爻在 lines 内联, 不恢复 moving 数组
    });

    test('清空真实记录 (示例不受影响由 Repository 保证)', () {
      final hist = newHist(); // seed: true
      final vm = SettingsViewModel(history: hist, favs: FavoritesRepository(
        store: MemoryFavoritesStore(),
      ));
      expect(vm.recordCount, greaterThanOrEqualTo(9));
      vm.clearReal();
      // 真实记录清空, 示例垫底仍在
      expect(vm.recordCount, greaterThanOrEqualTo(9));
      // meta 行反映空真实记录
      expect(vm.metaLine, contains('收藏 0 卦'));
    });

    test('流年展开选择 (selectDayunStep)', () {
      final vm = CastViewModel(hexRepo: repo, history: newHist(seed: false));
      vm.computeBazi(DateTime(1990, 5, 15, 14, 30), 'male');
      expect(vm.state.selectedDayunStep, isNull);
      vm.selectDayunStep(0);
      expect(vm.state.selectedDayunStep, 0);
      // 再点收起
      vm.selectDayunStep(0);
      expect(vm.state.selectedDayunStep, 0); // copyWith 不清除 — 由 View 传 null 收起
      vm.selectDayunStep(null);
      expect(vm.state.selectedDayunStep, isNull);
    });
  });

  group('HistoryViewModel — 收藏数联动', () {
    test('favCount 来自 FavoritesRepository', () {
      final favs = FavoritesRepository(store: MemoryFavoritesStore([5, 14]));
      final vm = HistoryViewModel(repo: HistoryRepository.instance, favs: favs);
      expect(vm.favCount, 2);
    });
  });
}
