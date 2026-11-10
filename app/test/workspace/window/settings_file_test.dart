// The file helpers every kept list uses: firstFree, fileKeep, fileJson and fileList. The expected values are what the
// code gave when this was written, so a move that changes one fails here. Writes only into a folder of its own in the
// system's temp folder; needs no engine. WindowFile reads the maker's own ~/.motolii/window.xml and is not tested here.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/window/settings_file.dart';

void main() {
  late Directory folder;
  setUp(() => folder = Directory.systemTemp.createTempSync('settings_file_test'));
  tearDown(() => folder.deleteSync(recursive: true));

  test('firstFree gives the name itself when it is free, else the first numbered one from 2 that is', () {
    String free(Set<String> taken) => firstFree('Deck', taken.contains, (n) => 'Deck $n');
    expect(free({}), 'Deck');
    expect(free({'Deck'}), 'Deck 2');
    expect(free({'Deck', 'Deck 2', 'Deck 3'}), 'Deck 4');
    expect(free({'Deck', 'Deck 3'}), 'Deck 2');
  });

  test('fileKeep writes text, making the folders on the way, and fileJson reads it back', () {
    final file = File('${folder.path}/made/on/the/way/kept.json');
    fileKeep(file, '{"decks": ["a", 2]}');
    expect(fileJson(file), {
      'decks': ['a', 2],
    });
  });

  test('fileKeep writes bytes as they are', () {
    final file = File('${folder.path}/kept.json');
    fileKeep(file, '[7]'.codeUnits);
    expect(file.readAsStringSync(), '[7]');
  });

  test('fileKeep ignores a place it cannot write to', () {
    final file = File('${folder.path}/kept.json')..writeAsStringSync('[]');
    fileKeep(File('${file.path}/inside.json'), 'never written');
    expect(file.readAsStringSync(), '[]');
  });

  test('fileJson gives null for a missing file and for text that is not JSON', () {
    expect(fileJson(File('${folder.path}/missing.json')), isNull);
    expect(fileJson(File('${folder.path}/kept.json')..writeAsStringSync('not json')), isNull);
  });

  test('fileList gives the list a file holds, and an empty one for anything else', () {
    final file = File('${folder.path}/kept.json')..writeAsStringSync('["a", 2]');
    expect(fileList(file), ['a', 2]);
    expect(fileList(file..writeAsStringSync('{"a": 2}')), isEmpty);
    expect(fileList(file..writeAsStringSync('not json')), isEmpty);
    expect(fileList(File('${folder.path}/missing.json')), isEmpty);
  });
}
