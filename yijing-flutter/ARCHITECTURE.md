# 易道 纯 App 架构 (iter33, v1.30.0)

> 目标: 脱离 PWA + Capacitor WebView 混合形态, 以 Flutter 原生 App 作为唯一交付形态。
> PWA (根目录) 保留为设计基准与数据源; 本目录为纯 App 主线。

## 分层架构

```
┌──────────────────────────────────────────────────────────┐
│ 应用壳层   main.dart + app/app_shell.dart                 │
│            5 Tab Hub (IndexedStack 保留各屏状态)           │
│            详情/推演 → Navigator.push 独立路由             │
├──────────────────────────────────────────────────────────┤
│ View 层    view/*.dart — 7 屏纯 UI, 一切状态来自 ViewModel │
│            共享组件 view/widgets/hex_glyph.dart            │
├──────────────────────────────────────────────────────────┤
│ ViewModel  ChangeNotifier × 7 (状态 + 意图, 无 Flutter UI  │
│            依赖, flutter_test 直接单测)                    │
├──────────────────────────────────────────────────────────┤
│ 核心引擎   core/ — 纯 Dart, 零 Flutter 依赖, dart run 可验  │
│            yi_calendar   干支历 (JDN/纪日/纪年/月干支/时辰) │
│            solar_terms   分钟级节气表 1901-2100 (12 节)     │
│            lunar_calendar 农历 1900-2100 (紧凑表)           │
│            cast_engine   起卦 (铜钱/蓍草/数字 + 文本定数)   │
│            bazi          八字 (四柱/藏干/十神/五行/强弱)    │
│            dayun         大运流年 (起运/8步大运/流年断语)   │
│            meihua        梅花易数 (时间/数字/掷骰三式)      │
│            palace        京房八宫 (卦序→宫/世位)           │
│            xiaoliuren    小六壬 (月日时三数落宫)           │
├──────────────────────────────────────────────────────────┤
│ 服务层     service/reminder_service — 每日提醒 (抽象调度器 + 插件实现)
│ 数据层     data/                                           │
│            hex_library          64 卦完整数据库 (卦辞/爻辞) │
│            hex_repository       卦库访问 + 变卦推演引擎     │
│            history_store        接口 → Prefs(真机)/Mock(测试)│
│            history_repository   历史聚合 (月份/范围)        │
│            favorites_repository 收藏 (接口 + 同上双实现)    │
├──────────────────────────────────────────────────────────┤
│ 模型层     model/  Hex / HistoryRecord / CastResult        │
└──────────────────────────────────────────────────────────┘
```

依赖方向自上而下单向: View → ViewModel → (core / data) → model。
core 与 data 不 import Flutter (仅 ViewModel 用 foundation.ChangeNotifier)。

## 屏幕地图 (对应 PWA 7 屏)

| Tab | 屏 | 文件 | 状态 |
|---|---|---|---|
| 今日 | 屏1 今日一卦 (时辰卦/干支/最近占卜) | view/home_screen.dart | iter33 |
| 起卦 | 屏2 起卦 (易经三式 + 更多占法子页) | view/cast_screen.dart | iter33 |
| 卦库 | 屏3 六十四卦 (宫筛选 + 搜索) | view/hexgrid_screen.dart | iter33 |
| — | 屏4 卦辞解析 (push 路由) | view/detail_screen.dart | iter31 |
| — | 屏5 变卦推演 (push 路由) | view/transform_screen.dart | iter30 |
| 历史 | 屏6 历史记录 (筛选/搜索/统计) | view/history_screen.dart | iter32 |
| 我的 | 屏7 我的 (统计/收藏/分布) | view/me_screen.dart | iter33 |

## 持久化设计

- 抽象 `HistoryStore` / `FavoritesStore` 接口: `read()` / `write()`
- `PrefsHistoryStore` / `PrefsFavoritesStore`: shared_preferences (真机持久化)
- `MockHistoryStore` / `MemoryFavoritesStore`: 内存实现 (测试 + 首跑种子数据)
- ViewModel/Repository 只依赖接口, 单测用内存实现, 真机 main() 注入 Prefs 实现

## 移植对齐原则 (与 PWA 引擎逐位一致)

- 干支纪日锚点: `(JDN - 11) % 60`, JD 2458511 = 甲子日
- 干支纪年: 立春 (≈2/4) 为界, 1984 = 甲子
- 月干支: 年上起月法 + 24 节气日期级表 (精度 ±1 天, UI 足够)
- 文本定数: FNV-1a + DJB2 双哈希 (UTF-16 码元, >>>0 无符号截断)
- 时辰卦: `HEX_LIBRARY[hour % 16]`; 十二时辰: `(hour + 1) ~/ 2 % 12`
- 八宫: 宫主纯卦按爻变序列 本宫→五世→游魂→归魂, 8×8 = 64 全覆盖
- 八字对拍: node 直跑 PWA divination.js 取参考向量 (四柱/起运/大运/流年) 逐位一致
- 验证: `tool/verify_engine.dart` 断言全部锚点 (26→78 项)

## 迭代状态

- iter33 (v1.30.0): 纯 App 架构定型, 7 屏全量接通, 真实持久化 (shared_preferences)
- iter34 (v1.31.0): 八字引擎 (四柱/十神/大运流年, 分钟级节气表起运) + 梅花时间式接通屏2
- iter35 (v1.32.0): SettingsViewModel + 设置面板 (导出/导入合并/清空/重置, PWA 数据互通)
  + 大运流年展开 UI; HistoryRecord.fromJson 兼容 PWA 字符串 lines
- iter36 (v1.33.0): view/widgets/share_card.dart (PictureRecorder 纯 Canvas 渲染,
  PWA 卡面逐项对齐) + share_plus 系统分享 + 屏4 爻辞弹窗复制; +share_plus/path_provider
- iter39 (v1.35.0): 卡面渐变全屏 + 筛选/chips 动效 + service/reminder_service
  (flutter_local_notifications + timezone, 调度抽象可测, Manifest 权限/接收器) + desugaring
- 待办: 文件级导入导出 / iOS 适配 / 点通知直达起卦屏
