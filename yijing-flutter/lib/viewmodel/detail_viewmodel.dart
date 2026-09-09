import 'package:flutter/foundation.dart';

import '../data/favorites_store.dart';
import '../data/hex_advice.dart';
import '../data/hex_repository.dart';
import '../model/hex.dart';

/// 屏 4 卦辞解析 Tab
enum DetailTab { guaci, yaoci, xiangzhuan }

/// ViewModel — 持当前卦 + 激活 Tab + 收藏态 (FavoritesRepository 真实持久化)
class DetailViewModel extends ChangeNotifier {
  final HexRepository _repo;
  final FavoritesRepository _favs;
  late Hex _hex;
  DetailTab _tab = DetailTab.guaci;
  String _question = ''; // 所问之事 (分享卡用)
  String _adviceDir = kAdviceDirections.first; // 方向建议选中项

  /// 动爻索引 (来自历史记录/起卦结果, 分享卡与推演跳转用)
  final List<int> moving;

  /// 所问方向 (历史记录/起卦传入, 用于建议默认选中; 非法值回退事业)
  final String direction;

  DetailViewModel({
    HexRepository? repo,
    FavoritesRepository? favs,
    int hexNo = 1,
    String question = '',
    this.moving = const [],
    this.direction = '',
  })  : _repo = repo ?? HexRepository.instance,
        _favs = favs ?? FavoritesRepository.instance {
    _hex = _repo.hexByNo(hexNo);
    _question = question;
    if (kAdviceDirections.contains(direction)) _adviceDir = direction;
  }

  Hex get hex => _hex;
  DetailTab get tab => _tab;
  String get question => _question;
  String get adviceDir => _adviceDir;

  void selectHex(int no) {
    _hex = _repo.hexByNo(no);
    _tab = DetailTab.guaci;
    notifyListeners();
  }

  void setTab(DetailTab t) {
    if (_tab == t) return;
    _tab = t;
    notifyListeners();
  }

  void setAdviceDir(String d) {
    if (!kAdviceDirections.contains(d) || _adviceDir == d) return;
    _adviceDir = d;
    notifyListeners();
  }

  bool isFav(int no) => _favs.isFav(no);

  void toggleFav(int no) {
    _favs.toggle(no);
    notifyListeners();
  }
}
