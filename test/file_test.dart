import 'dart:io';
import 'dart:math';

import 'package:isolate_current_directory/isolate_current_directory.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('File', () {
    final tempDir = Directory(p.join('test', 'temp'));
    late Directory dir;

    setUpAll(() async {
      expect(await tempDir.exists(), isTrue);
      expect((await tempDir.list().toList()).map((e) => e.path).toList(),
          equals([p.join('test', 'temp', '.gitignore')]));
    });

    setUp(() async {
      dir = Directory(
          p.join(tempDir.path, Random().nextInt(999999999).toString()));
      await dir.create();
    });

    tearDown(() async {
      await dir.delete(recursive: true);
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
      await withCurrentDirectory(dir.path, () async {
        final file = File('bar.txt');
        await file.rename('zort.txt');
      });
      expect(await file.exists(), isFalse);
      expect(await File(p.join(dir.path, 'zort.txt')).exists(), isTrue);
    });
  });
}
