// A font file as the Fonts shelf offers it.

/// A font file offered on the shelf.
class FontFile {
  /// The font named [family], read from the file [path].
  const FontFile(this.family, {this.path, this.script, this.sample});

  /// The name the font is listed under: its file's name.
  final String family;

  /// The font file.
  final String? path;

  /// For a font without Latin letters: its script, and a sample text in that script (from samples.json).
  final String? script, sample;
}

/// The sample line each font is shown with.
const fontSampleLine = 'Motion for more relations';
