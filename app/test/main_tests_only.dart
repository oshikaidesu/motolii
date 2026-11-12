// `flutter test` runs the main tests only: those whose expected values come from outside the code under test
// (docs/TESTING.md, "The rule for tests"). Every other test file starts its main with skipUnlessEveryTest, and runs only
// when every test is asked for by name:
//   flutter test --dart-define=MOTOLII_RUN_EVERY_TEST=yes
// The switch is a --dart-define and not --run-skipped, because --run-skipped also runs skin_folders_test's own-folder
// case, which then writes into the maker's real ~/.motolii.
import 'package:flutter_test/flutter_test.dart';

const _everyTest = String.fromEnvironment('MOTOLII_RUN_EVERY_TEST') == 'yes';

/// True when the calling file is to be left out; one skipped test is then left in its place, saying how to run it.
bool skipUnlessEveryTest() {
  if (_everyTest) return false;
  test(
    'not a main test',
    () {},
    skip: 'run with flutter test --dart-define=MOTOLII_RUN_EVERY_TEST=yes',
  );
  return true;
}
