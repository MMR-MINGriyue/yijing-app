/// 收藏存储 — 纯 Dart 层 (零 Flutter 依赖)
/// Prefs 实现见 history_store_prefs.dart
library;

/// 收藏存储接口
abstract class FavoritesStore {
  List<int> read();
  void write(List<int> hexNos);

  /// 启动预热 (Prefs 实现覆盖; 默认无操作)
  Future<void> warmUp() async {}
}

/// 内存实现 — 单元测试 / 默认实现
class MemoryFavoritesStore implements FavoritesStore {
  List<int> _nos;
  MemoryFavoritesStore([List<int>? seed]) : _nos = seed ?? [];

  @override
  List<int> read() => List.of(_nos);

  @override
  void write(List<int> hexNos) => _nos = List.of(hexNos);

  @override
  Future<void> warmUp() async {}
}

/// 默认存储工厂 — main() 里由 installPrefsStores() 覆盖为 Prefs 实现
FavoritesStore Function() favoritesStoreFactory = () => MemoryFavoritesStore();

/// 收藏 Repository — 切换 / 查询 (对应易道 yijing.favHexes)
class FavoritesRepository {
  FavoritesRepository({FavoritesStore? store})
      : _store = store ?? favoritesStoreFactory();

  /// 默认单例 (真机用); 测试自行注入 MemoryFavoritesStore
  static final FavoritesRepository instance = FavoritesRepository();

  final FavoritesStore _store;

  /// 启动预热
  Future<void> warmUp() => _store.warmUp();

  List<int> load() => _store.read();

  bool isFav(int hexNo) => _store.read().contains(hexNo);

  /// 切换收藏, 返回切换后的状态
  bool toggle(int hexNo) {
    final list = _store.read();
    if (list.contains(hexNo)) {
      list.remove(hexNo);
      _store.write(list);
      return false;
    }
    list.add(hexNo);
    _store.write(list);
    return true;
  }
}
