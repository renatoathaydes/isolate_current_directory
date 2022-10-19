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

    test('Can create and check file exists', () async {
      final result = await withCurrentDirectory(dir.path, () async {
        final file = File('hi.txt');
        await file.writeAsString('hello world');
        return {'exists': await file.exists(), 'absPath': file.absolute.path};
      });

      expect(result,
          {'exists': true, 'absPath': p.join(dir.absolute.path, 'hi.txt')});

      // shouldn't exist in the actual current dir
      expect(await File('hi.txt').exists(), isFalse);
    });
  });
}
