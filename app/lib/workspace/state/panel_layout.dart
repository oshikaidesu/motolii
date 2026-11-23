// The window's panels (PanelLayout): the tabs, which panel was brought to the front, the tool open in the tool panel,
// and what each panel keeps of its own view.
import 'package:flutter/foundation.dart' show VoidCallback;

import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/pane.dart';

/// The window's panels: its tabs, the panel last brought to the front, the tool open in the tool panel, and the view
/// state each panel keeps by name.
class PanelLayout {
  /// Creates it with no tabs and nothing brought to the front.
  /// [onViewChanged] is called when a value of [view] changes, [onFronted] every time a panel is brought to the front.
  PanelLayout({
    required this._layers,
    required this._onViewChanged,
    required this._onFronted,
  });

  final List<Layer> Function() _layers;
  final VoidCallback _onViewChanged, _onFronted;

  /// View state by name ('stage.tool', 'fold.Transform'): what a panel keeps of itself that is not part of the document.
  final view = <String, Object?>{};

  /// The view state kept under [name], or [otherwise] when there is none.
  T viewOf<T>(String name, T otherwise) => view[name] as T? ?? otherwise;

  /// Keeps [value] as the view state under [name].
  void setView(String name, Object? value) {
    if (view[name] == value) return;
    view[name] = value;
    _onViewChanged();
  }

  /// Whether the project currently has any camera layer.
  bool get hasCamera => _layers().any((l) => l.kind == LayerKind.camera);

  /// Whether the stage shows the 3D overview (working camera) instead of the active camera layer.
  /// Defaults to false so adding a camera immediately films the stage; toggle on when spatial context is needed.
  bool get freeEye => hasCamera && viewOf('stage.overview', false);

  /// Switches the stage between the active camera and the 3D overview.
  void setOverview(bool on) => setView('stage.overview', on);

  /// The group/parent layer currently isolated for pre-comp-style centered local editing, or null.
  int? get isolatedGroup {
    final id = viewOf<int?>('stage.isolate', null);
    if (id == null || id <= 0) return null;
    return _layers().any((l) => l.id == id) ? id : null;
  }

  /// Sets the isolated group/parent layer ID (null exits back to the full stage).
  void setIsolatedGroup(int? id) =>
      setView('stage.isolate', id != null && id > 0 ? id : null);

  /// The working camera's position as an orbit around the world's centre: yaw, pitch and distance.
  /// Defaults slightly angled and pulled back so the Boxcam frame and camera body pin fit in 3D View.
  List<double> get eye => viewOf('stage.eye', const [28.0, -18.0, 2.2]);

  /// The tool the user opened in the tool panel. Null lets the tool panel follow the selection.
  String? toolPanelManual;

  /// Every tab in the window, set once by Workspace. The tool panel's catalog is the tabs that do not start in a strip.
  List<Pane> panes = const [];

  /// The tabs of [panes] that are opened inside the tool panel.
  List<Pane> get tools => [
    for (final p in panes)
      if (p.at == PaneStrip.catalog) p,
  ];

  /// Opens the tool [name] in the tool panel and brings the tool panel to the front.
  void openToolPanel(String? name) {
    toolPanelManual = name;
    front('Tool Panel');
  }

  /// Brings a panel to the front of its tabs (the panels follow, see panes.dart).
  void front(String pane) {
    fronted = (pane, (fronted?.$2 ?? 0) + 1);
    _onFronted();
  }

  /// The panel last brought to the front, with a count that goes up every time, so that fronting the same panel again is heard.
  (String, int)? fronted;

  /// Set of pane names currently open in the docking layout (kept in sync by `Panes`).
  Set<String> openTabs = const {};

  /// Records the set of pane names currently mounted in the docking layout.
  void syncOpenTabs(Set<String> ids) {
    if (openTabs.length == ids.length && openTabs.containsAll(ids)) return;
    openTabs = Set.unmodifiable(ids);
    _onFronted();
  }

  /// A custom tool pane requested to open as an independent closable docking tab
  /// (optionally docked onto a specific target pane [onPane]).
  (Pane, String?, int)? dockOpened;

  /// Opens [pane] as an independent closable tab in the workspace docking layout
  /// (docked onto [onPane] when given, or fronts it if already open).
  void openDockTab(Pane pane, {String? onPane}) {
    dockOpened = (pane, onPane, (dockOpened?.$3 ?? 0) + 1);
    _onFronted();
  }

  /// The tool the tool panel shows: the one opened by hand, else 'Tools'.
  String get toolPanel => toolPanelManual ?? 'Tools';

  /// Handles a link from another panel to a panel (fonts, colours, ease): the dock or tool panel shows it.
  void route(String to) => front(to.split('›').last.trim());
}
