import 'dart:io';

import 'package:isolate_current_directory/isolate_current_directory.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('File', () {
    late Directory dir;
    final dirFuture = addSetupAndTearDownThenGetDir();

    setUpAll(() async {
      dir = await dirFuture;
    });

    test('Can create, read, check file exists', () async {
      final result = await withCurrentDirectory(dir.path, () async {
        final file = File('hi.txt');
        await file.writeAsString('hello world');
        final text = await file.readAsString();
        return {
          'exists': await file.exists(),
          'absPath': file.absolute.path,
          'text': text,
        };
      });

      expect(result, {
        'exists': true,
        'absPath': p.join(dir.absolute.path, 'hi.txt'),
        'text': 'hello world',
      });

      // shouldn't exist in the actual current dir
      expect(await File('hi.txt').exists(), isFalse);
    });

    test('Can open file to read', () async {
      await File(p.join(dir.path, 'foo.txt')).writeAsString('foo bar');
      final result = await withCurrentDirectory(dir.path, () async {
        final file = File('foo.txt');
        final handle = await file.open();
        try {
          return String.fromCharCodes(await handle.read(5));
        } finally {
          await handle.close();
        }
      });

      expect(result, 'foo b');
    });

    test('Can rename file', () async {
      final file = await File(p.join(dir.path, 'bar.txt')).create();
      final renamedFile = await withCurrentDirectory(dir.path, () async {
        final file = File('bar.txt');
        return await file.rename('zort.txt');
      });
      expect(await file.exists(), isFalse);
      expect(await File(p.join(dir.path, 'zort.txt')).exists(), isTrue);
      expect(renamedFile.path, equals('zort.txt'));
    });

    test('Can get file stats', () async {
      await File(p.join(dir.path, 's')).writeAsString('  ');
      final result = await withCurrentDirectory(dir.path, () async {
        final file = File('s');
        final stat = await file.stat();
        return {'type': stat.type, 'size': stat.size};
      });
      expect(result, {'type': FileSystemEntityType.file, 'size': 2});
    });

    test('Can get parent Directory', () async {
      final result = await withCurrentDirectory(dir.path, () async {
        final file = File('abc.txt');
        return file.parent.absolute.path;
      });
      expect(p.canonicalize(result), p.canonicalize(dir.absolute.path));
    });
  });
}
