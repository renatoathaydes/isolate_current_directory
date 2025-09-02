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
import 'src/link.dart';
import 'src/utils.dart';

Future<FileStat> _stat(String dir, String path) {
  return FileStat.stat(absPath(path, dir));
}

FileStat _statSync(String dir, String path) {
  return FileStat.statSync(absPath(path, dir));
}

T _invoke<T>(Function onError, Object e, StackTrace stackTrace) {
  if (onError is Function(dynamic)) {
    return onError(e);
  }
  if (onError is Function(dynamic, dynamic)) {
    return onError(e, stackTrace);
  }
  // let Dart fail if this function can't be called like this
  return onError();
}

/// Run the given [action] using the given [directory] as the working directory.
///
/// Within the scope of [action], any [File], [Directory] and [Link]
/// created will be relative to [directory]. [FileStat] methods will also
/// work as expected.
///
/// The actual working directory used within the scope of [action] is the value
/// of [directory] if it's an absolute path, or else is computed
/// by immediately reading [Directory.current], then appending [directory] to
/// that.
///
/// `Directory.current` is scoped within the [action] and will return the given
/// [directory] unless modified within [action]. The global value of
/// `Directory.current` cannot, at least easily, be affected by this function,
/// so modifications are only visible within [action]'s scope. Notice that
/// the global value can still be accessed via [Zone.root], so this feature
/// cannot be used for security.
///
/// If the [onError] callback is provided, it has similar semantics to the
/// [Future.then] method's argument with the same name.
/// In other words: it must accept one or two arguments,
/// the first one being the error, and the second one, the stackTrace. It must
/// return a value compatible with the return value of [action]. If it throws,
/// this function throws the error, or if [action] is async, the returned
/// [Future] completes with that error.
FutureOr<T> withCurrentDirectory<T>(
    String directory, FutureOr<T> Function() action,
    {Function? onError}) {
  final parentZone = Zone.current;
  var zoneDir = Directory(absPath(directory));

  return IOOverrides.runZoned(
      () {
        try {
          final result = action();
          if (result is Future<T>) {
            if (onError == null) return result;
            return result.catchError(onError);
          }
          return result;
        } catch (e, stackTrace) {
          if (onError == null) {
            rethrow;
          }
          final result = _invoke(onError, e, stackTrace);
          if (identical(e, result)) {
            rethrow;
          }
          return result;
        }
      },
      createDirectory: (p) => IsolatedDirectory.of(p, parentZone),
      createFile: (p) => IsolatedFile.of(p, parentZone),
      createLink: (p) => IsolatedLink.of(p, parentZone),
      stat: (p) => parentZone.runBinary(_stat, zoneDir.path, p),
      statSync: (p) => parentZone.runBinary(_statSync, zoneDir.path, p),
      getCurrentDirectory: () => zoneDir,
      setCurrentDirectory: (path) {
        zoneDir = parentZone.runUnary(Directory.new, path);
      });
}

/// Wrap an existing function so that the returned function calls
/// [withCurrentDirectory] around it using `Directory.current.path`.
///
/// This is normally used to wrap functions meant to run on another Isolate
/// because this allows "propagating" the current directory between Isolates.
///
/// ## Example:
/// ```
/// // BEFORE
/// Isolate.run(readTextFile);
///
/// // AFTER
/// Isolate.run(wrapWithCurrentDirectory(readTextFile));
/// ```
FutureOr<T> Function() wrapWithCurrentDirectory<T>(FutureOr<T> Function() fun,
    {Function? onError}) {
  final workingDir = Directory.current.path;
  return () => withCurrentDirectory(workingDir, fun, onError: onError);
}
