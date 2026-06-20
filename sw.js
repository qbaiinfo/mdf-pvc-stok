// MDF & PVC - Service Worker
const CACHE = 'mdf-pvc-v1';
const ASSETS = ['/', '/index.html', '/manifest.json'];

// Kurulum: temel dosyaları önbelleğe al
self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)));
  self.skipWaiting();
});

// Aktivasyon: eski önbellekleri temizle
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// İstekler: önce ağ, olmazsa önbellek (Supabase verileri hep canlı gelsin)
self.addEventListener('fetch', e => {
  const url = e.request.url;
  // Supabase ve CDN isteklerini cache'leme, hep ağdan al
  if (url.includes('supabase.co') || url.includes('cdn.') || url.includes('cdnjs.')) {
    return;
  }
  e.respondWith(
    fetch(e.request).catch(() => caches.match(e.request))
  );
});
