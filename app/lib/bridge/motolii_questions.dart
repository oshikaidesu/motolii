// Async engine queries (isolate or platform channel). See docs/app/BRIDGE.md Q.
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart' show MethodChannel;

import 'package:ffi/ffi.dart';

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_bindings.dart' as c;
import 'package:motolii/bridge/motolii_writes.dart';

const _channel = MethodChannel('motolii/stage');

/// Cached video thumbnail, keyed by path + mtime.
final _thumbnails = <String, Future<String?>>{};
Future<String?> _thumbnail(
  String lib,
  String video, [
  int step = 0,
  int steps = 1,
  double? seconds,
]) async {
  final folder = Directory('${Directory.systemTemp.path}/motolii_thumbnails')
    ..createSync(recursive: true);
  final named = video.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
  final png =
      '${folder.path}/${named.length > 150 ? named.substring(named.length - 150) : named}_${File(video).statSync().modified.millisecondsSinceEpoch}${seconds != null
          ? '_s${(seconds * 10).round()}'
          : step == 0
          ? ''
          : '_$step'}.png';
  if (File(png).existsSync()) return png;
  final made = await askEngine(
    lib,
    [video, png],
    (b, w) =>
        (seconds != null
            ? b.motolii_thumbnail_seconds(w[0], w[1], 160, seconds)
            : b.motolii_thumbnail_at(w[0], w[1], 240, step / steps)) !=
        0,
  );
  return made ? png : null;
}

extension MotoliiQuestions on Motolii {
  /// Stage as a Flutter texture (-1 if unavailable). The render thread opens it.
  Future<int> texture() async {
    final (a, _) = await answered(later('live'));
    if (a == 0) return -1;
    return await _channel.invokeMethod<int>('start', {
          'lib': libPath,
          'handle': handle.address,
        }) ??
        -1;
  }

  /// Tool panel texture (-1 if unavailable).
  Future<int> deskTexture() async => deskId ??=
      await _channel.invokeMethod<int>('start', {
        'lib': libPath,
        'handle': handle.address,
        'front': 'motolii_desk_front',
        'frames': 'motolii_desk_frames',
      }) ??
      -1;

  /// Exports the project as .mp4 on another isolate.
  Future<bool> exportVideo(String mp4) {
    final lib = libPath, at = handle.address;
    return Isolate.run(() {
      final ask = c.MotoliiBindings(DynamicLibrary.open(lib)).motolii_export;
      final to = mp4.toNativeUtf8();
      final done = ask(EngineHandle.fromAddress(at), to) != 0;
      malloc.free(to);
      return done;
    });
  }

  /// Export progress 0→1. Safe to call on UI thread (atomically updated per frame).
  double exportFraction() => bindings.motolii_export_fraction(handle);

  /// Cancel the running export at the next frame boundary.
  void cancelExport() => bindings.motolii_export_cancel(handle);

  /// Each property as the stage shows it at the given time (after relations). Null if none. Isolate.
  Future<List<double?>> shownAt(List<(int, String, double)> asks) {
    final lib = libPath, at = handle.address;
    return Isolate.run(() {
      final l = DynamicLibrary.open(lib), m = EngineHandle.fromAddress(at);
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

  /// For each font, the index of the first of [words] it can render, or -1. Isolate.
  Future<List<int>> settingFirst(List<String> fonts, List<String> words) {
    final lib = libPath;
    return Isolate.run(() {
      final ask = c.MotoliiBindings(DynamicLibrary.open(lib)).motolii_sets;
      final said = [for (final w in words) w.toNativeUtf8()], out = <int>[];
      for (final f in fonts) {
        final file = f.toNativeUtf8();
        // cmap check: faster than ThorVG's full file read (type_sets).
        out.add(said.indexWhere((w) => ask(file, w) != 0));
        malloc.free(file);
      }
      said.forEach(malloc.free);
      return out;
    });
  }

  /// Renders [words] in each font as white-on-black [w]×[h] bitmaps. Null if nothing drawn. Isolate.
  Future<List<Uint8List?>> typePictures(
    List<String> fonts,
    String words,
    int w,
    int h, {
    double most = 0,
  }) {
    final lib = libPath;
    return Isolate.run(() {
      final ask = c.MotoliiBindings(DynamicLibrary.open(lib))
          .motolii_type_frame;
      final said = words.toNativeUtf8(),
          out = malloc<UnsignedChar>(w * h),
          all = <Uint8List?>[];
      for (final f in fonts) {
        final file = f.toNativeUtf8();
        all.add(
          ask(file, said, w, h, most, out) != 0
              ? Uint8List.fromList(out.cast<Uint8>().asTypedList(w * h))
              : null,
        );
        malloc.free(file);
      }
      malloc.free(said);
      malloc.free(out);
      return all;
    });
  }

  /// CLIP image encoding: 224×224 RGBA → 512-float vector. Null if model is missing. Isolate.
  Future<List<Float32List>?> likeness(String model, List<Uint8List> pictures) {
    final lib = libPath;
    return Isolate.run(() {
      const side = 224 * 224 * 4, dims = 512;
      final n = pictures.length,
          file = model.toNativeUtf8(),
          into = malloc<UnsignedChar>(n * side + 1),
          out = malloc<Float>(n * dims + 1);
      for (final (i, p) in pictures.indexed) {
        into
            .cast<Uint8>()
            .asTypedList(n * side)
            .setRange(i * side, (i + 1) * side, p);
      }
      final encoded =
          n > 0 &&
          c.MotoliiBindings(DynamicLibrary.open(lib))
                  .motolii_likeness(file.cast(), into, n, dims, out) !=
              0;
      final all = encoded
          ? [
              for (var i = 0; i < n; i++)
                Float32List.fromList(
                  out.asTypedList(n * dims).sublist(i * dims, (i + 1) * dims),
                ),
            ]
          : null;
      malloc.free(file);
      malloc.free(into);
      malloc.free(out);
      return all;
    });
  }

  /// t-SNE layout: each point → (x, y) in [0,1]. Null if < 4 points. Isolate.
  Future<List<(double, double)>?> map(List<Float32List> points) {
    final lib = libPath;
    return Isolate.run(() {
      final n = points.length, dims = n == 0 ? 0 : points.first.length;
      final at = malloc<Float>(n * dims + 1), xy = malloc<Double>(2 * n + 1);
      for (var i = 0; i < n; i++) {
        at.asTypedList(n * dims).setRange(i * dims, (i + 1) * dims, points[i]);
      }
      final got = c.MotoliiBindings(DynamicLibrary.open(lib))
          .motolii_map(at, n, dims, xy);
      final laid = got == 0
          ? null
          : [for (var i = 0; i < n; i++) (xy[2 * i], xy[2 * i + 1])];
      malloc.free(at);
      malloc.free(xy);
      return laid;
    });
  }

  /// Motion path: [n] samples of (x, y, rotation, scale) from [from] to [to]. Null if no such layer.
  Future<List<double>?> path(
    int layer, {
    double from = 0,
    required double to,
    int n = 60,
  }) => _ask((l, m) {
    final out = malloc<Double>(4 * n);
    final got = c.MotoliiBindings(l)
        .motolii_path(m, layer, 0, from, to, n, out);
    final p = [for (var i = 0; i < 4 * got; i++) out[i]];
    malloc.free(out);
    return got > 0 ? p : null;
  });

  /// Run a query on another isolate.
  Future<T> _ask<T>(T Function(DynamicLibrary lib, EngineHandle m) ask) {
    final lib = libPath, at = handle.address;
    return Isolate.run(
      () => ask(DynamicLibrary.open(lib), EngineHandle.fromAddress(at)),
    );
  }

  /// Like [path] but in 3D: (x, y, z, scale) per sample.
  List<double>? path3(
    int layer, {
    int copy = 0,
    required double to,
    int n = 24,
  }) {
    final out = malloc<Double>(4 * n);
    final got = bindings.motolii_path3(handle, layer, copy, 0, to, n, out),
        p = [for (var i = 0; i < 4 * got; i++) out[i]];
    malloc.free(out);
    return got > 0 ? p : null;
  }

  /// Loudness in dB (0 = full scale), 100 samples/s. Decoded once. Isolate.
  Future<List<double>> loudness(int layer) {
    final lib = libPath, at = handle.address;
    return Isolate.run(() {
      final ask = c.MotoliiBindings(DynamicLibrary.open(lib)).motolii_loudness;
      final m = EngineHandle.fromAddress(at),
          n = ask(m, layer, nullptr, 0),
          out = malloc<Float>(n < 1 ? 1 : n);
      final got = ask(m, layer, out, n),
          all = [for (var i = 0; i < got && i < n; i++) out[i].toDouble()];
      malloc.free(out);
      return all;
    });
  }

  /// Loudness over [n] project times. -100 = silent. Null if not yet read ([loudness]).
  Future<List<double>?> loudnessOver(
    int layer,
    double from,
    double to,
    int n,
  ) => _ask((l, m) {
    final out = malloc<Float>(n < 1 ? 1 : n);
    final got = c.MotoliiBindings(l)
        .motolii_loudness_over(m, layer, from, to, n, out);
    final all = got < 0
        ? null
        : [for (var i = 0; i < got; i++) out[i].toDouble()];
    malloc.free(out);
    return all;
  });

  /// Times where the sound jumps by [rise] dB. Call after [loudness].
  Future<List<double>> strikes(int layer, double rise) => _ask((l, m) {
    final ask = c.MotoliiBindings(l).motolii_strikes;
    final n = ask(m, layer, rise, 0, nullptr, 0),
        out = malloc<Double>(n < 1 ? 1 : n);
    final got = ask(m, layer, rise, 0, out, n),
        all = [for (var i = 0; i < got && i < n; i++) out[i]];
    malloc.free(out);
    return all;
  });

  /// Video frame thumbnail at [seconds] (rounded to 0.1 s).
  Future<String?> videoFrame(String video, double seconds) =>
      _thumbnails['$video@${(seconds * 10).round()}'] ??= _thumbnail(
        libPath,
        video,
        0,
        1,
        (seconds * 10).round() / 10,
      );

  /// Video thumbnail at step [step]/[steps]. Made once, isolate.
  Future<String?> thumbnailAt(String video, int step, int steps) => step == 0
      ? _thumbnails[video] ??= _thumbnail(libPath, video)
      : _thumbnails['$video#$step/$steps'] ??= _thumbnail(
          libPath,
          video,
          step,
          steps,
        );

  /// Waits for a ticket's answer: (status, reason or script reply). One Completer per ticket, no polling.
  Future<(int, String)> answered(int ticket) {
    final a = answer(ticket);
    if (a >= 0) return Future.value((a, answerWhy));
    return (waiting[ticket] ??= Completer<(int, String)>()).future;
  }

  /// Asks a running script [file] the JavaScript [js] and returns its text answer. Read-only.
  Future<String> askScript(String file, String js) async =>
      (await answered(later('ask', name: file, word: js))).$2;

  /// -1 pending, 0 refused, 1 done. Each answer reported once.
  int answer(int ticket) {
    final a = bindings.motolii_answer(handle, ticket);
    // Read snapshots made before the answer.
    if (a >= 0) takeSnapshots(3);
    return a;
  }
}
