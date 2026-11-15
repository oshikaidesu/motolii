// Plays a sound file with macOS's afplay, for the Media shelf's preview before a file is placed.
import 'dart:io';

class SoundPlay {
  SoundPlay._(this._process);
  final Process _process;

  /// Stops the sound.
  void kill() => _process.kill();

  /// Completes with the player's exit code when it ends, after a [kill] too.
  Future<int> get exitCode => _process.exitCode;
}

Future<SoundPlay> playSound(String path) async =>
    SoundPlay._(await Process.start('afplay', [path]));
