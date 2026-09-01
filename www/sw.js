/* ===========================================
 * 易道 PWA Service Worker
 * 缓存策略：app shell cache-first，导航/字体 cache-first with network fallback
 * =========================================== */

const CACHE_VERSION = 'yijing-v1.14.0';
const CACHE_RUNTIME = 'yijing-runtime-v1';
const CACHE_ASSETS  = [
  './',
  './index.html',
  './data.js',
  './manifest.webmanifest',
  './icons/icon.svg',
  './icons/icon-192.png',
  './icons/icon-512.png',
  'https://fonts.googleapis.com/css2?family=Noto+Serif+SC:wght@500;700&family=Noto+Sans+SC:wght@300;400;500&family=Inter:wght@400;500;600&display=swap'
];

self.addEventListener('install', (event) => {
  console.log('[SW] Install:', CACHE_VERSION);
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) => {
      // 字体/CSS 可能因网络问题失败，使用 addAll 容错
      return Promise.all(
        CACHE_ASSETS.map((url) =>
          cache.add(url).catch((e) => console.warn('[SW] cache.add failed:', url, e))
        )
      );
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  console.log('[SW] Activate');
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.filter((k) => k !== CACHE_VERSION && k !== CACHE_RUNTIME)
            .map((k) => { console.log('[SW] Delete cache:', k); return caches.delete(k); })
      )
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);

  // 跳过 chrome-extension / 非 http 协议
  if (!url.protocol.startsWith('http')) return;

  // 同源 GET 资源：cache-first
  if (url.origin === self.location.origin) {
    event.respondWith(cacheFirst(request));
    return;
  }

  // 跨域（Google Fonts）：stale-while-revalidate
  event.respondWith(staleWhileRevalidate(request));
});

async function cacheFirst(request) {
  const cache = await caches.open(CACHE_VERSION);
  const cached = await cache.match(request, { ignoreSearch: false });
  if (cached) {
    return cached;
  }
  try {
    const response = await fetch(request);
    if (response && response.status === 200 && response.type === 'basic') {
      cache.put(request, response.clone());
    }
    return response;
  } catch (e) {
    // 离线兜底：返回 index.html (SPA fallback)
    const fallback = await cache.match('./index.html');
    if (fallback) return fallback;
    return new Response('Offline', { status: 503, statusText: 'Offline' });
  }
}

async function staleWhileRevalidate(request) {
  const cache = await caches.open(CACHE_RUNTIME);
  const cached = await cache.match(request);
  const networkPromise = fetch(request).then((response) => {
    if (response && response.status === 200) {
      cache.put(request, response.clone());
    }
    return response;
  }).catch(() => null);
  return cached || (await networkPromise) || new Response('Offline', { status: 503 });
}

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  if (event.data && event.data.type === 'GET_VERSION') {
    event.ports[0] && event.ports[0].postMessage({ version: CACHE_VERSION });
  }
});
