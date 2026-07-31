// Custom Flutter bootstrap.
//
// This is the stock bootstrap minus the `serviceWorkerSettings` argument.
// Flutter's service-worker wiring is deprecated (flutter/flutter#156910) and
// the worker it registers is an inert stub, so TaskDice registers its own
// offline-first worker from index.html instead. Passing the settings here
// would only register Flutter's stub alongside it.

{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load();
