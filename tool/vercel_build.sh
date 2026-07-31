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

if [ -x "${FLUTTER_DIR}/bin/flutter" ] &&
    [ "$(cat "${VERSION_STAMP}" 2>/dev/null || true)" = "${FLUTTER_VERSION}" ]; then
    echo "==> Reusing cached Flutter ${FLUTTER_VERSION}"
else
    echo "==> Installing Flutter ${FLUTTER_VERSION}"
    rm -rf "${FLUTTER_DIR}"
    mkdir -p "${CACHE_DIR}"
    git clone --depth 1 --branch "${FLUTTER_VERSION}" \
        https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
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
dart run tool/build_web.dart --release

echo "==> build/web ready"
