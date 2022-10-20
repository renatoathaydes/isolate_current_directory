import 'dart:io';

import 'package:path/path.dart' as p;

String absPath(String path, [String? dir]) {
  return p.isAbsolute(path)
      ? path
      : p.join(dir ?? Directory.current.path, path);
}
