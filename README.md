# taskdice

A new Flutter project.

## Web (PWA)

Build the web app with:

```sh
dart run tool/build_web.dart          # extra args are passed to `flutter build web`
```

Use this rather than a bare `flutter build web`. Flutter stopped shipping a
caching service worker (the `flutter_service_worker.js` it generates is now a
stub that unregisters itself), so the app carries its own in `web/sw.js`, and
the script is what fills in that worker's precache manifest after the build.
A plain `flutter build web` produces a site that still installs but never works
offline. The script also passes `--no-web-resources-cdn`, which keeps CanvasKit
local instead of loading it from gstatic at runtime.

To try the result, serve `build/web` over HTTP — service workers do not run from
`file://`:

```sh
python3 -m http.server 8765 --directory build/web
```

Other web-specific pieces:

- `web/sw.js` — offline-first worker. Precaches the app shell and lazily caches
  the engine payload; shows an in-page "new version is ready" prompt on updates
  rather than swapping code under a running session.
- `web/flutter_bootstrap.js` — the stock bootstrap minus Flutter's deprecated
  service-worker wiring.
- `assets/fonts/` — Instrument Sans and IBM Plex Mono are bundled instead of
  fetched from the Google Fonts CDN, so type is correct offline.
- `tool/generate_icons.py` — regenerates the icon set from the in-app dice mark.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
