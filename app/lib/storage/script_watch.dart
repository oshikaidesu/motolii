// Hot-reload file watcher for JS Custom UI scripts (`shelves/panels/*.js` and `<effect>.ui.js`).
// Lives under `lib/storage/` so UI widgets never touch `dart:io` directly.
import 'dart:async';
import 'dart:io';

/// Watches a single script file on disk and invokes [onChanged] (debounced) when
/// it is saved or atomically replaced by an editor. Safe no-op when [path] does
/// not exist or directory watching is unavailable.
class ScriptFileWatcher {
  StreamSubscription<FileSystemEvent>? _sub;
  Timer? _debounce;
  String _watchedPath = '';

  void watch(String path, void Function() onChanged) {
    if (path == _watchedPath) return;
    dispose();
    _watchedPath = path;
    if (path.isEmpty) return;
    final file = File(path);
    if (!file.existsSync()) return;
    final dir = file.parent;
    if (!dir.existsSync()) return;
    final baseName = file.uri.pathSegments.isEmpty
        ? ''
        : file.uri.pathSegments.last;
    if (baseName.isEmpty) return;

    try {
      _sub = dir.watch().listen((event) {
        if (!event.path.endsWith(baseName)) return;
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 80), onChanged);
      }, onError: (_) {});
    } on FileSystemException {
      // Headless / sandboxed environments may disallow directory watches.
    }
  }

  void dispose() {
    _debounce?.cancel();
    _debounce = null;
    _sub?.cancel();
    _sub = null;
    _watchedPath = '';
  }
}
