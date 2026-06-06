CACHE_NAME="fate-gear-v1"
urlsToCache=[
  "./",
  "./index.html",
  "./manifest.json",
  "./icon.svg"
]
self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE_NAME).then((c) => c.addAll(urlsToCache)));
});
self.addEventListener("fetch", (e) => {
  e.respondWith(caches.match(e.request).then((r) => r || fetch(e.request)));
});
