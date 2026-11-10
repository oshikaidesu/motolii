// What pictures look like, as numbers a shelf's map can compare: tiny colours or a CLIP encoder's vector, cached on disk.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart' show sha1;

import 'package:motolii/bridge/motolii.dart' show Motolii;
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/storage/json_file.dart' show fileKeep;

/// The feature vectors of the pictures a shelf's map has compared, remembered while the window is open so each picture
/// is read once.
class ImageFeatures {
  final _tiny = <String, Float32List>{};
  final _clip = <String, Float32List>{};

  /// Feature vector for images, from their colours reduced to 16 x 16 pixels (Torralba, Fergus and Freeman, "80 million
  /// tiny images", 2008). Several images are concatenated.
  ///
  /// Returns null when one of them cannot be read yet, so it is asked for again next time. Cached while the window is open.
  Future<Float32List?> tiny(List<String> files) async {
    final key = files.join('\n');
    if (_tiny[key] case final v?) return v;
    final v = await _read(files);
    if (v != null) _tiny[key] = v;
    return v;
  }

  /// Feature vector of several images from the CLIP image encoder [model].
  ///
  /// Each image is resized to 224 x 224, as CLIP's own Resize does, and gives 512 numbers. The images are concatenated so
  /// that two effects are compared frame by frame at the same times, as in ViSiL's frame-to-frame similarity
  /// (Kordopatis-Zilos et al., ICCV 2019). Every effect's tile is drawn at the same times. Returns null if an image cannot
  /// be read or the model fails. Results are cached ([featuresKept]), so only a new or redrawn image is encoded again.
  Future<Float32List?> seen(Motolii m, String model, List<String> files) async {
    final key = '$model\n${files.join('\n')}';
    if (_clip[key] case final v?) return v;
    final v = Float32List(512 * files.length),
        keys = <String>[],
        missing = <int>[];
    for (final (k, f) in files.indexed) {
      try {
        keys.add(
          '$model\n$f\n${File(f).lastModifiedSync().microsecondsSinceEpoch}',
        );
      } catch (_) {
        return null;
      }
      if (featuresKept(keys[k]) case final had?) {
        v.setRange(512 * k, 512 * (k + 1), had);
      } else {
        missing.add(k);
      }
    }
    if (missing.isNotEmpty) {
      final pictures = <Uint8List>[];
      for (final k in missing) {
        try {
          final codec = await ui.instantiateImageCodec(
            await File(files[k]).readAsBytes(),
            targetWidth: 224,
            targetHeight: 224,
          );
          final image = (await codec.getNextFrame()).image;
          pictures.add(
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer
                .asUint8List(),
          );
          image.dispose();
          codec.dispose();
        } catch (_) {
          return null;
        }
      }
      final told = await m.likeness(model, pictures);
      if (told == null) return null;
      for (final (j, k) in missing.indexed) {
        v.setRange(512 * k, 512 * (k + 1), told[j]);
        keepFeatures(keys[k], told[j]);
      }
    }
    return _clip[key] = v;
  }
}

Future<Float32List?> _read(List<String> files) async {
  const side = 16;
  final out = Float32List(files.length * side * side * 3);
  for (final (k, f) in files.indexed) {
    try {
      final codec = await ui.instantiateImageCodec(
        await File(f).readAsBytes(),
        targetWidth: side,
        targetHeight: side,
      );
      final image = (await codec.getNextFrame()).image,
          px = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
              .buffer
              .asUint8List();
      image.dispose();
      codec.dispose();
      for (var i = 0; i < side * side; i++) {
        for (var ch = 0; ch < 3; ch++) {
          out[(k * side * side + i) * 3 + ch] = px[i * 4 + ch] / 255;
        }
      }
    } catch (_) {
      return null;
    }
  }
  return out;
}

/// Path of the CLIP image encoder [name] (clip_b32 is OpenAI's ViT-B/32, fontclip_b32 is FontCLIP's) if it has been
/// built (engine/deps/likeness_models.py), otherwise null. Without a model the maps use tiny colours
/// ([ImageFeatures.tiny]).
String? likenessModel(String name) {
  final f =
      '${Platform.environment['HOME']}/Library/Caches/Motolii/models/$name.onnx';
  return File(f).existsSync() ? f : null;
}

/// The cache file for an image's feature vector, in ~/Library/Caches/Motolii/looks.
/// [key] combines the model, the image and when it was drawn. [featuresKept] returns null when nothing is cached.
File _look(String key) => File(
  '${Platform.environment['HOME']}/Library/Caches/Motolii/looks/${sha1.convert(utf8.encode(key))}.f32',
);
Float32List? featuresKept(String key) {
  try {
    final had = _look(key).readAsBytesSync();
    return had.isEmpty || had.length % 4 != 0
        ? null
        : had.buffer.asFloat32List();
  } catch (_) {
    return null;
  }
}

void keepFeatures(String key, Float32List v) {
  fileKeep(_look(key), Float32List.fromList(v).buffer.asUint8List());
}

/// Joins several feature vectors per item side by side, as FontMap does for fonts (FontCLIP's numbers beside the tags'
/// and shapes', weighted 1, 0.5 and 0.2).
///
/// Each part is scaled to a total spread of 1, then multiplied by its entry in [weights]. Parts listed in [even] are
/// first standardised per dimension (z-score). An item the first part has no vector for is left out (null). An item
/// missing from another part gets that part's mean, so the part says nothing about it.
List<Float32List?> joinFeatures(
  List<List<Float32List?>> parts,
  List<double> weights, {
  Set<int> even = const {},
}) {
  final n = parts.first.length, made = <List<Float32List>>[];
  for (final (k, rows) in parts.indexed) {
    final dims = rows.nonNulls.firstOrNull?.length ?? 0,
        had = [
          for (final r in rows)
            if (r != null && r.length == dims) r,
        ];
    final mean = Float64List(dims),
        sd = Float64List(dims)..fillRange(0, dims, 1);
    for (final r in had) {
      for (var i = 0; i < dims; i++) {
        mean[i] += r[i] / had.length;
      }
    }
    if (even.contains(k)) {
      sd.fillRange(0, dims, 0);
      for (final r in had) {
        for (var i = 0; i < dims; i++) {
          sd[i] += (r[i] - mean[i]) * (r[i] - mean[i]) / had.length;
        }
      }
      for (var i = 0; i < dims; i++) {
        sd[i] = math.sqrt(sd[i]) + 1e-6;
      }
    }
    final out = [for (final _ in rows) Float32List(dims)];
    var spread = 0.0;
    for (final (j, r) in rows.indexed) {
      if (r == null || r.length != dims) continue;
      for (var i = 0; i < dims; i++) {
        out[j][i] = (r[i] - mean[i]) / sd[i];
        spread += out[j][i] * out[j][i] / had.length;
      }
    }
    final by = spread > 0 ? weights[k] / math.sqrt(spread) : 0.0;
    for (final r in out) {
      for (var i = 0; i < dims; i++) {
        r[i] *= by;
      }
    }
    made.add(out);
  }
  return [
    for (var i = 0; i < n; i++)
      if (parts.first[i] == null)
        null
      else
        Float32List.fromList([for (final k in made) ...k[i]]),
  ];
}
