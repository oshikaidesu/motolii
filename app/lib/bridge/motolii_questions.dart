// Questions to the engine (docs/app/BRIDGE.md Q), asked on another isolate or a platform channel.
// Each answer is a Future, so the app never blocks on them.
part of 'motolii.dart';

extension MotoliiQuestions on Motolii {
  /// The stage as a Flutter texture. The engine draws it on its own clock and nothing is copied. Returns -1 if unavailable.
  Future<int> texture() async {
    // The render thread opens it, so the app never blocks.
    final (a, _) = await answered(later('live'));
    if (a == 0) return -1;
    return await Motolii._channel.invokeMethod<int>('start', {'lib': libPath, 'handle': _m.address}) ?? -1;
  }

  /// The tool panel's output as a Flutter texture. Returns -1 if unavailable.
  Future<int> deskTexture() async => _deskId ??=
      await Motolii._channel.invokeMethod<int>('start', {
        'lib': libPath,
        'handle': _m.address,
        'front': 'motolii_desk_front',
        'frames': 'motolii_desk_frames',
      }) ??
      -1;

  /// Exports the whole project as an .mp4 with the sound of its videos, on another isolate so the app does not block.
  ///
  /// The engine's render thread takes the call in turn, whichever thread it comes from.
  Future<bool> exportVideo(String mp4) {
    final lib = libPath, at = _m.address;
    return Isolate.run(() {
      final ask = c.MotoliiBindings(DynamicLibrary.open(lib)).motolii_export;
      final to = mp4.toNativeUtf8();
      final done = ask(_P.fromAddress(at), to) != 0;
      malloc.free(to);
      return done;
    });
  }

  /// Each property as the stage shows it at the requested time: after any relation, otherwise its own value.
  /// An entry is null if the property has none.
  ///
  /// Use it for times other than the current frame's. It runs on another isolate (docs/app/BRIDGE.md Q).
  Future<List<double?>> shownAt(List<(int, String, double)> asks) {
    final lib = libPath, at = _m.address;
    return Isolate.run(() {
      final l = DynamicLibrary.open(lib), m = _P.fromAddress(at);
      final shows = c.MotoliiBindings(l).motolii_shows;
      final out = malloc<Double>();
      final all = [
        for (final (t, n, moment) in asks)
          () {
            final name = n.toNativeUtf8(), got = shows(m, t, name, moment, out);
            malloc.free(name);
            return got == 0 ? null : out.value;
          }(),
      ];
      malloc.free(out);
      return all;
    });
  }

  /// For each font file, the index of the first of [words] that text can be set in, or -1 if none. Runs on another isolate.
  Future<List<int>> settingFirst(List<String> fonts, List<String> words) {
    final lib = libPath;
    return Isolate.run(() {
      final ask = c.MotoliiBindings(DynamicLibrary.open(lib)).motolii_sets;
      final said = [for (final w in words) w.toNativeUtf8()], out = <int>[];
      for (final f in fonts) {
        final file = f.toNativeUtf8();
        // The font's cmap reports a missing glyph before ThorVG reads the file (see type_sets).
        out.add(said.indexWhere((w) => ask(file, w) != 0));
        malloc.free(file);
      }
      said.forEach(malloc.free);
      return out;
    });
  }

  /// Renders [words] in each font file as white on black, [w] by [h] bytes with one byte per point.
  ///
  /// The text is no larger than [most] when that is above 0. An entry is null if nothing was drawn
  /// (motolii_type_frame). Runs on another isolate, like [settingFirst].
  Future<List<Uint8List?>> typePictures(List<String> fonts, String words, int w, int h, {double most = 0}) {
    final lib = libPath;
    return Isolate.run(() {
      final ask = c.MotoliiBindings(DynamicLibrary.open(lib)).motolii_type_frame;
      final said = words.toNativeUtf8(), out = malloc<UnsignedChar>(w * h), all = <Uint8List?>[];
      for (final f in fonts) {
        final file = f.toNativeUtf8();
        all.add(ask(file, said, w, h, most, out) != 0 ? Uint8List.fromList(out.cast<Uint8>().asTypedList(w * h)) : null);
        malloc.free(file);
      }
      malloc.free(said);
      malloc.free(out);
      return all;
    });
  }

  /// Encodes each image (224 by 224 points, RGBA) into a 512-number vector with the CLIP image encoder in the ONNX
  /// file [model] (motolii_likeness), on another isolate. Null if the model is missing.
  Future<List<Float32List>?> likeness(String model, List<Uint8List> pictures) {
    final lib = libPath;
    return Isolate.run(() {
      const side = 224 * 224 * 4, dims = 512;
      final n = pictures.length, file = model.toNativeUtf8(), into = malloc<UnsignedChar>(n * side + 1), out = malloc<Float>(n * dims + 1);
      for (final (i, p) in pictures.indexed) {
        into.cast<Uint8>().asTypedList(n * side).setRange(i * side, (i + 1) * side, p);
      }
      final encoded = n > 0 && c.MotoliiBindings(DynamicLibrary.open(lib)).motolii_likeness(file.cast(), into, n, dims, out) != 0;
      final all = encoded ? [for (var i = 0; i < n; i++) Float32List.fromList(out.asTypedList(n * dims).sublist(i * dims, (i + 1) * dims))] : null;
      malloc.free(file);
      malloc.free(into);
      malloc.free(out);
      return all;
    });
  }

  /// Lays [points] out on a plane with similar ones close together (motolii_map, using t-SNE).
  ///
  /// Returns one (x, y) per point, in order, each from 0 to 1. Null if there are fewer than four points.
  /// Runs on another isolate.
  Future<List<(double, double)>?> map(List<Float32List> points) {
    final lib = libPath;
    return Isolate.run(() {
      final n = points.length, dims = n == 0 ? 0 : points.first.length;
      final at = malloc<Float>(n * dims + 1), xy = malloc<Double>(2 * n + 1);
      for (var i = 0; i < n; i++) {
        at.asTypedList(n * dims).setRange(i * dims, (i + 1) * dims, points[i]);
      }
      final got = c.MotoliiBindings(DynamicLibrary.open(lib)).motolii_map(at, n, dims, xy);
      final laid = got == 0 ? null : [for (var i = 0; i < n; i++) (xy[2 * i], xy[2 * i + 1])];
      malloc.free(at);
      malloc.free(xy);
      return laid;
    });
  }

  /// How a layer moves over a time range as the stage places it, including its wave.
  ///
  /// Returns [n] samples from [from] up to [to], four numbers each: position (x, y in stage units), rotation (degrees)
  /// and scale (a fraction). Null if there is no such layer. Ask once when the properties change, to drive a small
  /// preview that then plays on its own (motolii_path).
  Future<List<double>?> path(int layer, {double from = 0, required double to, int n = 60}) => _ask((l, m) {
    final out = malloc<Double>(4 * n);
    final got = c.MotoliiBindings(l).motolii_path(m, layer, 0, from, to, n, out);
    final p = [for (var i = 0; i < 4 * got; i++) out[i]];
    malloc.free(out);
    return got > 0 ? p : null;
  });

  /// Asks the engine a question on another isolate (docs/app/BRIDGE.md Q), so the app does not wait for the answer.
  Future<T> _ask<T>(T Function(DynamicLibrary lib, _P m) ask) {
    final lib = libPath, at = _m.address;
    return Isolate.run(() => ask(DynamicLibrary.open(lib), _P.fromAddress(at)));
  }

  /// Like [path] but in 3D. Four numbers per sample: position (x, y, z in stage units) and scale (motolii_path3).
  List<double>? path3(int layer, {int copy = 0, required double to, int n = 24}) {
    final out = malloc<Double>(4 * n);
    final got = _path3(_m, layer, copy, 0, to, n, out), p = [for (var i = 0; i < 4 * got; i++) out[i]];
    malloc.free(out);
    return got > 0 ? p : null;
  }

  /// A video layer's loudness in dB (0 is full scale), sampled 100 times per second of the video's own time.
  /// Empty if there is no sound or the layer is not a video. The file is decoded once, on another isolate.
  Future<List<double>> loudness(int layer) {
    final lib = libPath, at = _m.address;
    return Isolate.run(() {
      final ask = c.MotoliiBindings(DynamicLibrary.open(lib)).motolii_loudness;
      final m = _P.fromAddress(at), n = ask(m, layer, nullptr, 0), out = malloc<Float>(n < 1 ? 1 : n);
      final got = ask(m, layer, out, n), all = [for (var i = 0; i < got && i < n; i++) out[i].toDouble()];
      malloc.free(out);
      return all;
    });
  }

  /// A video layer's loudness in dB at [n] project times from [from] up to [to], at the points where the layer shows them.
  /// -100 means silent or not shown. Null if the sound has not been read yet ([loudness] reads it). Empty means no sound.
  Future<List<double>?> loudnessOver(int layer, double from, double to, int n) => _ask((l, m) {
    final out = malloc<Float>(n < 1 ? 1 : n);
    final got = c.MotoliiBindings(l).motolii_loudness_over(m, layer, from, to, n, out);
    final all = got < 0 ? null : [for (var i = 0; i < got; i++) out[i].toDouble()];
    malloc.free(out);
    return all;
  });

  /// The project times where a video's sound strikes, meaning it gets [rise] dB louder at once, at the points where the layer shows them.
  /// Ask after its loudness has been read ([loudness]).
  Future<List<double>> strikes(int layer, double rise) => _ask((l, m) {
    final ask = c.MotoliiBindings(l).motolii_strikes;
    final n = ask(m, layer, rise, 0, nullptr, 0), out = malloc<Double>(n < 1 ? 1 : n);
    final got = ask(m, layer, rise, 0, out, n), all = [for (var i = 0; i < got && i < n; i++) out[i]];
    malloc.free(out);
    return all;
  });

  /// A small frame of the video at [seconds], rounded to the nearest tenth. A timeline bar shows it to indicate what the video plays.
  Future<String?> videoFrame(String video, double seconds) =>
      _thumbnails['$video@${(seconds * 10).round()}'] ??= _thumbnail(libPath, video, 0, 1, (seconds * 10).round() / 10);

  /// A small .png of the frame [step] of [steps] along the video, for a tile that scrubs with the pointer or plays.
  /// Step 0 is the first frame. Null if no image could be made. Made once, on another isolate.
  Future<String?> thumbnailAt(String video, int step, int steps) =>
      step == 0 ? _thumbnails[video] ??= _thumbnail(libPath, video) : _thumbnails['$video#$step/$steps'] ??= _thumbnail(libPath, video, step, steps);

  /// Completes with a ticket's answer when it arrives, and with the reason if it was refused.
  ///
  /// Like Thermion's VoidCallbackRegistry, it keeps a Completer per ticket and completes it when the engine reports an
  /// answer (motolii_add_listener, flag 8). Nothing polls.
  Future<(int, String)> answered(int ticket) {
    final a = answer(ticket);
    if (a >= 0) return Future.value((a, a >= 1 ? '' : answerWhy));
    return (_waiting[ticket] ??= Completer<(int, String)>()).future;
  }

  /// A ticket's answer: -1 if not done yet, 0 if refused ([answerWhy] says why), 1 if done. Each answer is reported once.
  int answer(int ticket) {
    final a = _answer(_m, ticket);
    // Done: read the snapshots as the engine made them before it answered.
    if (a >= 0) _take(3);
    return a;
  }

  String get answerWhy => _answerWhy(_m).toDartString();
}
