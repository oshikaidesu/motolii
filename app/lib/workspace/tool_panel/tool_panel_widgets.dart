// The empty list of tool-panel tools. Tools of your own: Workspace(tools: [PanelTool(...)]).
import 'package:flutter/widgets.dart';

/// One tool the tool panel can hold.
class PanelTool {
  const PanelTool(this.name, this.tone, this.acts, {this.build});
  final String name, acts;
  final Color tone;
  final Widget Function()? build;
}

final panelTools = <PanelTool>[];
