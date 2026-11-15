// The engine's picture work for the shelves' maps: a font or a picture drawn as the engine draws it, a picture's look
// from a CLIP encoder, and the points of a map laid out by the engine. Shelves ask through here.
import 'dart:typed_data';

import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

Future<List<Uint8List?>> typePicturesOf(
  WorkspaceController ws,
  List<String> fonts,
  String words,
  int w,
  int h, {
  double most = 0,
}) => ws.inside!.typePictures(fonts, words, w, h, most: most);

Future<List<Float32List>?> likenessOf(
  WorkspaceController ws,
  String model,
  List<Uint8List> pictures,
) => ws.inside!.likeness(model, pictures);

Future<List<(double, double)>?> layOutMap(
  WorkspaceController ws,
  List<Float32List> points,
) => ws.inside!.map(points);
