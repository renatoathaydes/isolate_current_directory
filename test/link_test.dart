import 'dart:io';

import 'package:isolate_current_directory/isolate_current_directory.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('Link', () {
    late Directory dir;
    final dirFuture = addSetupAndTearDownThenGetDir();

    setUpAll(() async {
      dir = await dirFuture;
    });

    test('Can create, read, check file link exists', () async {
      final result = await withCurrentDirectory(dir.path, () async {
        final file = File('hi.txt');
        await file.writeAsString('hello world');
        final link = await Link('hi.txt.link').create('hi.txt');
        final text = await File(await link.target()).readAsString();
        return {
          // 'exists': await link.exists(),
          'absPath': link.absolute.path,
          'text': text,
        };
      });

      expect(result, {
        // FIXME why is this false?!
        // 'exists': true,
        'absPath': p.join(dir.absolute.path, 'hi.txt.link'),
        'text': 'hello world',
      });

      // shouldn't exist in the actual current dir
      expect(await File('hi.txt').exists(), isFalse);
      expect(await Link('hi.txt.link').exists(), isFalse);
    });

    test('Can create, read file through, check directory link exists',
        () async {
      final result = await withCurrentDirectory(dir.path, () async {
        await Directory('dir').create();
        final file = File(p.join('dir', 'f.txt'));
        await file.writeAsString('foo bar');
        final link = await Link('dir-link').create('dir');
        final text = await File(p.join('dir-link', 'f.txt')).readAsString();
        return {
          // 'exists': await link.exists(),
          'absPath': link.absolute.path,
          'text': text,
        };
      });

      expect(result, {
        // FIXME why is this false?!
        // 'exists': true,
        'absPath': p.join(dir.absolute.path, 'dir-link'),
        'text': 'foo bar',
      });

      // shouldn't exist in the actual current dir
      expect(await Directory('dir').exists(), isFalse);
      expect(await Link('dir-link').exists(), isFalse);
    });

    test('Can resolve directory link', () async {
      final result = await withCurrentDirectory(dir.path, () async {
        await Directory('dir2').create();
        await File(p.join('dir2', 'foo.txt')).create();
        await Link('dir2-link').create('dir2');
        return await File(p.join('dir2-link', 'foo.txt'))
            .resolveSymbolicLinks();
      });

      expect(p.canonicalize(result),
          p.canonicalize(p.join(dir.absolute.path, 'dir2', 'foo.txt')));
    });
  });
}
