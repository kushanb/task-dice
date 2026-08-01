// Builds the web app and stamps the service worker's precache manifest.
//
// Use this instead of a bare `flutter build web` — a plain build produces a
// web/sw.js that is still in its inert "dev" state, so the result installs but
// never works offline.
//
// Usage:
//   dart run tool/build_web.dart [extra flutter build web args]
//
// e.g. `dart run tool/build_web.dart --base-href=/taskdice/`

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Files the worker should never serve: debug-only artifacts, and Flutter's own
/// service worker, which since 3.29 is an inert stub that unregisters itself
/// (TaskDice registers web/sw.js instead).
bool _isJunk(String path) =>
    path.endsWith('.map') ||
    path.endsWith('.symbols') ||
    path == 'sw.js' ||
    path == 'flutter_service_worker.js' ||
    path == 'version.json' ||
    path.split('/').last.startsWith('.');

/// Shipped and cacheable, but too big to download up front.
///
/// `canvaskit/` holds five mutually exclusive renderer payloads (~24 MB) of
/// which a given browser loads exactly one, and `NOTICES` is licence text the
/// app only reads if someone opens the licence page. All of it is still cached
/// on first use by the worker's runtime cache-first handler, which happens
/// while the page is online and rendering, so offline launches are unaffected.
bool _isRuntimeOnly(String path) =>
    path.startsWith('canvaskit/') || path == 'assets/NOTICES';

const _configStart = '// build:config-start';
const _configEnd = '// build:config-end';

Future<void> main(List<String> args) async {
  final root = Directory.current;
  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Run this from the repository root.');
    exit(1);
  }

  // Pick up a local .env automatically so `dart run tool/build_web.dart` needs
  // no flags. On Vercel there is no .env — the Firebase settings arrive as real
  // environment variables and vercel_build.sh passes them as --dart-define,
  // which is why this is skipped when the caller already supplied defines.
  final hasOwnDefines = args.any((a) => a.startsWith('--dart-define'));
  final envFile = File('${root.path}/.env');
  final useEnvFile = !hasOwnDefines && envFile.existsSync();
  if (useEnvFile) {
    stdout.writeln('Using .env for Firebase config.');
  } else if (!hasOwnDefines) {
    stdout.writeln(
      'No .env found — building without Firebase (data will not persist).',
    );
  }

  // --no-web-resources-cdn keeps CanvasKit local. Without it the engine is
  // pulled from gstatic at runtime and the app cannot start offline.
  final buildArgs = <String>[
    'build',
    'web',
    if (!args.any((a) => a.contains('web-resources-cdn'))) '--no-web-resources-cdn',
    if (useEnvFile) '--dart-define-from-file=.env',
    ...args,
  ];

  stdout.writeln('flutter ${buildArgs.join(' ')}');
  final build = await Process.start(
    'flutter',
    buildArgs,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await build.exitCode;
  if (code != 0) {
    exit(code);
  }

  final output = Directory('${root.path}/build/web');
  final worker = File('${output.path}/sw.js');
  if (!worker.existsSync()) {
    stderr.writeln('Missing ${worker.path} — is web/sw.js still in place?');
    exit(1);
  }

  final resources = <String, String>{};
  var bytes = 0;
  var deferred = 0;
  for (final entity in output.listSync(recursive: true).whereType<File>()) {
    final path = entity.path.substring(output.path.length + 1);
    if (_isJunk(path)) {
      continue;
    }
    final content = entity.readAsBytesSync();
    if (_isRuntimeOnly(path)) {
      deferred += content.length;
      continue;
    }
    resources[path] = sha256.convert(content).toString().substring(0, 16);
    bytes += content.length;
  }

  final paths = resources.keys.toList()..sort();
  final buildId = sha256
      .convert(utf8.encode(paths.map((p) => '$p:${resources[p]}').join('\n')))
      .toString()
      .substring(0, 16);

  final config = StringBuffer()
    ..writeln(_configStart)
    ..writeln("const BUILD_ID = '$buildId';")
    ..writeln('const RESOURCES = ${_encode(paths, resources)};')
    ..write(_configEnd);

  final source = worker.readAsStringSync();
  final start = source.indexOf(_configStart);
  final end = source.indexOf(_configEnd);
  if (start < 0 || end < 0) {
    stderr.writeln('web/sw.js is missing its $_configStart / $_configEnd markers.');
    exit(1);
  }
  worker.writeAsStringSync(
    source.replaceRange(start, end + _configEnd.length, config.toString()),
  );

  stdout.writeln(
    'Stamped build/web/sw.js — build $buildId, '
    '${resources.length} files / ${_mb(bytes)} precached, '
    '${_mb(deferred)} left to the runtime cache.',
  );
}

String _mb(int bytes) => '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';

String _encode(List<String> paths, Map<String, String> resources) {
  final entries = paths.map((p) => '  ${jsonEncode(p)}: ${jsonEncode(resources[p])},');
  return '{\n${entries.join('\n')}\n}';
}
