# 易道 · 纯 App (yijing-flutter)

> 国风易经原生 App — Flutter MVVM — 7 屏全量 — 真实持久化

纯 Flutter 原生 App 主线 (v1.30.0, iter33 起)。PWA (仓库根目录) 保留为设计基准与数据源;
本目录为唯一交付形态, 不再依赖 WebView/Capacitor。

架构设计详见 **[ARCHITECTURE.md](ARCHITECTURE.md)**。

## 屏幕地图 (5 Tab + 2 推入路由)

| 入口 | 屏 | 说明 |
|---|---|---|
| 今日 (tab) | 屏1 今日一卦 | 时辰卦 (hour%16) + 干支问候 (十二时辰) + 刷新轮换 64 卦 + 最近占卜 2 条 |
| 起卦 (tab) | 屏2 起卦 | 问题输入 + 方向 chips + 易经三式 (数字/蓍草/铜钱) + 推演动画 + 落历史; 更多占法子页: 小六壬 (农历真实起课) / 梅花易数 (时间式+数字式) / 八字排盘 (四柱十神大运, iter34) |
| 卦库 (tab) | 屏3 六十四卦 | 网格 + 京房八宫筛选 + 搜索 (卦名/拼音/卦序) |
| push | 屏4 卦辞解析 | 卦辞/爻辞/象传 三 Tab + 收藏 (持久化) + 直达屏5 + 爻辞弹窗复制 + 分享卡 (PNG 系统分享) |
| push | 屏5 变卦推演 | 本卦/变卦/互卦 + 体用生克 + 点击爻切换动爻 |
| 历史 (tab) | 屏6 历史记录 | 月份导航 + 卦象/方向/占法三层筛选 + 搜索 + 排序 + 统计 |
| 我的 (tab) | 屏7 我的 | 总数/连续天数/收藏 始于日期 + 收藏横滑 + 方向/占法分布条形图 + ⚙ 设置 |

## 分层

```
app/app_shell.dart      5 Tab Hub (IndexedStack 保留各屏状态) + push 路由接线
view/                   7 屏纯 UI + widgets/hex_glyph.dart (卦象绘制, 上爻在上)
viewmodel/              ChangeNotifier × 7 (状态+意图, 可单测)
core/                   纯 Dart 引擎 (零 Flutter 依赖, dart run 可验)
  yi_calendar           干支历 (JDN/纪日/纪年/月干支/十二时辰)
  lunar_calendar        农历 1900-2100 (PWA 紧凑表逐位对齐)
  solar_terms           分钟级节气表 1901-2100 (12 节, 机械提取)
  cast_engine           起卦: 铜钱/蓍草/数字 + 文本定数 (FNV-1a+DJB2, JS 语义仿真)
  bazi                  八字: 四柱/藏干/十神/五行/日主强弱
  dayun                 大运流年: 3日折1岁起运 + 8步大运 + 流年断语
  meihua                梅花易数: 时间式/数字式/掷骰
  palace                京房八宫 (8×8 全覆盖)
  xiaoliuren            小六壬 (农历月日时 + 经典路径法)
data/                   hex_library (64 卦全数据) + repositories
  history_store         抽象接口 + 内存实现 (纯 Dart)
  history_store_prefs   shared_preferences 实现 (仅 main 引入)
  favorites_store       收藏 (同上双实现)
model/                  Hex / HistoryRecord (JSON 容错序列化) / CastResult
```

依赖方向单向: view → viewmodel → core/data → model。
核心层/data 不 import Flutter, `dart run tool/verify_engine.dart` 直接验证 59 项。

## 与 PWA 引擎对齐 (逐位一致)

- 干支纪日锚点 `(JDN-11)%60` (JD 2458511 = 甲子日); 纪年立春界 1984=甲子
- 文本定数: JS 三语义精确仿真 — Int32 有符号异或 / double 乘 53 位舍入 / `>>>0`
  (验证向量: '近期事业运筹方向' → [4797, 2131])
- 时辰卦 `HEX_LIBRARY[hour%16]`; 时辰映射 `(hour+1)~/2%12`
- 农历春节锚点: 2024-02-10 / 2025-01-29 = 正月初一
- 八宫: 宫主纯卦爻变序列 本宫→五世→游魂→归魂 (乾宫 = 乾姤遯否观剥晋大有)

## 验证

```
flutter analyze                 # 0 issue
flutter test                    # 108 项 (引擎/ViewModel/壳层/动效组件/提醒调度)
dart run tool/verify_engine.dart  # 78 项 (历法/农历/节气/起卦/八字/大运/梅花/八宫/小六壬)
flutter build apk --debug       # CI 自动构建
```

## 迭代状态

- **iter33 (v1.30.0)**: 纯 App 架构定型 — 7 屏全量接通, 真实持久化 (shared_preferences),
  核心引擎层移植 (干支历/农历/起卦/八宫/小六壬), CI test 步骤 pipefail 修复
- **iter34 (v1.31.0)**: 八字排盘接通屏2 (四柱/藏干十神/五行/强弱/起运/8步大运,
  分钟级节气表), 梅花时间式接通; 全引擎与 PWA node 对拍逐位一致
- **iter35 (v1.32.0)**: 设置面板 (屏1/屏7 ⚙: 导出剪贴板 / 导入合并去重 / 清空 / 重置,
  双击确认, 数据格式与 PWA 导出互通) + 八字大运点击展开流年断语
- **iter36 (v1.33.0)**: 屏4 分享卡 (PWA 同款 720×1040 卡面: 渐变/金框/卦象/动爻标注/
  卦辞/所问/干支落款, PictureRecorder 渲染 PNG → share_plus 系统分享) + 爻辞弹窗复制
- **iter38 (v1.34.0)**: 动效体系 YiMotion (easeOutExpo 曲线/全站按压 0.96/首页四段 stagger/
  动爻呼吸动画/六爻逐爻点亮推演动画/收藏弹跳/页面转场) + 屏5 长按爻辞弹窗; Android 模拟器实测通过
- **iter39 (v1.35.0)**: 卡面渐变全屏铺开 + 卦库宫筛选网格过渡动画 + 历史筛选 chips 动效 +
  每日占卜提醒 (flutter_local_notifications 定时通知, 设置面板开关/时间, 重启自动恢复,
  模拟器实测 08:00 整点弹出)
- 待办: 文件级导入导出 / iOS 适配 / 提醒点通知直达起卦屏
