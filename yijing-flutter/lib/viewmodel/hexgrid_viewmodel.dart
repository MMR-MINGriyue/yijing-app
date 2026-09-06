import 'package:flutter/foundation.dart';

import '../core/palace.dart';
import '../data/hex_repository.dart';
import '../model/hex.dart';

/// ViewModel — 屏 3 六十四卦网格 (宫筛选 + 搜索)
class HexGridViewModel extends ChangeNotifier {
  final HexRepository _repo;
  String _palaceFilter = ''; // '' = 八宫全部
  String _keyword = '';

  HexGridViewModel({HexRepository? repo})
      : _repo = repo ?? HexRepository.instance;

  String get palaceFilter => _palaceFilter;
  String get keyword => _keyword;

  /// 宫筛选 chips
  List<String> get palaceChips => kPalaceNames;

  /// 宫内卦序 (选宫时按 本宫→归魂 排序)
  List<Hex> get filtered {
    List<Hex> list;
    if (_palaceFilter.isEmpty) {
      list = List.generate(64, (i) => _repo.hexByNo(i + 1));
    } else {
      list = palaceMembers(_palaceFilter).map(_repo.hexByNo).toList();
    }
    if (_keyword.isNotEmpty) {
      final kw = _keyword.toLowerCase();
      list = list
          .where((h) =>
              h.name.contains(kw) ||
              h.en.toLowerCase().contains(kw) ||
              h.no.toString() == kw ||
              h.desc.contains(kw))
          .toList();
    }
    return list;
  }

  void setPalace(String p) {
    _palaceFilter = p;
    notifyListeners();
  }

  void setKeyword(String kw) {
    _keyword = kw.trim();
    notifyListeners();
  }

  Hex hexByNo(int no) => _repo.hexByNo(no);

  /// 卦的宫位名 (卡片副行)
  String? palaceOfHex(int no) => palaceOf(no)?.palace;
}
