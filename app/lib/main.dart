// App entry point. Opens the project named by the MOTOLII_DOC environment variable, or the last one opened.
// See bridge/engine_paths.dart.
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/engine_paths.dart';
import 'package:motolii/skin/theme.dart';
import 'package:motolii/workspace/workspace.dart';

void main() {
  ColorTheme.setSkinRoots(shelves: motoliiShelves, own: motoliiOwn);
  runApp(
    WidgetsApp(
      color: const Color(0xFF000000),
      debugShowCheckedModeBanner: false,
      builder: (c, _) => Workspace(document: motoliiDoc),
    ),
  );
}
