/// 用户称呼存储抽象 — 纯 Dart (iter72: 问候语不再硬编码)
library;

/// 默认称呼; 与 PWA 设计稿一致
const String kDefaultGreetingName = '慕白';

abstract class ProfileStore {
  String readName();
  void writeName(String name);

  Future<void> warmUp() async {}
}

class MemoryProfileStore implements ProfileStore {
  String _name;

  MemoryProfileStore([this._name = kDefaultGreetingName]);

  @override
  String readName() => _name;

  @override
  void writeName(String name) => _name = name.trim().isEmpty
      ? kDefaultGreetingName
      : name.trim();

  @override
  Future<void> warmUp() async {}
}

ProfileStore Function() profileStoreFactory = () => MemoryProfileStore();
