# 易道 (yijing-app) — 项目长期记忆

## 项目定位

- 国风易经 PWA，单 HTML + 零运行时依赖，7 屏移动优先（app ≤900 / landscape / grid / fit 四态）
- 64 卦完整数据层（HEX_LIBRARY + HEX_EXTRA + YijingEngine 起卦推演）
- 四大占法：易经（数字/蓍草/铜钱）、八字（含大运流年/节气精确化）、小六壬、梅花易数
- v1.23.0 / 26 轮迭代；sw.js 缓存策略 app-shell cache-first

## 设计系统要点

- 主色：墨 #14100b / 朱砂 #d04d3e / 暗金 #c9a876 / 松绿 #5ba88a
- 65 个 `:root` CSS 变量零偏移，圆形元素统一 border-radius: 50%
- 三层渐变 token：--grad-card / --grad-sheet / --grad-overlay
- 移动端：100dvh + scroll-snap-x + safe-area + 48dp 触控 + dvh

## 移动优先四态布局模型（v1.22 完整）

- **竖屏手机 (≤900px)**：app 模式, 7 屏横向 scroll-snap 轮播, 每屏全宽, 100dvh 全屏
- **横屏矮屏 (orientation: landscape + max-height: 520px)**：多列网格 (flex-wrap: wrap), 每屏 390×358px 保持竖屏比例 + 边框圆角, 视口纵向滚动; hero 紧凑至 200px (隐藏 desc/label/meta/en, 卦名 26px)
- **平板/小桌面 (901–1599px)**：grid 模式, 390×844 原尺寸换行网格 + canvas-title
- **大桌面 (≥1600px)**：fit/canvas 模式, 2940×1300 设计画廊等比缩放
- **正方形视口**：orientation: square 不触发 landscape media query, 保持竖屏模式

## 设计打磨教训（重要 — 10 条踩坑记录）

1. **flex shrink 子项坍塌陷阱**：任何在 `.content` flex column 下的子项若没有 `flex-shrink: 0`，即使有 padding 也会被父级压成 padding-only 高度（hex-filter-row 12px / chip 36px → 视觉"扁条"）。修复一律加 flex-shrink: 0
2. **屏1首屏 hero 紧凑化**：hero-card 在 390×844 视口占 409px 会挤掉快捷入口和最近占卜；hero-card 加 flex-shrink:0 + 紧凑 padding/gap，配合 auto-scroll 让「最近占卜」完整可见（scrollTop = recBottom - tabTop + 12）
3. **phone 容器选择器**：屏1今日一卦的 phone div 没有 id（只有 phoneDivination/phoneDetail/phoneMe），需用 child 反查（如 `el.closest('.content')`）而不是 `querySelector('#xxx .content')`
4. **JS 字符串拼接换行安全**：模板字符串换行时务必保留 `+`，误改成 `;` 会导致语法报错（最近占卜 innerHTML 那段差点踩坑）
5. **横屏适配决策**：手机横屏不能复用 app 模式（每屏全宽 100% 让内容居中失真+高度极矮），正确做法是新增独立 landscape media query 切到多列网格
6. **CSS 后定义胜出陷阱**：两个 media query 同特异性同时命中时（如横屏 844x390 同时满足 orientation:landscape max-height:520 和 max-width:900 max-height:740），后定义的 media query 胜出。横屏规则必须放在矮屏 block 之后才能生效
7. **`[hidden]` 默认 display:none 被覆盖**：HTML5 `[hidden]` 属性的默认 display:none 会被元素自身的 `display:flex/grid` 覆盖。设置 hidden=true 后元素仍 visible。修复：显式声明 `.xxx[hidden] { display: none !important }`
8. **gotoScreen 是 0-based**：YijingUI.gotoScreen(N) 跳到第 N+1 屏，gotoScreen(1)=起卦屏2，gotoScreen(2)=64卦屏3
9. **transform 100% 参考 element 自身 box**：translateX(calc(-100% / 3)) 是 element 自身宽度的 1/3。如果想相对父级, 用 `calc(-33.333% of parentWidth)` 需要明确
10. **slider 300% 必须 flex-shrink: 0**：父级 flex item 默认会压缩子项回到 100%, slider 撑不到 300% 就被截回 card 视口宽

## 数据层

- HEX_LIBRARY / HEX_EXTRA：64 卦全部爻辞+大象传+卦辞
- YijingEngine：铜钱/蓍草/数字起卦 + 体用生克 + 互卦
- YijingDivination（divination.js）：八字 LunarCalendar / BaZi / DaYun / XiaoLiuRen / MeiHua
- YijingCalendar / PreciseTerms：JDN 干支历，1901-2100 精确节气
- terms.js：分钟级节气表（generator: .pwtest/.termgen/gen.js, 数据源 lunar-typescript 1.7.3）

## 核心交互入口

- 屏1：今日一卦 + 快捷入口 + 最近占卜（auto-scroll 横屏跳过）
- 屏2：起卦 + 问题输入 + 方向标签 + 更多占法子页 (iter25 分页)
- 屏3：64 卦网格 + 宫筛选
- 屏4：卦辞/爻辞/象传 三 Tab + 收藏
- 屏5：本卦/变卦/互卦 + 体用生克 + 点击爻切换
- 屏6：历史按月分组 + 三层筛选 (卦象/方向/占法) + 搜索 + 排序 + 设置 (导入导出/清空/重置)
- 屏7：我的（统计 + 收藏横滑 + 方向/方式分布条形图 + 历史/64卦入口）

## 调试与测试

- `.pwtest/check-syntax.js` Node 内联脚本 new Function 语法冒烟
- `.pwtest/iter*.js` Playwright + Edge 渠道断言；iter17-iter25 共 208 项回归全过
- 测试教训：跨午夜日期断言必须用 Date.now() 动态推；localStorage.clear() 必须在 page.goto 之后；统计截图用 getImageData 像素亮度；点击元素前 hidden 元素不可点需先点入口（iter25 子页）

## 分发

- APK：`.github/workflows/android-build.yml` 推 main 自动出 debug APK，attach 到 GitHub Release
- 网页版：GitHub Free 私有仓库不支持 Pages；如需公开可 Cloudflare Pages
- 本地：`node -e` 一行起 8723 端口 HTTP 服务