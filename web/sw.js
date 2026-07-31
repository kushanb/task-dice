'use strict';

// Offline-first service worker for TaskDice.
//
// Flutter no longer ships a caching service worker — as of 3.29 the generated
// flutter_service_worker.js is a stub that unregisters itself — so the app
// brings its own.
//
// The block below is rewritten by tool/build_web.dart after `flutter build
// web`: BUILD_ID becomes the build's content hash and RESOURCES becomes a
// path -> hash map of everything in build/web. The checked-in values are the
// "not stamped yet" state, which makes this worker deliberately inert so a
// `flutter run -d chrome` session is never served stale bytes.

// build:config-start
const BUILD_ID = 'dev';
const RESOURCES = {};
// build:config-end

const CACHE = 'taskdice-app';
const SHELL = 'index.html';

/** Bookkeeping entry holding the RESOURCES map the cache was last filled from. */
const MANIFEST_KEY = '__sw_manifest__';

const STAMPED = BUILD_ID !== 'dev';

/** Resolves an app-relative path against the worker's scope. */
function scoped(path) {
  return new URL(path, self.registration.scope).toString();
}

/** Inverse of `scoped`: the in-scope path for a URL, or null if out of scope. */
function unscoped(url) {
  const scope = self.registration.scope;
  return url.startsWith(scope) ? url.slice(scope.length) : null;
}

self.addEventListener('install', (event) => {
  event.waitUntil(precache());
});

async function precache() {
  if (!STAMPED) {
    // An unstamped worker has nothing to serve. Get out of the way so the page
    // goes straight to the network.
    await self.registration.unregister();
    return;
  }

  const cache = await caches.open(CACHE);
  const previous = await readManifest(cache);

  // Evict anything this build no longer ships. That includes runtime-cached
  // entries such as the CanvasKit payload, which is deliberately not in
  // RESOURCES (see tool/build_web.dart) — dropping it is what stops a stale
  // engine surviving an upgrade. It is re-cached on the next render.
  for (const request of await cache.keys()) {
    const path = unscoped(request.url);
    if (path !== MANIFEST_KEY && !(path in RESOURCES)) {
      await cache.delete(request);
    }
  }

  // Re-fetch only what actually changed; identical files are already cached
  // under the same URL with the right bytes.
  const stale = [];
  for (const [path, hash] of Object.entries(RESOURCES)) {
    if (previous[path] !== hash || !(await cache.match(scoped(path)))) {
      stale.push(path);
    }
  }

  await Promise.all(stale.map((path) => refetch(cache, path)));
  await cache.put(
    scoped(MANIFEST_KEY),
    new Response(JSON.stringify(RESOURCES), {
      headers: { 'Content-Type': 'application/json' },
    })
  );
}

async function refetch(cache, path) {
  // `cache: 'reload'` bypasses the HTTP cache so a deploy can't be masked by a
  // stale intermediary copy.
  const response = await fetch(new Request(scoped(path), { cache: 'reload' }));
  if (!response.ok) {
    throw new Error(`Precache failed for ${path}: ${response.status}`);
  }
  await cache.put(scoped(path), response);
}

async function readManifest(cache) {
  const stored = await cache.match(scoped(MANIFEST_KEY));
  if (!stored) {
    return {};
  }
  try {
    return await stored.json();
  } catch (_) {
    return {};
  }
}

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      for (const name of await caches.keys()) {
        if (name !== CACHE) {
          await caches.delete(name);
        }
      }
      await self.clients.claim();
    })()
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (!STAMPED || request.method !== 'GET') {
    return;
  }
  if (unscoped(request.url) === null) {
    return; // cross-origin or outside the app — leave it to the network
  }

  // Deep links and reloads all resolve to the one app shell; Flutter routes
  // from there.
  if (request.mode === 'navigate') {
    event.respondWith(serveShell(request));
    return;
  }
  event.respondWith(cacheFirst(request));
});

async function serveShell(request) {
  const cached = await caches.match(scoped(SHELL), { cacheName: CACHE });
  return cached ?? fetch(request);
}

async function cacheFirst(request) {
  const cache = await caches.open(CACHE);
  // Flutter appends cache-busting query strings to some requests; the cached
  // copy is keyed off the bare path.
  const cached = await cache.match(request, { ignoreSearch: true });
  if (cached) {
    return cached;
  }

  const response = await fetch(request);
  if (response.ok && response.type === 'basic') {
    await cache.put(request, response.clone());
  }
  return response;
}

self.addEventListener('message', (event) => {
  const data = event.data;
  if (!data) {
    return;
  }
  // The page shows an "update ready" prompt while a new worker waits; this is
  // how accepting it hands over.
  if (data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  // The page reports what it actually loaded once it has painted. See
  // cacheUrls for why this matters.
  if (data.type === 'CACHE_URLS' && Array.isArray(data.urls)) {
    event.waitUntil(cacheUrls(data.urls));
  }
});

/**
 * Caches URLs the page fetched outside this worker's control.
 *
 * On a very first visit the engine payload is requested before the worker has
 * claimed the page, so the fetch handler never sees it and it would be missing
 * if the user went offline straight away. The page tells us which of the
 * runtime-only files (the one CanvasKit variant its browser chose) it really
 * used, and we fetch those into the cache.
 */
async function cacheUrls(urls) {
  if (!STAMPED) {
    return;
  }
  const cache = await caches.open(CACHE);
  await Promise.all(
    urls.map(async (url) => {
      if (unscoped(url) === null) {
        return;
      }
      if (await cache.match(url, { ignoreSearch: true })) {
        return;
      }
      try {
        const response = await fetch(url);
        if (response.ok && response.type === 'basic') {
          await cache.put(url, response);
        }
      } catch (_) {
        // Offline already — the fetch handler will cache it on a later run.
      }
    })
  );
}
