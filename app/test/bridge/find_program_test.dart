// findProgram looks a program up the way execvp does: the folders of a PATH value in order, then the fallback
// folders. The expected values follow the contract written beside it in bridge/engine_paths.dart. Each test makes
// its own folders under the system temp folder.
import 'dart:io';

import 'package:motolii/bridge/engine_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('find_program_test'));
  tearDown(() => root.deleteSync(recursive: true));

  String folder(String name) {
    final dir = Directory('${root.path}/$name')..createSync(recursive: true);
    return dir.path;
  }

  // A tiny file folder/name with the given chmod mode.
  void touch(String folderPath, String name, String mode) {
    File('$folderPath/$name').writeAsStringSync('#!/bin/sh\n');
    Process.runSync('chmod', [mode, '$folderPath/$name']);
  }

  test('finds the program in path', () {
    final a = folder('a');
    touch(a, 'tool', '755');
    expect(findProgram('tool', a, fallbacks: []), '$a/tool');
  });

  test('the order of path decides between two folders', () {
    final first = folder('first'), second = folder('second');
    touch(first, 'tool', '755');
    touch(second, 'tool', '755');
    expect(
      findProgram('tool', '$second:$first', fallbacks: []),
      '$second/tool',
    );
    expect(findProgram('tool', '$first:$second', fallbacks: []), '$first/tool');
  });

  test('finds the program in the fallbacks when path has none', () {
    final inPath = folder('in_path'), fallback = folder('fallback');
    touch(fallback, 'tool', '755');
    expect(
      findProgram('tool', inPath, fallbacks: [fallback]),
      '$fallback/tool',
    );
  });

  test('path wins over the fallbacks', () {
    final inPath = folder('in_path'), fallback = folder('fallback');
    touch(inPath, 'tool', '755');
    touch(fallback, 'tool', '755');
    expect(findProgram('tool', inPath, fallbacks: [fallback]), '$inPath/tool');
  });

  test('a file without the execute bit is skipped for the next folder', () {
    final plain = folder('plain'), runnable = folder('runnable');
    touch(plain, 'tool', '644');
    touch(runnable, 'tool', '755');
    expect(
      findProgram('tool', '$plain:$runnable', fallbacks: []),
      '$runnable/tool',
    );
  });

  test('a directory with that name is skipped', () {
    final withDir = folder('with_dir'), runnable = folder('runnable');
    Directory('$withDir/tool').createSync();
    touch(runnable, 'tool', '755');
    expect(
      findProgram('tool', '$withDir:$runnable', fallbacks: []),
      '$runnable/tool',
    );
  });

  test('returns the name when nothing matches', () {
    expect(
      findProgram('tool', folder('empty'), fallbacks: [folder('also_empty')]),
      'tool',
    );
  });

  test('a name with a slash is returned as it is, even if path holds a file of that name', () {
    final a = folder('a');
    touch(a, 'tool', '755');
    expect(findProgram('sub/tool', a, fallbacks: []), 'sub/tool');
    expect(findProgram('./tool', a, fallbacks: []), './tool');
  });

  test('an empty path and empty entries are skipped, and the fallbacks are still used', () {
    final a = folder('a'), fallback = folder('fallback');
    touch(a, 'tool', '755');
    touch(fallback, 'other', '755');
    expect(findProgram('other', '', fallbacks: [fallback]), '$fallback/other');
    expect(findProgram('other', ':', fallbacks: [fallback]), '$fallback/other');
    expect(findProgram('tool', '::$a:', fallbacks: []), '$a/tool');
    expect(findProgram('tool', ':$a', fallbacks: []), '$a/tool');
    expect(findProgram('tool', '', fallbacks: []), 'tool');
  });

  test('a folder entry ending in a slash gives one slash', () {
    final a = folder('a'), fallback = folder('fallback');
    touch(a, 'tool', '755');
    touch(fallback, 'other', '755');
    expect(findProgram('tool', '$a/', fallbacks: []), '$a/tool');
    expect(
      findProgram('other', '', fallbacks: ['$fallback/']),
      '$fallback/other',
    );
  });
}
