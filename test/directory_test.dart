import 'dart:async';
import 'dart:io';

import 'package:isolate_current_directory/isolate_current_directory.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('Directory', () {
    late Directory dir;
    final dirFuture = addSetupAndTearDownThenGetDir();

    setUpAll(() async {
      dir = await dirFuture;
    });

    test('Can create, check dir exists', () async {
      final result = await withCurrentDirectory(dir.path, () async {
        final directory = Directory('hello');
        await directory.create();
        return {
          'exists': await directory.exists(),
          'absPath': directory.absolutePath,
          'path': directory.path,
        };
      });

      expect(result, {
        'exists': true,
        'absPath': p.join(dir.absolutePath, 'hello'),
        'path': 'hello',
      });

      // shouldn't exist in the actual current dir
      expect(await Directory('hello').exists(), isFalse);
    });

    test('Can rename directory', () async {
      final directory = await Directory(p.join(dir.path, 'bar')).create();
      final renamedDir = await withCurrentDirectory(dir.path, () async {
        final directory = Directory('bar');
        return await directory.rename('zort');
      });
      expect(await directory.exists(), isFalse);
      expect(await Directory(p.join(dir.path, 'zort')).exists(), isTrue);
      expect(renamedDir.path, equals('zort'));
    });

    test('Can get directory stats', () async {
      await Directory(p.join(dir.path, 's')).create();
      final result = await withCurrentDirectory(dir.path, () async {
        final directory = Directory('s');
        final stat = await directory.stat();
        return {'type': stat.type};
      });
      expect(result, {'type': FileSystemEntityType.directory});
    });

    test('Can get parent Directory', () async {
      final result = await withCurrentDirectory(dir.path, () async {
        final directory = Directory('abc');
        return directory.parent.absolutePath;
      });
      expect(p.canonicalize(result), p.canonicalize(dir.absolutePath));
    });

    test('Nested invocations to withCurrentDirectory should work', () async {
      final parentDir = await Directory(p.join(dir.path, 'inner')).create();
      await File(p.join(parentDir.path, 'nested.txt')).create();

      final result = await withCurrentDirectory(dir.path, () async {
        return await withCurrentDirectory('inner', () async {
          final file = File('nested.txt');
          return await file.exists();
        });
      });
      expect(result, isTrue);
    });

    test('Can change current Directory within withCurrentDirectory', () async {
      final initialCurrentDir = Directory.current.path;
      final lock = StreamController();
      final globalCurrentDir = Future(() async {
        await lock.stream.first;
        return Directory.current.path;
      });
      final result = await withCurrentDirectory(dir.path, () async {
        Directory.current = dir.parent.path;
        lock.add(true);
        // let globalCurrentDir be set before we complete this lambda
        await Future.delayed(Duration(milliseconds: 25));
        return await Directory(p.basename(dir.path)).exists();
      });

      expect(result, isTrue);
      expect(await globalCurrentDir, equals(initialCurrentDir));
    });

    test('Delete error propagates to caller', () async {
      final resultFuture = withCurrentDirectory(dir.path, () async {
        final directory = Directory('does-not-exist');
        await directory.delete();
      });
      expect(resultFuture, throwsA(isA<FileSystemException>()));
    });
  });
}
