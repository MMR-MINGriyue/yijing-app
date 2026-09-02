import 'package:flutter/foundation.dart';

import '../data/hex_repository.dart';
import '../model/hex.dart';

/// 屏 5 状态 — MVVM 的 State (不可变快照)
class TransformState {
  final int benNo;
  final List<int> moving;
  final TransformResult result;

  const TransformState({required this.benNo, required this.moving, required this.result});

  TransformState copyWith({int? benNo, List<int>? moving, TransformResult? result}) =>
      TransformState(
        benNo: benNo ?? this.benNo,
        moving: moving ?? this.moving,
        result: result ?? this.result,
      );
}

/// ViewModel — 持有状态 + 业务入口 (对应原生 ViewModel + StateFlow)
class TransformViewModel extends ChangeNotifier {
  final HexRepository _repo;
  late TransformState _state;

  TransformViewModel({HexRepository? repo})
      : _repo = repo ?? HexRepository.instance {
    _state = _compute(1, [2]); // 默认: 乾卦 九三动 → 履
  }

  TransformState get state => _state;

  TransformState _compute(int benNo, List<int> moving) {
    final result = _repo.transform(benNo, moving);
    return TransformState(benNo: benNo, moving: moving, result: result);
  }

  /// 点击第 [i] 爻: 切换该爻为动爻 (与易道交互一致)
  void toggleMoving(int i) {
    final mv = List<int>.from(_state.moving);
    if (mv.contains(i)) { mv.remove(i); } else { mv.add(i); }
    mv.sort();
    _state = _compute(_state.benNo, mv);
    notifyListeners();
  }

  /// 换本卦
  void selectHex(int no) {
    _state = _compute(no, const []);
    notifyListeners();
  }

  /// 供 UI 读取任意卦 (picker)
  Hex hexByNo(int no) => _repo.hexByNo(no);

  /// 当前本卦
  Hex get currentBen => _state.result.ben;

  /// 随机起卦 (测试与演示)
  void randomCast() {
    final benNo = 1 + (DateTime.now().millisecondsSinceEpoch % 64);
    final moving = List.generate(1 + (DateTime.now().microsecondsSinceEpoch % 2),
        (_) => DateTime.now().microsecondsSinceEpoch % 6).toSet().toList()..sort();
    _state = _compute(benNo, moving.isEmpty ? [2] : moving);
    notifyListeners();
  }

  /// 爻变明细行 (供推演视图)
  List<YaoChange> yaoChanges() {
    final ben = _state.result.ben;
    return _state.moving.map((i) {
      final fromYang = ben.isYang(i);
      final toYang = !fromYang;
      String yaoName(int idx, bool yang) {
        const pos = ['初', '二', '三', '四', '五', '上'];
        final n = yang ? '九' : '六';
        return (idx == 0 || idx == 5) ? pos[idx] + n : n + pos[idx];
      }
      return YaoChange(
        idx: i,
        from: yaoName(i, fromYang),
        to: yaoName(i, toYang),
        fromYang: fromYang,
      );
    }).toList();
  }
}
