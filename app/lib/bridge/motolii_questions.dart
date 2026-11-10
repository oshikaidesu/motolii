// motolii_questions.dart: questions of the inside (docs/app/BRIDGE.md Q): asked on another isolate or a channel, the answer a Future; the window never waits on them.
part of 'motolii.dart';

extension MotoliiQuestions on Motolii {
  /// The stage's picture as a Flutter texture (the inside draws it by its own clock; nothing is copied). -1: none.
  Future<int> texture() async {
    final (a, _) = await answered(later('live')); // (opened by the hand: the window never stands still for it)
    if (a == 0) return -1;
    return await Motolii._channel.invokeMethod<int>('start', {'lib': libPath, 'handle': _m.address}) ?? -1;
  }

  /// The desk's picture as a Flutter texture (-1: none).
  Future<int> deskTexture() async => _deskId ??=
      await Motolii._channel.invokeMethod<int>('start', {
        'lib': libPath,
        'handle': _m.address,
        'front': 'motolii_desk_front',
        'frames': 'motolii_desk_frames',
      }) ??
      -1;

  /// The whole document written as a film (.mp4, with its films' sound), on another isolate: the window does not wait.
  /// The inside's one hand takes the call in its turn, from whatever thread it comes.
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

  /// As the stage shows each thing's value at each moment asked (what a relation makes of it, else its own; null: it
  /// has none): another moment than the picture's, a question (docs/app/BRIDGE.md Q), asked on another isolate.
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

  /// Of each font file, the first of [words] a text can be set in, by its index; -1 none (on another isolate).
  Future<List<int>> settingFirst(List<String> fonts, List<String> words) {
    final lib = libPath;
    return Isolate.run(() {
      final ask = c.MotoliiBindings(DynamicLibrary.open(lib)).motolii_sets;
      final said = [for (final w in words) w.toNativeUtf8()], out = <int>[];
      for (final f in fonts) {
        final file = f.toNativeUtf8();
        out.add(said.indexWhere((w) => ask(file, w) != 0)); // (one lacking a letter is told so by its cmap, before ThorVG reads it: type_sets)
        malloc.free(file);
      }
      said.forEach(malloc.free);
      return out;
    });
  }

  /// Of each font file, [words] in it white on black [w] by [h], a byte a point, no larger than size [most] when it is
  /// more than 0 (motolii_type_frame; null: not drawn), asked on another isolate as [setting].
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

  /// Each picture (224 points square, RGBA) told as 512 numbers, one long, by the CLIP image encoder in the ONNX file
  /// [model] (motolii_likeness), on another isolate; null: not told (no such model).
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

  /// [points] (each as many numbers) laid on a plane, the alike near (motolii_map: t-SNE): where each lies, 0 to 1 each
  /// way, in their order (null: fewer than four), worked out on another isolate.
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

  /// How a thing moves over a while, as the stage places it (its wave and all): [n] moments from [from] to before [to],
  /// four numbers each: where it is (x, y, units of the stage), how far turned (degrees), how large (a share). null: no
  /// such thing. Asked once when its values change, for a small preview that then plays by itself (motolii_path).
  Future<List<double>?> path(int layer, {double from = 0, required double to, int n = 60}) => _ask((l, m) {
    final out = malloc<Double>(4 * n);
    final got = c.MotoliiBindings(l).motolii_path(m, layer, 0, from, to, n, out);
    final p = [for (var i = 0; i < 4 * got; i++) out[i]];
    malloc.free(out);
    return got > 0 ? p : null;
  });

  /// A question of the inside (docs/app/BRIDGE.md Q): asked on another isolate, the window does not wait for its answer.
  Future<T> _ask<T>(T Function(DynamicLibrary lib, _P m) ask) {
    final lib = libPath, at = _m.address;
    return Isolate.run(() => ask(DynamicLibrary.open(lib), _P.fromAddress(at)));
  }

  /// The same in the round: four numbers a moment, where it is (x, y, z, units of the stage) and how large (motolii_path3).
  List<double>? path3(int layer, {int copy = 0, required double to, int n = 24}) {
    final out = malloc<Double>(4 * n);
    final got = _path3(_m, layer, copy, 0, to, n, out), p = [for (var i = 0; i < 4 * got; i++) out[i]];
    malloc.free(out);
    return got > 0 ? p : null;
  }

  /// A film's sound: its loudness (dB, 0 at full) 100 times a second of its own (none: no sound, or not a film). Read
  /// on another isolate, the file decoded once: the window does not wait.
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

  /// How loud a film's sound is at [n] moments of the document from [from] to before [to], where its film shows them
  /// (dB; -100 silent or not shown). null: its sound not read yet ([loudness] reads it); empty: no sound.
  Future<List<double>?> loudnessOver(int layer, double from, double to, int n) => _ask((l, m) {
    final out = malloc<Float>(n < 1 ? 1 : n);
    final got = c.MotoliiBindings(l).motolii_loudness_over(m, layer, from, to, n, out);
    final all = got < 0 ? null : [for (var i = 0; i < got; i++) out[i].toDouble()];
    malloc.free(out);
    return all;
  });

  /// Where a film's sound strikes (grows [rise] dB louder at once): the document's moments where it shows them.
  /// Asked once its loudness has been read ([loudness]).
  Future<List<double>> strikes(int layer, double rise) => _ask((l, m) {
    final ask = c.MotoliiBindings(l).motolii_strikes;
    final n = ask(m, layer, rise, 0, nullptr, 0), out = malloc<Double>(n < 1 ? 1 : n);
    final got = ask(m, layer, rise, 0, out, n), all = [for (var i = 0; i < got && i < n; i++) out[i]];
    malloc.free(out);
    return all;
  });

  /// The film's picture so many seconds in (a tenth's nearest), small: a bar on the timeline shows what it plays.
  Future<String?> videoFrame(String video, double seconds) =>
      _thumbnails['$video@${(seconds * 10).round()}'] ??= _thumbnail(libPath, video, 0, 1, (seconds * 10).round() / 10);

  /// A picture [step] of [steps] along the film (a tile looked along by the hand's place on it, or played); step 0: its first,
  /// small, as a .png file (null: none could be made). Made once and on another isolate: the window does not wait.
  Future<String?> thumbnailAt(String video, int step, int steps) =>
      step == 0 ? _thumbnails[video] ??= _thumbnail(libPath, video) : _thumbnails['$video#$step/$steps'] ??= _thumbnail(libPath, video, step, steps);

  /// A ticket's answer when it comes, and why not if refused: Thermion's VoidCallbackRegistry, as it is (a Completer under
  /// each request's number, completed when the inside says an answer is there: motolii_add_listener 8). Nothing looks again and again.
  Future<(int, String)> answered(int ticket) {
    final a = answer(ticket);
    if (a >= 0) return Future.value((a, a >= 1 ? '' : answerWhy));
    return (_waiting[ticket] ??= Completer<(int, String)>()).future;
  }

  /// A ticket's answer: -1 not done yet, 0 refused ([answerWhy] says why), 1 done; said once.
  int answer(int ticket) {
    final a = _answer(_m, ticket);
    if (a >= 0) _take(3); // (done: the pictures as the inside made them before it answered)
    return a;
  }

  String get answerWhy => _answerWhy(_m).toDartString();
}
