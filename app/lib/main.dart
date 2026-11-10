// App entry point. Opens the project named by the MOTOLII_DOC environment variable, or the last one opened.
// See bridge/motolii.dart.
import 'package:flutter/widgets.dart';

import 'bridge/motolii.dart';
import 'workspace/workspace.dart';

void main() => runApp(
  WidgetsApp(
    color: const Color(0xFF000000),
    debugShowCheckedModeBanner: false,
    builder: (c, _) => Workspace(document: motoliiDoc),
  ),
);
