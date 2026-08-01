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

### Deploying to Vercel

`vercel.json` builds the app on Vercel and serves `build/web`. Nothing needs
configuring in the dashboard — import the repo and deploy; the framework preset
should stay "Other".

Vercel's build image has no Flutter, so `tool/vercel_build.sh` installs a pinned
SDK first. It caches both the SDK and the pub packages under `.vercel/cache`, so
only the first deploy pays for the download. When upgrading Flutter, bump
`FLUTTER_VERSION` in that script to match the revision in `.metadata`.

Two details in `vercel.json` are load-bearing:

- **Everything is served `must-revalidate`.** Flutter's web output has no
  content hashes in its filenames — `main.dart.js`, `assets/*` and `canvaskit/*`
  keep the same URLs from build to build — so any long-lived `Cache-Control`
  would hand returning visitors the previous deploy's code. `web/sw.js` is the
  real cache; HTTP only has to revalidate, which is cheap (304s). `sw.js` itself
  is additionally `no-cache`, since it decides when every other file is replaced.
- **The catch-all rewrite to `/index.html`** only fires for paths that do not
  exist on disk, since Vercel matches real files first. It is what stops a
  refresh or a deep link from 404ing.

## Firebase (auth + Firestore)

Sign-in is Google-only, and a signed-in user's tasks, inbox, rewards and day
counters live in Firestore under `users/{uid}`.

The app runs **without** Firebase too. With no config it stays in memory with
the demo dataset — that is what `flutter test` and a plain `flutter run` use, so
you never need credentials just to work on the UI.

### 1. Create the project

1. <https://console.firebase.google.com> → **Add project**.
2. **Build → Authentication → Get started → Google → Enable.** Set a support
   email and save. No OAuth client ID is needed: the app uses Firebase's own
   consent handler at `<authDomain>/__/auth/handler`.
3. **Build → Firestore Database → Create database.** Pick a region — it cannot
   be changed later. Start in production mode; step 3 below replaces the rules.
4. **Project settings → Your apps → Web (`</>`)** → register an app. Copy the
   `firebaseConfig` values it shows you.

### 2. Give the app the config

Six values, passed as `--dart-define`. **None of them are secrets** — a Firebase
web config identifies the project, it does not grant access, and it ships inside
the JS bundle no matter what you do. The rules in step 3 and the authorized
domains in step 4 are what actually protect the data.

| Env var | From `firebaseConfig` |
| --- | --- |
| `FIREBASE_API_KEY` | `apiKey` |
| `FIREBASE_AUTH_DOMAIN` | `authDomain` |
| `FIREBASE_PROJECT_ID` | `projectId` |
| `FIREBASE_STORAGE_BUCKET` | `storageBucket` |
| `FIREBASE_MESSAGING_SENDER_ID` | `messagingSenderId` |
| `FIREBASE_APP_ID` | `appId` |

**Locally** — copy the example file and fill it in. `.env` is gitignored;
`.env.example` is the committed template.

```sh
cp .env.example .env
```

The file must be `KEY=value`. Flutter's `.env` parser rejects `KEY: value` with
`Invalid property line`.

`tool/build_web.dart` picks `.env` up on its own, so the web build needs no
flags. `flutter run` does not, so pass it there:

```sh
dart run tool/build_web.dart                        # uses .env automatically
flutter run -d chrome --dart-define-from-file=.env
```

**On Vercel** — add all six under **Project → Settings → Environment Variables**
(Production, Preview and Development). `tool/vercel_build.sh` turns them into
`--dart-define` flags and **fails the build if any are missing**, rather than
shipping a build that silently does not persist anything. To deploy deliberately
without Firebase, set `ALLOW_MISSING_FIREBASE=1`.

### 3. Publish the security rules

`firestore.rules` restricts every user to their own `users/{uid}` subtree and
denies everything else. Without this, a production-mode database rejects all
reads and writes and the app will load to an error screen.

```sh
firebase deploy --only firestore:rules
```

Or paste the file into **Firestore Database → Rules → Publish**.

### 4. Authorize your domains

**Authentication → Settings → Authorized domains** must list every origin the
app is served from, or Google sign-in fails with `unauthorized-domain`:

- `localhost` (already there by default)
- your production domain, e.g. `taskdice.vercel.app`
- any custom domain

Vercel gives every preview deployment a **new** URL, and each one needs adding
if you want sign-in to work there. Adding your `*.vercel.app` production domain
does not cover previews — wildcards are not supported.

### What is stored

```
users/{uid}                points, day counters, dayKey
users/{uid}/tasks/{id}     title, tag, priority, estimate, status, actual
users/{uid}/inbox/{id}     captured text, timestamp, mid-focus flag
users/{uid}/rewards/{id}   title, progress, claimed
users/{uid}/session/current the focus session in progress
```

Writes are fire-and-forget against Firestore's local cache, so edits apply
instantly and queue when offline. Daily figures are stamped with `dayKey`; open
the app on a new day and they reset while the running `points` total carries
over.

### The focus timer

The session document stores *instants*, never a running count:

```
activeTaskId, accumMs, runningSince, breakAccumMs, breakSince
```

Elapsed time is recomputed from the clock every time it is displayed
(`elapsed = accum + (now − runningSince)`), so the seconds that pass while the
tab is closed still count. That is what makes the timer survive a refresh and
show the same reading on a second device.

It is written on transitions only — start, pause, resume, break, complete — and
never on the one-second display tick, which would otherwise be a Firestore write
per second. `session/current` is its own document so the cross-device listener
wakes on session changes rather than on every counter update.

Not yet persisted: the Trends/Progress history, which is still seeded demo data.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
