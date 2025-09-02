import 'dart:async';
import 'dart:io';
import 'dart:isolate';

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

    test('Can check directory exists sync', () async {
      final directory = Directory(p.join(dir.path, 'my-dir'));
      await directory.create();
      expect(
          withCurrentDirectory(
              dir.path, () => Directory('my-dir').existsSync()),
          isTrue);
      expect(
          withCurrentDirectory(
              dir.path, () => Directory('other-dir').existsSync()),
          isFalse);
    });

    test('Can check directory exists async without await', () async {
      final directory = Directory(p.join(dir.path, 'my-dir'));
      await directory.create();
      expect(
          await withCurrentDirectory(
              dir.path, () async => Directory('my-dir').exists()),
          isTrue);
      expect(
          await withCurrentDirectory(
              dir.path, () => Directory('my-dir').exists()),
          isTrue);
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

    test('Can list Directory children', () async {
      await Directory(p.join(dir.path, 'a')).create();
      await Directory(p.join(dir.path, 'a', 'b')).create();
      await Directory(p.join(dir.path, 'a', 'c')).create();
      await File(p.join(dir.path, 'a', 't')).create();
      await File(p.join(dir.path, 'a', 'b', 'v')).create();
      final result = await withCurrentDirectory(dir.path, () async {
        final aChildren =
            await Directory('a').list().map((e) => e.path).toSet();
        final aChildrenRecursive = await Directory('a')
            .list(recursive: true)
            .map((e) => e.path)
            .toSet();
        final bChildren = await withCurrentDirectory(
            'a', () => Directory('b').listSync().map((e) => e.path).toSet());
        return {
          'aChildren': aChildren,
          'aChildrenRecursive': aChildrenRecursive,
          'bChildren': bChildren,
        };
      });
      expect(
          result,
          equals({
            'aChildren': {p.join('a', 'b'), p.join('a', 'c'), p.join('a', 't')},
            'aChildrenRecursive': {
              p.join('a', 'b'),
              p.join('a', 'c'),
              p.join('a', 't'),
              p.join('a', 'b', 'v')
            },
            'bChildren': {p.join('b', 'v')},
          }));
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

    test('Delete error propagates to caller', () {
      final resultFuture = withCurrentDirectory(dir.path, () async {
        final directory = Directory('does-not-exist');
        await directory.delete();
      });
      expect(resultFuture, throwsA(isA<FileSystemException>()));
    });

    test('Delete error propagates to caller (with error wrapper)', () {
      final resultFuture = withCurrentDirectory(dir.path,
          onError: (e) => throw {'error': e}, () async {
        final directory = Directory('does-not-exist');
        return await directory.delete();
      });

      expect(
          resultFuture,
          throwsA(isA<Map<String, dynamic>>().having(
              (m) => m['error'], 'has error key', isA<FileSystemException>())));
    });

    test('Can recover from error using onError callback (sync)', () {
      final result = withCurrentDirectory(dir.path, onError: (_) => 10, () {
        if (Directory('does-not-exist').existsSync()) {
          return 42;
        }
        throw Exception('FAIL');
      });
      expect(result, equals(10));
    });

    test('Can recover from error using onError callback (async)', () async {
      final resultFuture =
          withCurrentDirectory(dir.path, onError: (_) => 11, () async {
        if (await Directory('does-not-exist').exists()) {
          return 42;
        }
        throw Exception('FAIL');
      });
      expect(await resultFuture, equals(11));
    });

    test('Can use wrapWithCurrentDirectory in Isolate', () async {
      await File(p.join(dir.path, textFileName)).writeAsString('hello');
      await withCurrentDirectory(dir.path, () async {
        // even though we're inside withCurrentDirectory, the Isolate doesn't know it
        expect(() => Isolate.run(readTextFile),
            throwsA(isA<PathNotFoundException>()));
        // but when wrapping it into a Zone, it works
        expect(await Isolate.run(wrapWithCurrentDirectory(readTextFile)),
            equals('hello'));
      });
    });
  });
}

const textFileName = 'some-random-text-file.txt';

Future<String> readTextFile() => File(textFileName).readAsString();
