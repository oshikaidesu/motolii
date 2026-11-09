// What the window still asks of the shelves: how a value is shown, and what kind of thing a file is.
part of 'motolii.dart';

extension MotoliiShelves on Motolii {
  /// How a value is shown to a hand, as the inside says (null: as its range says): its look, the unit it is read in,
  /// its name in plain words, the span its knob covers (in the document's units) and the fold it lies in.
  Shown? shown(String name) => _shownOf.putIfAbsent(name, () {
    for (final part in _layer.values) {
      if ((part['shown'] as Map<String, dynamic>?)?[name] case final String said) {
        final f = said.split('\t');
        return f.length < 6
            ? null
            : Shown(f[0], f[1], f[2], double.parse(f[3]), double.parse(f[4]), f[5].isEmpty ? null : f[5], open: f.length > 6 && f[6] == '1');
      }
    }
    return null;
  });

  /// What kind of thing a file makes ('': none).
  String kindOf(String file) => _with([file], (s) => _b.motolii_kind_of(s[0]).toDartString());
}
