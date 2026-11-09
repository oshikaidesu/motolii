// Motolii: the window. Opens the document given by MOTOLII_DOC or the last one (motolii.dart).
import 'package:flutter/widgets.dart';

import 'engine/motolii.dart';
import 'workspace/workspace.dart';

void main() => runApp(WidgetsApp(
      color: const Color(0xFF000000),
      debugShowCheckedModeBanner: false,
      builder: (c, _) => Workspace(document: motoliiDoc),
    ));
