// Syncs the native macOS window appearance (title bar) with Motolii's Light/Dark shade.
import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException;

const _shade = MethodChannel('motolii/shade');

/// Tells the host window whether the app is in Light mode so the title bar matches.
Future<void> syncWindowShade(bool light) async {
  try {
    await _shade.invokeMethod<void>('set', {'light': light});
  } on MissingPluginException {
    // Tests and platforms without the native handler ignore it.
  } catch (_) {}
}
