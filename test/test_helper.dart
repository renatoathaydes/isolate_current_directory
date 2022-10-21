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
