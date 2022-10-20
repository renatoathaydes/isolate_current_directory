import 'dart:io';

import 'package:isolate_current_directory/isolate_current_directory.dart';

void main() {
  withCurrentDirectory('lib', () async {
    // File and Directory created within "withCurrentDirectory"
    // will use 'lib' as the working directory.
    final src = Directory('src');
    print('Directory src exists? ${await src.exists()}');
    await src.list(recursive: true).forEach((child) => print(' * $child'));

    // But Process methods do not currently respect Directory.current,
    // so the working directory must be explicitly provided.
    final ls = await Process.run('ls', const [],
        workingDirectory: Directory.current.path);
    print('Result of running "ls" at ${Directory.current}');
    stdout.write(ls.stdout);
    stderr.write(ls.stderr);
  });
}
