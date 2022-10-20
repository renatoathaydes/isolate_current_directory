/// Dart's Directory.current can be set to change the current directory,
/// but this is a true global variable shared even between different
/// Isolates.
///
/// That makes it almost impossible to write Dart code that requires changing
/// the current working directory while using more than one Isolate, as changes
/// in one Isolate would affect all Isolates.
///
/// This library solves that problem by providing a function,
/// `withCurrentDirectory()`, which effectively changes Directory.current only
/// in the current Isolate.
///
/// It relies on [IOOverrides] to override dart:io's classes behaviour.
library isolate_current_directory;

import 'dart:async';
import 'dart:io';

import 'isolate_current_directory.dart';

export 'src/file.dart';

class _ZoneVariables {
  Directory currentDirectory;

  _ZoneVariables(this.currentDirectory);
}

Directory _dir(String path) => Directory(path);

Future<FileStat> _stat(String dir, String path) {
  return FileStat.stat(absPath(path, dir));
}

FileStat _statSync(String dir, String path) {
  return FileStat.statSync(absPath(path, dir));
}

FutureOr<T> withCurrentDirectory<T>(
    String directory, FutureOr<T> Function() action) {
  final parentZone = Zone.current;
  final zoneVariables = _ZoneVariables(_dir(absPath(directory)));

  return IOOverrides.runZoned(() async => await action(),
      createDirectory: (p) => parentZone.runUnary(_dir, p),
      createFile: (p) => IsolatedFile.of(p, parentZone),
      stat: (p) => parentZone.runBinary(_stat, directory, p),
      statSync: (p) => parentZone.runBinary(_statSync, directory, p),
      getCurrentDirectory: () => zoneVariables.currentDirectory,
      setCurrentDirectory: (path) {
        zoneVariables.currentDirectory = parentZone.runUnary(_dir, path);
      });
}
