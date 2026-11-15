// The Take Snapshot still on disk: a new file in the system's temporary folder for each snapshot, shown over the stage.
import 'dart:io' show Directory, File;

import 'package:flutter/painting.dart' show FileImage, ImageProvider;

/// A new file name for a snapshot. Each is new, because Flutter's image cache identifies a file by its name.
String newSnapshotPath() =>
    '${Directory.systemTemp.path}/motolii_snapshot_${DateTime.now().microsecondsSinceEpoch}.png';

/// The snapshot image at [path], to be drawn over the stage.
ImageProvider snapshotImage(String path) => FileImage(File(path));

/// Deletes the snapshot at [path]. A file that is already gone is not an error.
void deleteSnapshot(String path) {
  try {
    File(path).deleteSync();
  } catch (_) {
    // Already gone.
  }
}
