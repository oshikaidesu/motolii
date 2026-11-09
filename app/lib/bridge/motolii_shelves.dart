// What the window still asks of the shelves: how a value is shown, a font's missing letters, what kind of thing a file is.
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

  /// The letters of [words] a font file has not (each once; '' none), and the font a text of them is drawn in instead
  /// ('' none has them all): the inside's motolii_font_lacks, a font's own letters by its cmap, Noto Sans JP first.
  (String, String) fontLacks(String font, String words) {
    final said = _with([font, words], (s) => _fontLacks(s[0], s[1]).toDartString()).split('\t');
    return (said.first, said.length > 1 ? said[1] : '');
  }

  /// What kind of thing a file makes ('': none).
  String kindOf(String file) => _with([file], (s) => _kindOf(s[0]).toDartString());

  /// Name and file from the inside's tab-separated list. The later columns were the shelf's labels and pictures.
  List<(String, String)> _labelled(String lines) => [
    for (final w in [for (final l in lines.split('\n')) l.split('\t')])
      if (w.length >= 2 && w[0].isNotEmpty) (w[0], w[1]),
  ];
}
