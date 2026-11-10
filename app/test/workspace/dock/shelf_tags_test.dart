// ShelfTags: the user's own tags are kept in a file and come back, with the tags an item already has.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/dock/common/shelf_tags.dart';

void main() {
  test('own tags set on an item are read back by a new window', () {
    final dir = Directory.systemTemp.createTempSync('shelf_tags');
    addTearDown(() => dir.deleteSync(recursive: true));
    ShelfTags.ownAt(File('${dir.path}/tags.json'));

    ShelfTags().setOwn('Effects', 'corner pin', ['#Basic', ' warp ', '']);

    final again = ShelfTags();
    expect(again.ownOf('Effects', 'corner pin'), {'basic', 'warp'});
    expect(again.of('Effects', 'corner pin', {'time'}), {
      'time',
      'basic',
      'warp',
    });
    expect(again.ownOf('Effects', 'other'), isEmpty);
  });

  test('setting no tags removes the item from the file', () {
    final dir = Directory.systemTemp.createTempSync('shelf_tags');
    addTearDown(() => dir.deleteSync(recursive: true));
    ShelfTags.ownAt(File('${dir.path}/tags.json'));

    ShelfTags()
      ..setOwn('Effects', 'a', ['x'])
      ..setOwn('Effects', 'a', []);

    expect(ShelfTags().ownOf('Effects', 'a'), isEmpty);
  });
}
