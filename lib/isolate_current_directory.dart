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

import 'src/directory.dart';
import 'src/file.dart';
import 'src/utils.dart';

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

/// Run the given [action] using [directory] as the working directory.
///
/// Within the scope of [action], any [File], [Directory] and [Link]
/// created will be relative to [directory]. [FileStat] methods will also
/// work as expected.
///
/// `Directory.current` is scoped within the [action] and will return the given
/// [directory] unless modified within [action]. The global value of
/// `Directory.current` is not affected by this function.
FutureOr<T> withCurrentDirectory<T>(
    String directory, FutureOr<T> Function() action) {
  final parentZone = Zone.current;
  final zoneVariables = _ZoneVariables(_dir(absPath(directory)));

  return IOOverrides.runZoned(() async => await action(),
      createDirectory: (p) => IsolatedDirectory.of(p, parentZone),
      createFile: (p) => IsolatedFile.of(p, parentZone),
      stat: (p) => parentZone.runBinary(_stat, directory, p),
      statSync: (p) => parentZone.runBinary(_statSync, directory, p),
      getCurrentDirectory: () => zoneVariables.currentDirectory,
      setCurrentDirectory: (path) {
        zoneVariables.currentDirectory = parentZone.runUnary(_dir, path);
      });
}
