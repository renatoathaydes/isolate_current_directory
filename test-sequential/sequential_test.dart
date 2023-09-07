import 'dart:async';
import 'dart:io';

import 'package:isolate_current_directory/isolate_current_directory.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test/test_helper.dart';

final pathEquals = Platform.isWindows ? equalsIgnoringCase : equals;

void main() {
  group('Sequential Tests', () {
    late Directory dir;
    final dirFuture = addSetupAndTearDownThenGetDir();

    setUpAll(() async {
      dir = await dirFuture;
    });

    test('Can change global Directory without affecting withCurrentDirectory',
        () async {
      final initialCurrentDir = Directory.current.path;
      await Directory(p.join(dir.path, 'my-unique-dir')).create();
      final globalDirChanged = Completer();
      final resultFuture = withCurrentDirectory(dir.path, () async {
        await globalDirChanged.future;
        return await Directory('my-unique-dir').exists();
      });

      Directory.current = p.join(initialCurrentDir, 'example');
      globalDirChanged.complete(null);

      try {
        expect(await resultFuture, isTrue);
      } finally {
        Directory.current = initialCurrentDir;
      }
    });

    test(
        'Changing the current dir inside withCurrentDirectory '
        'does not change the outer scope current dir', () async {
      final initialCurrentDir = Directory.current.path;
      await Directory(p.join(dir.path, 'my-other-dir')).create();
      final innerCurrent = await withCurrentDirectory(dir.path, () async {
        Directory.current = Directory('my-other-dir').absolute.path;
        await File('hello').writeAsString('foo');
        return Directory.current.path;
      });
      expect(Directory.current.path, pathEquals(initialCurrentDir));
      expect(
          innerCurrent, pathEquals(p.join(dir.absolute.path, 'my-other-dir')));
      expect(
          await File(p.join(dir.path, 'my-other-dir', 'hello')).readAsString(),
          equals('foo'));
    });
  });
}
