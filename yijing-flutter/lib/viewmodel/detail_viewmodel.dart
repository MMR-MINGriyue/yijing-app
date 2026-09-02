import 'package:flutter/foundation.dart';

import '../data/hex_repository.dart';
import '../model/hex.dart';

/// 屏 4 卦辞解析 Tab
enum DetailTab { guaci, yaoci, xiangzhuan }

/// ViewModel — 持当前卦 + 激活 Tab + 收藏态
class DetailViewModel extends ChangeNotifier {
  final HexRepository _repo;
  late Hex _hex;
  DetailTab _tab = DetailTab.guaci;
  final Set<int> _fav = <int>{};

  DetailViewModel({HexRepository? repo, int hexNo = 1})
      : _repo = repo ?? HexRepository.instance {
    _hex = _repo.hexByNo(hexNo);
    _loadFav();
  }

  Hex get hex => _hex;
  DetailTab get tab => _tab;

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

  bool isFav(int no) => _fav.contains(no);

  void toggleFav(int no) {
    if (!_fav.remove(no)) _fav.add(no);
    _saveFav();
    notifyListeners();
  }

  /* 与易道 localStorage 键一致: yijing.favHexes */
  void _loadFav() {
    // web 版用 localStorage (通过 dart:html 不可行; 降级到内存 + SharedPreferences 由外部注入)
    // 此处保持内存态, 由 UI 层持久化 (见 detail_screen fav 按钮旁注)
  }

  void _saveFav() {}
}
