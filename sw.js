// MDF & PVC - Service Worker v2
const CACHE = 'mdf-pvc-v2';

// Kurulum: hemen aktif ol
self.addEventListener('install', e => {
  self.skipWaiting();
});

// Aktivasyon: TÜM eski önbellekleri temizle
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// İstekler: HER ZAMAN ağdan al, böylece güncel sürüm hep gelir
self.addEventListener('fetch', e => {
  e.respondWith(
    fetch(e.request).catch(() => caches.match(e.request))
  );
});
