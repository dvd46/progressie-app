const CACHE = 'gymloft-v1';
const ASSETS = [
  '/',
  '/index.html',
  '/assets/gymloft-logo.png',
  '/assets/badge-gold.svg',
  '/assets/badge-silver.svg',
  '/assets/badge-bronze.svg'
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(keys =>
    Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
  ));
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  // Supabase en externe API's altijd via netwerk
  if (e.request.url.includes('supabase') || e.request.url.includes('strava')) return;
  e.respondWith(
    fetch(e.request).catch(() => caches.match(e.request))
  );
});
