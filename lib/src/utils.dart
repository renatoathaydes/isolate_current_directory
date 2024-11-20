import 'dart:async';
import 'dart:io';

import 'package:isolate_current_directory/isolate_current_directory.dart';
import 'package:path/path.dart' as p;

String absPath(String path, [String? dir]) {
  final normalPath =
      p.isAbsolute(path) ? path : p.join(dir ?? _findWorkingDir(), path);
  return p.canonicalize(normalPath);
}

String _findWorkingDir() {
  final zoneWorkingDir = _findZoneWorkingDir();
  if (zoneWorkingDir != null) {
    if (p.isAbsolute(zoneWorkingDir)) {
      return zoneWorkingDir;
    }
    return p.join(Directory.current.path, zoneWorkingDir);
  }
  return Directory.current.path;
}

String? _findZoneWorkingDir() {
  Zone? zone = Zone.current;
  while (zone != null) {
    final zoneWorkingDir = zone[workingDirZoneKey];
    if (zoneWorkingDir != null) {
      return zoneWorkingDir as String;
    }
    zone = zone.parent;
  }
  return null;
}
