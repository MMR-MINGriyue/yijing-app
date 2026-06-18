# 易道 - 卦象解读 (yijing-app)

> 国风移动端 PWA - 六爻起卦 - AI 解卦 - 历史回溯

仓库地址: git@github.com:MMR-MINGriyue/yijing-app.git
HTTPS: https://github.com/MMR-MINGriyue/yijing-app

## 简介

易道 是一款专注解读卦象的移动端 PWA 应用, 6 屏设计:

1. 今日一卦 - 当前时辰对应卦象 + 解读
2. 起卦 - 三种起卦方式 (时间 / 数字 / 手动)
3. 六十四卦 - 8x2 卦象网格浏览
4. 卦辞解析 - 卦辞 / 爻辞 / 象传 三 Tab
5. 变卦推演 - 本卦 + 变卦对比 (支持左右拖动)
6. 历史记录 - 按月分组, 卦象筛选, 长按多选

## 设计特色

- 深色国风调性 (#14100b 底 + 朱红 + 暗金 + 松绿)
- 衬线字 Noto Serif SC + 37+ 自定义 keyframes
- 动爻红色高亮 + 波纹呼吸动画
- 响应式等比缩放, 支持手机/平板/桌面
- PWA 离线能力 + 图标 + 快捷方式
- URL 调试参数: ?view=gallery 平铺画廊

## 文件结构

yijing-app/
- index.html         单 HTML 主体 (4450+ 行, 含 CSS + JS)
- data.js            64 卦数据库 + YijingAPI 接口
- manifest.webmanifest   PWA 清单
- sw.js              Service Worker 离线缓存
- icons/             矢量 + PNG 多尺寸图标
- README.md          本文件

## 本地运行

# 启动本地 HTTP 服务
node -e "const h=require('http'),f=require('fs'),p=require('path');h.createServer((q,r)=>{let u=q.url.split('?')[0];f.readFile(p.join('D:/workspace/yijing-app',u),(e,d)=>{if(e){r.writeHead(404);r.end();return}r.writeHead(200,{'Content-Type':(u.endsWith('.html')?'text/html':u.endsWith('.js')?'application/javascript':u.endsWith('.webmanifest')?'application/manifest+json':u.endsWith('.png')?'image/png':u.endsWith('.svg')?'image/svg+xml':'text/plain')+';charset=utf-8'});r.end(d);});}).listen(8723,()=>console.log('http://localhost:8723'))"

打开 http://localhost:8723

## URL 调试参数

view=gallery  平铺画廊视图 (6 屏 3x2)
p9=hero       打开 01 屏 hero 全屏
p9=yao        04 屏切换到爻辞 Tab
p9=filter     06 屏按卦象筛选 (?p9=filter&hex=2 坤卦)

## 浏览器 API

window.YijingUI.refreshHero / heroByHour / forceHour
window.YijingUI.openHeroFullscreen / closeHeroFullscreen
window.YijingUI.transformGoTo / changeMonth
window.YijingUI.submitQuestion / switchTab
window.YijingStates.showEmpty / showError / showLoading / showNormal

## 技术栈

- 纯 HTML + CSS + JS (零依赖)
- Service Worker (原生)
- 6 屏 390x844 移动端画布
- 响应式 2940x1300 viewport

## License

MIT
READMEEOF\nwc -c D:/workspace/yijing-app/README.md 2>&1
