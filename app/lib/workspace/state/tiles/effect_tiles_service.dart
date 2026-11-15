// What the effects shelf asks of the engine: drawing the effect tiles again, and how many effects the document has.
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/workspace/state/document/document_service.dart';
import 'package:motolii/workspace/state/tiles/effect_tiles.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

void Function()? effectTilesAgain(WorkspaceController ws, {String? file}) =>
    documentOpen(ws) ? () => EffectTiles.again(ws, file: file) : null;

int readyEffectCount(WorkspaceController ws) =>
    (ws.inside?.layerEffects.length ?? 0) + (ws.inside?.effects.length ?? 0);
