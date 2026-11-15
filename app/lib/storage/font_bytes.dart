// The bytes of a font file that is not bundled with the app (see widgets/font_files.dart).
import 'dart:io';
import 'dart:typed_data';

/// The whole file at [path]. Fails when it cannot be read.
Future<Uint8List> readFontBytes(String path) => File(path).readAsBytes();
