// View › Skin lists the skins of shelves/skins and of skins/ in the maker's own folder, as every shelf is read
// (engine/document/folders.h doc_folders). Run from app/:
//   MOTOLII_OWN=$(mktemp -d) flutter test --no-pub test/skin_folders_test.dart
// (without MOTOLII_OWN the own-folder case is skipped: the test writes nothing into a real maker's folder)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/bridge/motolii.dart' show motoliiOwn, motoliiShelves;
import 'package:motolii/style/theme.dart';

void main() {
  test('the library\'s skins (shelves/skins) are in View › Skin', () {
    final shipped = [
      for (final d in Directory('$motoliiShelves/skins').listSync().whereType<Directory>())
        if (File('${d.path}/theme.xml').existsSync()) d.uri.pathSegments[d.uri.pathSegments.length - 2],
    ];
    expect(shipped, isNotEmpty);
    expect(ColorTheme.skinNames(), containsAll(shipped));
  });

  test('a skin put in skins/ of the own folder is in View › Skin', () {
    final skin = Directory('$motoliiOwn/skins/own_folder_test_skin')..createSync(recursive: true);
    addTearDown(() => skin.deleteSync(recursive: true));
    File('${skin.path}/theme.xml').writeAsStringSync('<Motolii><Theme><Background Value="#ffd400"/></Theme></Motolii>');
    expect(ColorTheme.skinNames(), contains('own_folder_test_skin'));
  }, skip: Platform.environment['MOTOLII_OWN'] == null ? 'MOTOLII_OWN not set: nothing is written into a real own folder' : false);
}
