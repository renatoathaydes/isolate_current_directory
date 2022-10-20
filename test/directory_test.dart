import 'dart:io';
import 'dart:math';

import 'package:isolate_current_directory/isolate_current_directory.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Directory', () {
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

    test('Can create, check dir exists', () async {
      final result = await withCurrentDirectory(dir.path, () async {
        final directory = Directory('hello');
        await directory.create();
        return {
          'exists': await directory.exists(),
          'absPath': directory.absolute.path,
          'path': directory.path,
        };
      });

      expect(result, {
        'exists': true,
        'absPath': p.join(dir.absolute.path, 'hello'),
        'path': 'hello',
      });

      // shouldn't exist in the actual current dir
      expect(await Directory('hello').exists(), isFalse);
    });

    test('Can rename directory', () async {
      final directory = await Directory(p.join(dir.path, 'bar')).create();
      await withCurrentDirectory(dir.path, () async {
        final directory = Directory('bar');
        await directory.rename('zort');
      });
      expect(await directory.exists(), isFalse);
      expect(await Directory(p.join(dir.path, 'zort')).exists(), isTrue);
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
  });
}
