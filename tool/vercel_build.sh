#!/usr/bin/env bash
#
# Vercel build entrypoint (wired up in vercel.json).
#
# Vercel's build image has no Flutter, so this installs a pinned SDK, then runs
# the normal web build. Both the SDK and the pub cache live under .vercel/cache,
# which Vercel restores between builds — the first deploy pays a few minutes for
# the clone and the artifacts, later ones do not.

set -euo pipefail

# Keep in sync with the revision in .metadata.
FLUTTER_VERSION="3.41.6"

# Firebase project settings come from Vercel environment variables and are
# compiled in via --dart-define. They are identifiers rather than secrets (they
# ship in the bundle regardless); firestore.rules is what protects the data.
#
# Checked before the SDK install so a missing variable fails in seconds rather
# than after a multi-minute Flutter clone.
FIREBASE_KEYS=(
    FIREBASE_API_KEY
    FIREBASE_AUTH_DOMAIN
    FIREBASE_PROJECT_ID
    FIREBASE_STORAGE_BUCKET
    FIREBASE_MESSAGING_SENDER_ID
    FIREBASE_APP_ID
)

DEFINES=()
MISSING=()
for key in "${FIREBASE_KEYS[@]}"; do
    value="${!key:-}"
    if [ -z "${value}" ]; then
        MISSING+=("${key}")
    else
        DEFINES+=("--dart-define=${key}=${value}")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    if [ -n "${ALLOW_MISSING_FIREBASE:-}" ]; then
        echo "==> WARNING: building without Firebase. Missing: ${MISSING[*]}"
        echo "    Sign-in will be skipped and data will not persist."
    else
        echo "ERROR: missing Firebase environment variables: ${MISSING[*]}" >&2
        echo "" >&2
        echo "Add them under Vercel -> Project -> Settings -> Environment Variables." >&2
        echo "Values come from Firebase console -> Project settings -> Your apps -> Web app." >&2
        echo "" >&2
        echo "To deploy deliberately without Firebase, set ALLOW_MISSING_FIREBASE=1." >&2
        exit 1
    fi
fi

CACHE_DIR="${PWD}/.vercel/cache"
FLUTTER_DIR="${CACHE_DIR}/flutter"
VERSION_STAMP="${FLUTTER_DIR}/.taskdice-flutter-version"

# Cache pub packages alongside the SDK rather than in the throwaway home dir —
# but only on Vercel. `pub get` bakes absolute package paths into
# .dart_tool/package_config.json, so doing this on a developer machine would
# repoint the checkout at a build cache and break the project the moment that
# cache is cleaned. Locally, use the normal shared pub cache.
if [ -n "${VERCEL:-}" ]; then
    export PUB_CACHE="${CACHE_DIR}/pub"
fi

# The official prebuilt archive, not a git clone.
#
# `git clone --depth 1` leaves the SDK unable to work out which engine it needs:
# bin/internal/update_engine_version.sh derives that from repository history a
# shallow clone does not have, so it writes an EMPTY bin/internal/engine.version.
# Flutter then hashes the empty file — e69de29bb2d1d6434b8b29ae775ad8c2e48c5391,
# the well-known SHA of empty content — asks the CDN for an engine at that
# revision, gets a 404 body, and fails unzipping it as the Dart SDK. The
# prebuilt archive ships engine.version and a populated bin/cache, so none of
# that resolution has to happen here.
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_ARCHIVE="${CACHE_DIR}/flutter-${FLUTTER_VERSION}.tar.xz"

# Whether a restored cache is actually usable, rather than merely present.
#
# Vercel's build cache has a size ceiling the Flutter SDK sits close to, so a
# restore can come back truncated: bin/flutter exists and the version stamp
# matches while the files the build needs are missing or empty. Checking only
# those two — as this script used to — turns one bad cache into every
# subsequent build failing. Each check below is a file the toolchain cannot run
# without, and -s additionally requires it to be non-empty.
flutter_cache_is_healthy() {
    [ -x "${FLUTTER_DIR}/bin/flutter" ] || return 1
    [ -s "${FLUTTER_DIR}/bin/internal/engine.version" ] || return 1
    [ -x "${FLUTTER_DIR}/bin/cache/dart-sdk/bin/dart" ] || return 1
    [ "$(cat "${VERSION_STAMP}" 2>/dev/null || true)" = "${FLUTTER_VERSION}" ] || return 1
}

if flutter_cache_is_healthy; then
    echo "==> Reusing cached Flutter ${FLUTTER_VERSION}"
else
    if [ -d "${FLUTTER_DIR}" ]; then
        echo "==> Cached Flutter is incomplete — reinstalling"
    else
        echo "==> Installing Flutter ${FLUTTER_VERSION}"
    fi
    rm -rf "${FLUTTER_DIR}" "${FLUTTER_ARCHIVE}"
    mkdir -p "${CACHE_DIR}"

    # --fail matters: without it curl happily writes an error page to disk and
    # the failure surfaces later as a corrupt archive, which is how the original
    # breakage presented.
    curl --fail --location --retry 3 --retry-delay 2 --retry-connrefused \
        --output "${FLUTTER_ARCHIVE}" "${FLUTTER_URL}"
    tar -xJf "${FLUTTER_ARCHIVE}" -C "${CACHE_DIR}"
    rm -f "${FLUTTER_ARCHIVE}"

    # Stamp only once the result is known good, so a half-written install is
    # never mistaken for a warm cache on the next build.
    if ! flutter_cache_is_healthy; then
        echo "ERROR: Flutter ${FLUTTER_VERSION} did not install cleanly." >&2
        echo "       Expected an SDK at ${FLUTTER_DIR} with a populated bin/cache." >&2
        exit 1
    fi
    echo "${FLUTTER_VERSION}" >"${VERSION_STAMP}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

# The SDK shells out to git against its own checkout, which git refuses to do
# when the build runs as a different user than the one that cloned it.
git config --global --add safe.directory "${FLUTTER_DIR}" || true

flutter --version
flutter pub get

# Not a bare `flutter build web`: this also stamps the service worker's precache
# manifest and keeps CanvasKit local. See tool/build_web.dart.
# The ${arr[@]+...} guard keeps `set -u` happy when the array is empty.
dart run tool/build_web.dart --release ${DEFINES[@]+"${DEFINES[@]}"}

echo "==> build/web ready"
