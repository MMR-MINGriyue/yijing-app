# 易道 - 卦象解读 (yijing-app)

> 国风移动端 PWA - 六爻起卦 - AI 解卦 - 历史回溯

仓库地址: git@github.com:MMR-MINGriyue/yijing-app.git
HTTPS: https://github.com/MMR-MINGriyue/yijing-app

> **纯 App 主线 (iter33, v1.30.0)**: Flutter 原生 App 已成为唯一交付形态 —
> 7 屏全量 + 真实持久化, 见 [`yijing-flutter/`](yijing-flutter/README.md) 与
> [`yijing-flutter/ARCHITECTURE.md`](yijing-flutter/ARCHITECTURE.md)。
> 本 README 描述的 PWA 保留为设计基准与数据源, 不再打包分发。

## 简介

易道 是一款专注解读卦象的移动端 PWA 应用, 7 屏设计:

1. 今日一卦 - 当前时辰对应卦象 + 解读
2. 起卦 - 三种起卦方式 (数字 / 蓍草 / 铜钱), 可写入历史; 更多占法板块 (子页): **八字解析** (四柱/五行/十神/大运流年, 农历 1900-2100, 节气精确化), **小六壬** (时辰起课六宫落宫), **梅花易数** (时间/数字/掷骰三式起卦, 复用体用生克推演), 结果统一入历史并支持占法筛选
3. 六十四卦 - 8x2 卦象网格浏览
4. 卦辞解析 - 卦辞 / 爻辞 / 象传 三 Tab
5. 变卦推演 - 真实本卦/变卦/互卦/体用生克计算 (支持左右拖动 / 点击爻切换动爻)
6. 历史记录 - 按月分组, 卦象筛选, 长按多选, 真实起卦记录落盘 localStorage

## 设计系统

- **深色国风调性**: `#14100b` 底 + 朱红 + 暗金 + 松绿
- **Token 零偏移** (v1.16): CSS 内硬编码颜色全部归一至 `:root` token (审计脚本实测 0 处游离 hex); 新增语义渐变 token 三层深度 `--grad-card` (卡片) / `--grad-sheet` (弹层更深) / `--grad-overlay` (全屏最深) + `--grad-cinnabar`(-v), 高亮白字 `--text-on-fill`, 朱红深端 `--cinnabar-deeper`; 5 处近似色收敛至最近 token (Δ≤15/255 视觉无感); 圆形元素统一 `border-radius: 50%` (替代手写半宽半径)
- **首屏可见性优化** (v1.20): 屏6 三行 `.hex-filter-row` 加 `flex-shrink: 0` 防父级 flex 列压扁（容器从 12px 恢复到 48px, chips 36px 完整显示）; 屏1 hero-card 紧凑化 (padding 24→16, gap 16→10, hero-body gap 24→18, hero-desc line-clamp 2 行) 省 ~55px 高度, 并在入场 stagger 完成后 auto-scroll 让「最近占卜」两卡完整可见于首屏 (scrollTop 由 `adjustHomeScroll()` 动态计算 = recBottom - tabTop + 12)
- **横屏矮屏适配** (v1.21): 新增 `@media (orientation: landscape) and (max-height: 520px) and (max-width: 1200px)` —— 手机横屏 (iPhone 12 844×390 / SE 667×375) 自动从「全屏单屏轮播」切换到「多列网格 + 纵向滚动」, 每屏保持 390px 竖屏原比例 + 边框圆角 (恢复画廊观感); 844 宽视口可并排 2-3 屏, 667 宽自动单列; app-pager / app-hint / scroll-snap 全部关闭; 竖屏/平板/正方形视口走原模式, 互不干扰; viewport 纵向 scrollHeight 1652px / 7 屏全部可达
- **屏2「更多占法」分页化** (v1.22): 屏2 默认只显示「请选择起卦方式」3 卡 + 一个金红渐变「更多占法 ›」入口卡, 点击入口进入独立子页 (返回行 + 3 张占法大卡: 八字/小六壬/梅花); 减少屏2 scrollHeight 5380→更紧凑; CSS 关键修复: `[hidden]` 默认 display:none 会被 `.method-list { display:flex }` 覆盖, 显式 `.method-list[hidden] { display: none !important }` 等保证 hidden 生效; 横屏 hero 进一步紧凑 (200px, 从 324→200px): 隐藏 hero-desc / hex-trigram-label / hex-meta / 英文副名, 卦名 36→26px, 快捷入口圆 44→32px; adjustHomeScroll 横屏跳过, 首屏保持 hero 可见; 横屏 media query 移到矮屏 block 之后避免被覆盖
- **屏 5 变卦推演卡片修复** (v1.23): 修复 3 个 view 全部挤在 transform-card 内 (本卦/变卦/推演徽标文字重叠) 的设计 bug — slider 改 `width: 300%` + `flex-shrink: 0` 防父级压缩, 每个 view 改 `width: calc(100% / 3)` + `min-width: 0`, 配合 transform `translateX(calc(-100% / 3))` 切换 (本卦/变卦/推演每次只显示 1 个); transform-card 加 `flex-shrink: 0` 防 flex 列压缩 (view 高度 259px), 去掉 `justify-content: center` 让 slider 从 card content left 开始; 推演视图 6 行 diff rows (上卦/下卦/动爻/互卦/体用/吉凶) 居中显示无溢出
- **屏 4 卦辞解析 hero 紧凑化** (v1.24): detail-hero 高度 277→210px (-67px) — padding 28/24→16/20, gap 14→8, hex-mini 60×84→54×66, 卦名 28→24px; tabs 位置上移 67px (y=435→368), 「本卦卦辞」+「个性化建议」两卡首屏完整可见 (之前需滚动 250px 才能看到建议); content scrollHeight 1034→967
- **屏 6 历史搜索关键字高亮** (v1.25): 屏6 搜索框 input 时匹配的 hist-card 添加 `.search-hit` class (左侧朱砂渐变竖条) + 匹配关键字用 `<mark class="hist-mark">` 金色背景包裹高亮; 同步清理首次 escape 后插入 mark 的安全策略 (双层 escapeHtml 防止 XSS); 改 `renderOne()` 接收 `histKeyword` 在 name/question 文本中插入高亮; 搜索清空时 mark + search-hit 全部消失
- **移动优先三态布局**:
  - `app` 模式 (≤900px): 6 屏横向 `scroll-snap` 轮播, `100dvh` 全屏, 内容/顶栏/底栏限制最大 460px 居中, 防止平板竖屏把 390px 设计稿拉成扁条
  - `grid` 模式 (901–1599px): 390×844 原尺寸换行网格, 纵向滚动, 保证真实可读性
  - `fit` / `canvas` 模式 (≥1600px): 2940×1300 设计画廊等比缩放
  - **横屏矮屏** (v1.21): orientation: landscape + max-height 520px → 多列网格 + 纵向滚动, 每屏 390×358 保持原比例
  - 支持 URL 参数 `?view=app|grid|fit|canvas` 强制切换
- **安全区适配**: 使用 `env(safe-area-inset-*)` 避开刘海/圆角/Home Indicator; 高度使用 `100dvh` 避免移动端工具栏跳动
- **触控规范**: 最小触控区 `--tap-min: 44px`; 禁用双击缩放 300ms 延迟与灰色点击高亮
- **无障碍对比度**: 小字内容统一使用 `--text-tertiary` (4.66:1) 与 `--cinnabar-text` (4.70:1), 满足 WCAG AA; 原 `--text-faint` 降级为装饰/禁用态
- **触控目标达标** (v1.14): 筛选 chips 28→36px、`section-link` 文字链接以负 margin padding 扩大命中区至 39px, 全部可点元素实测 ≥36px
- **全局按压反馈** (v1.14): chips/方向标签/方法卡/历史卡/卦卡/tab 等 11 类可点元素统一 `:active { scale(0.96) }` 即时确认感, 触摸/点击均有缩放反馈; v1.17.1 补齐 icon-btn/detail-tab (0.88) 与 hero/transform 大卡 (0.985) 两档力度, 交互反馈覆盖率审计脚本实测无缺口
- **排版**: 中文优先回退栈 (`PingFang SC` / `Microsoft YaHei` / `-apple-system`); 字体令牌 `--font-serif` / `--font-sans` / `--font-num`; 字号下限 11px, CJK 行高 1.75
- 动爻红色高亮 + 波纹呼吸动画
- **入场编排** (v1.17): 01 首屏四段式 stagger (问候 0.03s → 今日一卦 0.14s → 快捷入口 0.26s → 最近占卜 0.38s, quick-item 内部再递进), 全站 40+ keyframes 统一 ease-out-expo 曲线; `prefers-reduced-motion` 一键归零
- **收藏 pop 反馈** (v1.17): 屏4 收藏切换 scale(1.34)+rotate(-10°) 弹跳确认, 支持连续点击重触发; 已删除从未使用的 countUp 死 keyframe
- **真实导航**: 底部 tabbar (今日/六十四卦/起卦/我的) 在 App 模式驱动横向轮播、grid 模式滚动定位、画廊模式闪烁提示目标屏, 高亮随当前屏同步
- **PWA 深链**: manifest shortcuts `#start` / `#today` / `#history` / `#me` 已接通 hash 导航
- **交互闭环**: 屏4「查看变卦推演」直达屏5, 屏1「查看全部」直达历史, 收藏按钮 localStorage 持久化 (`yijing.favHexes`)
- **屏6 全动态统计与检索**: 统计卡(总次数/本周/收藏)与顶栏总数由真实数据实时计算; 搜索栏为真实输入框(按卦名/问题/日期过滤当月记录); ⇅ 排序按钮在「最新在前 / 最早在前」间切换
- **⚙ 设置面板**: 屏1/屏7 齿轮按钮弹出底部抽屉, 支持导出历史数据(JSON 下载)、导入合并(自动去重, 含收藏并集)、二次确认清空本地历史与重置为示例数据(收藏不受影响)
- **数据健壮性** (v1.15): 历史卡片渲染三处 `lines` 缺字段容错 (导入的畸形/旧格式记录按全阳爻渲染不崩溃); 屏1 最近占卜过滤缺 name/question 的记录; 坏 JSON 存储自动回退空数组; 问题字段 escapeHtml 防注入 (XSS payload 实测不执行)
- **头部分享**: 屏4 顶栏 ↗ 与底部「生成分享卡」行为一致
- **爻辞弹窗数据驱动**: 05 屏点击任意爻行(本卦/变卦)弹出对应真实爻辞, 事件委托绑定重渲染不失效; 支持 Esc 关闭 / 复制爻辞 / Web Share 分享(不支持时降级复制)
- **无障碍**: 6 屏 aria-label, tabbar tablist/tab 语义 + 键盘 Enter/Space 激活, hero 全屏 role=dialog + Esc 关闭 + 焦点管理
- PWA 离线能力 + 图标 + 快捷方式

## 数据层 (data.js)

- HEX_LIBRARY: 64 卦完整数据 (卦名/卦象/爻位/六爻爻辞+白话解读), 爻位经脚本校验与先天卦象一致
- HEX_EXTRA: 每卦的卦辞原文 / 大象传 / 全屏 hero 一句话解读, 加载时自动合并进 HEX_LIBRARY
- 今日一卦 hero 刷新可轮换全部 64 卦, 卦辞与解读跟随真实数据
- 04 卦辞解析屏按 HEX_LIBRARY 动态渲染: 03 屏卦卡点击 / 06 屏历史卡点击 / URL hex= 参数均可打开对应卦
- 05 屏变卦推演: 按真实动爻计算变卦, 含互卦、体卦/用卦、五行生克; 点击任意爻可动态切换动爻
- **02 屏起卦闭环**: 选择起卦方式 → 推演中动画 → 生成卦象 → 同步 04/05 屏 → 写入 localStorage 历史; 方向标签可点击切换并记忆上次选择(radiogroup 语义); **iter25 起卦分页**: 屏2 默认只展示易经三式 + 「更多占法 ›」入口卡, 点击进入子页展示八字/小六壬/梅花三式 + 返回行
- **分享卡**: 04 屏顶栏 ↗ / 底部按钮生成 PNG 分享卡, 页脚含干支纪年月日 + 公历落款
- 06 屏历史记录: 本地起卦数据持久化, 月份导航随真实数据动态扩展, 长按删除同时生效于本地存储; 统计卡/搜索/排序全动态; 按卦象筛选 + 方向筛选(动态 chips, 可复合 AND, 月切换自动重置)
- **时间真实性**: 状态栏 6 屏实时时钟(30s 刷新); 01 屏日期行显示真实干支(年/月/日) + 公历(儒略日换算, 锚点 JD 2458511=甲子日; 月干支按节气界+年上起月法, 2024-2030 精度±1天); 历史记录带完整时间戳 ts, 排序与「本周」统计按真实时间计算
- **最近占卜动态化**: 01 屏最近卡由真实历史前 2 条渲染, 点击直达 04 屏解析; 卦卡(03 屏)/历史卡(06 屏)点击后同样自动跳转到解析屏, 04 屏顶栏 ← 返回来路屏
- **07 屏「我的」个人页**: 统计概览(起卦总数/连续天数/收藏数 + 始于日期), 收藏卦横滑列表(点击直达解析), 问卦方向与起卦方式分布条形图(方向条点击跳 06 屏并自动应用方向筛选), 历史记录与六十四卦快捷入口; 底部 tab「我的」与深链 #me 直达, ⚙ 设置面板双入口共用
- 全站卦象朝向修复: 画廊 / 历史 / 详情 / hero 均按「上爻在上、初爻在下」正确绘制

## 文件结构

yijing-app/
- index.html         应用壳层 (CSS + HTML 结构 + 模块引用)
- data.js            64 卦完整数据库 + 卦辞/大象传 + YijingAPI 接口
- terms.js           分钟级节气表 (自动生成, 1901-2100)
- divination.js      更多占法: 八字/小六壬/梅花易数
- js/                应用逻辑模块 (iter29 移动 App 架构分层拆分)
  - 00-core.js        核心层: escapeHtml / HEX_DRAW_ORDER / YijingCalendar / YijingHistory / 时钟
  - 01-init.js        初始化: 屏1 最近占卜 / 屏3 网格 / 屏2 方法+方向 / 屏6 分组注入
  - 02-home-cast.js   屏1 今日一卦 (时辰卦/问候) + 屏3 搜索过滤
  - 03-transform.js   屏5 变卦推演 (滑动切换 + 真实变卦计算)
  - 04-history.js     屏6 历史 (月份/状态/筛选/排序/搜索/统计) + 屏2 起卦闭环 + 更多占法 + 输入
  - 05-detail.js      屏4 卦辞解析 (Tab/动态渲染) + 屏5 爻辞 Modal
  - 06-layout-nav.js  布局层: 四态响应式 / 屏框 / 缩放 / App 轮播 / tabbar 导航
  - 07-extra.js       工具层: 杂项接线 / 分享卡 / 设置面板 / 屏7 我的 / 骨架屏 / URL 参数 / SW 注册
- manifest.webmanifest   PWA 清单
- sw.js              Service Worker 离线缓存 (app-shell cache-first)
- icons/             矢量 + PNG 多尺寸图标
- .github/workflows/android-build.yml   Android APK 自动构建工作流
- .pwtest/           Playwright 迭代测试脚本 (开发用, 不参与运行)
- README.md          本文件

## 架构 (iter29 移动 App 分层)

```
┌─ 应用壳层 index.html (CSS + HTML + 模块引用)
├─ 数据层  data.js / terms.js / divination.js (64 卦库 / 节气表 / 占法引擎)
├─ 核心层  js/00-core.js (干支历 / 历史存储 / 共享常量)
├─ 屏控制器 js/01-init · 02-home-cast · 03-transform · 04-history · 05-detail (7 屏)
├─ 布局层  js/06-layout-nav.js (四态响应式 + tabbar + 路由)
└─ 工具层  js/07-extra.js (分享 / 设置 / 骨架 / SW)
加载顺序: data.js → terms.js → divination.js → 00-core → 01-init → ... → 07-extra
(跨文件共享常量通过 window 挂载, 如 window.HEX_DRAW_ORDER)
```

## 本地运行

# 启动本地 HTTP 服务
node -e "const h=require('http'),f=require('fs'),p=require('path');h.createServer((q,r)=>{let u=q.url.split('?')[0];f.readFile(p.join('D:/workspace/yijing-app',u),(e,d)=>{if(e){r.writeHead(404);r.end();return}r.writeHead(200,{'Content-Type':(u.endsWith('.html')?'text/html':u.endsWith('.js')?'application/javascript':u.endsWith('.webmanifest')?'application/manifest+json':u.endsWith('.png')?'image/png':u.endsWith('.svg')?'image/svg+xml':'text/plain')+';charset=utf-8'});r.end(d);});}).listen(8723,()=>console.log('http://localhost:8723'))"

打开 http://localhost:8723

## 分发 (安卓 APK)

仓库保持私有 (GitHub Free 计划不支持私有仓库的 Pages, 无网页版):

1. 推送到 `main` 分支自动触发 `.github/workflows/android-build.yml` (含 www/ 与根目录哈希一致性守卫 + 内联脚本语法冒烟检查)
2. Actions 运行页下载 `yijing-debug` 构建产物, 解压取 APK 传输安装
3. 如后续需要网页版, 可将仓库转公开 (Pages 自动可用) 或迁移 Cloudflare Pages (免费支持私有仓库)

> PWA 注意: HTTPS 下 Service Worker 与 `manifest` 才能完整生效; 本地 http://localhost 与 APK 内嵌 WebView 不受影响。

## URL 调试参数

view=canvas    强制桌面设计画廊视图(默认在桌面端生效)
view=fit       强制设计画廊视图(与 canvas 相同)
view=app       强制移动端 App 模式(即使在大窗口)
view=grid      强制平板/小桌面网格视图 (390px 原尺寸换行)
view=gallery   平铺画廊视图 (6 屏 3x2, 旧版兼容)
p9=hero        打开 01 屏 hero 全屏
p9=yao         04 屏切换到爻辞 Tab
p9=filter      06 屏按卦象筛选 (?p9=filter&hex=2 坤卦)
hex=31         04 屏直接渲染第 31 卦 (咸卦) 的卦辞解析
hex=3&moving=1,4   05 屏直接推演第 3 卦、动爻为六二与九五

## 浏览器 API

window.YijingUI.refreshHero / heroByHour / forceHour
window.YijingUI.openHeroFullscreen / closeHeroFullscreen
window.YijingUI.transformGoTo / setTransform / getTransform
window.YijingUI.submitQuestion / getQuestion / setQuestion
window.YijingUI.switchTab
window.YijingUI.openDetail(hexNo, { question, moving, method, summary })
window.YijingUI.castHex(methodId)          // 触发 02 屏起卦流程
window.YijingUI.refreshHistory / changeMonth / refreshRecent / refreshMe / openSettings / filterByDirection
window.YijingHistory.add / all / removeMany
window.YijingStates.showEmpty / showError / showLoading / showNormal
window.yijingToast(msg)                   // 全局轻提示
window.YijingCalendar.jdn/ganzhiDay/ganzhiYear/ganzhiMonth/gregorian  // 干支历法
window.YijingUI.adjustHomeScroll          // 屏1首屏 auto-scroll (v1.20)

## 深链

#today    打开屏1 今日一卦
#start    打开屏2 起卦
#history  打开屏6 历史记录
#me       打开屏7 我的
(与 manifest shortcuts 对应, hashchange 实时响应)

## 技术栈

- 纯 HTML + CSS + JS (零运行时依赖)
- Service Worker (原生)
- 6 屏 390×844 移动端画布 + 桌面 2940×1300 设计画廊
- 移动优先响应式: `100dvh` / `scroll-snap-x` / `safe-area-inset` / `dvh`

## License

MIT
