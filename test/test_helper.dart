import 'dart:io';
import 'dart:math' show Random;

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Future<Directory> addSetupAndTearDownThenGetDir() async {
  final tempDir =
      Directory(p.join('test', 'temp', Random().nextInt(999999999).toString()));

  setUp(() async {
    expect(await tempDir.exists(), isFalse);
    await tempDir.create();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  return tempDir;
}

/// On Windows, paths seem to sometimes include a lowercase drive,
/// sometimes an uppercase drive. So we need to fix that.
String Function(String) _fixPathOnWindows = Platform.isWindows
    ? (path) {
        if (p.isAbsolute(path)) {
          final idx = path.indexOf(':');
          if (idx > 0) {
            final drive = path.substring(0, idx);
            return '${drive.toLowerCase()}${path.substring(idx)}';
          }
        }
        return path;
      }
    : (path) => path;

extension PathExtension on FileSystemEntity {
  String get absolutePath => _fixPathOnWindows(absolute.path);
}
