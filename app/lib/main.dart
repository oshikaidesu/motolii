// App entry point. Opens the project named by the MOTOLII_DOC environment variable, or the last one opened.
// See bridge/engine_paths.dart.
import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart' show FlutterError, PlatformDispatcher;
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/engine_paths.dart';
import 'package:motolii/skin/theme.dart';
import 'package:motolii/workspace/workspace.dart';

void main() {
  // Catch widget-tree errors (layout, build, paint).
  // presentError keeps the default formatted console dump; log() also sends to DevTools.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    log(
      details.exceptionAsString(),
      name: 'flutter',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  // Catch platform-channel and async errors the zone does not reach.
  PlatformDispatcher.instance.onError = (error, stack) {
    log('$error', name: 'platform', error: error, stackTrace: stack);
    return false; // Let the platform also handle it (crash reporter etc.).
  };
  ColorTheme.setSkinRoots(shelves: motoliiShelves, own: motoliiOwn);
  runZonedGuarded(
    () => runApp(
      WidgetsApp(
        color: const Color(0xFF000000),
        debugShowCheckedModeBanner: false,
        builder: (c, _) => Workspace(document: motoliiDoc),
      ),
    ),
    (error, stack) =>
        log('$error', name: 'zone', error: error, stackTrace: stack),
  );
}
