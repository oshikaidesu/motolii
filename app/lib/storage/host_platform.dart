// What the host is: its system, its processor, its login shell and its environment. Panels import this instead of
// dart:io and dart:ffi.
import 'dart:ffi' show Abi;
import 'dart:io';

bool get hostIsWindows => Platform.isWindows;

bool get hostIsMacOS => Platform.isMacOS;

/// The system's name, as a registry spells it: `darwin` on macOS, else Dart's own name.
String get hostOperatingSystem =>
    Platform.isMacOS ? 'darwin' : Platform.operatingSystem;

/// Whether the processor is arm64.
bool get hostIsArm64 => '${Abi.current()}'.contains('arm64');

/// The login shell, or /bin/sh when the launch has none.
String get loginShell => Platform.environment['SHELL'] ?? '/bin/sh';

/// The user's home folder, from the launch's environment.
String? get homeFolder => Platform.environment['HOME'];

/// The system's temporary folder.
String get tempFolder => Directory.systemTemp.path;
