import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'file.dart';
import 'link.dart';
import 'utils.dart';

class IsolatedDirectory implements Directory {
  @override
  final String path;

  final Zone _parentZone;

  IsolatedDirectory._(this.path, this._parentZone);

  static Directory of(String path, Zone parentZone) {
    return IsolatedDirectory._(path, parentZone);
  }

  @override
  String toString() => 'IsolatedDirectory{path: $path}';

  @override
  Directory get absolute {
    final wd = Directory.current.path;
    return Zone.root.run(() => Directory(p.join(wd, path)));
  }

  @override
  Future<Directory> create({bool recursive = false}) async {
    await absolute.create(recursive: recursive);
    return this;
  }

  @override
  void createSync({bool recursive = false}) {
    absolute.createSync(recursive: recursive);
  }

  @override
  Future<Directory> createTemp([String? prefix]) async {
    final tmp = await absolute.createTemp(prefix);
    return IsolatedDirectory.of(
        p.join(path, p.basename(tmp.path)), _parentZone);
  }

  @override
  Directory createTempSync([String? prefix]) {
    final tmp = absolute.createTempSync(prefix);
    return IsolatedDirectory.of(
        p.join(path, p.basename(tmp.path)), _parentZone);
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    await absolute.delete(recursive: recursive);
    return this;
  }

  @override
  void deleteSync({bool recursive = false}) {
    absolute.deleteSync(recursive: recursive);
  }

  @override
  Future<bool> exists() {
    return absolute.exists();
  }

  @override
  bool existsSync() {
    return absolute.existsSync();
  }

  @override
  bool get isAbsolute => p.isAbsolute(path);

  @override
  Stream<FileSystemEntity> list(
      {bool recursive = false, bool followLinks = true}) async* {
    final abs = absolute;
    final startIndex = abs.path.length - path.length;
    await for (final item
        in abs.list(recursive: recursive, followLinks: followLinks)) {
      final childPath = item.path.substring(startIndex);
      yield item.withPath(childPath, _parentZone);
    }
  }

  @override
  List<FileSystemEntity> listSync(
      {bool recursive = false, bool followLinks = true}) {
    final abs = absolute;
    final startIndex = abs.path.length - path.length;
    return abs
        .listSync(recursive: recursive, followLinks: followLinks)
        .map((item) {
      final childPath = item.path.substring(startIndex);
      return item.withPath(childPath, _parentZone);
    }).toList();
  }

  @override
  Directory get parent => IsolatedDirectory._(p.dirname(path), _parentZone);

  @override
  Future<Directory> rename(String newPath) async {
    await absolute.rename(absPath(newPath));
    return IsolatedDirectory.of(newPath, _parentZone);
  }

  @override
  Directory renameSync(String newPath) {
    absolute.renameSync(absPath(newPath));
    return IsolatedDirectory.of(newPath, _parentZone);
  }

  @override
  Future<String> resolveSymbolicLinks() {
    return absolute.resolveSymbolicLinks();
  }

  @override
  String resolveSymbolicLinksSync() {
    return absolute.resolveSymbolicLinksSync();
  }

  @override
  Future<FileStat> stat() {
    return FileStat.stat(path);
  }

  @override
  FileStat statSync() {
    return FileStat.statSync(path);
  }

  @override
  Uri get uri => absolute.uri;

  @override
  Stream<FileSystemEvent> watch(
      {int events = FileSystemEvent.all, bool recursive = false}) {
    return absolute.watch(events: events, recursive: recursive);
  }
}

extension _EntityPathExt on FileSystemEntity {
  FileSystemEntity withPath(String newPath, Zone parentZone) {
    if (this is File) return IsolatedFile.of(newPath, parentZone);
    if (this is Directory) return IsolatedDirectory.of(newPath, parentZone);
    return IsolatedLink.of(newPath, parentZone);
  }
}
