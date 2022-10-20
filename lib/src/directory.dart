import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'utils.dart';

class IsolatedDirectory implements Directory {
  @override
  final String path;

  final Zone _parentZone;

  IsolatedDirectory._(this.path, this._parentZone);

  static Directory wrapDirectory(Directory directory, Zone parentZone) {
    return directory.isAbsolute || directory is IsolatedDirectory
        ? directory
        : IsolatedDirectory._(directory.path, parentZone);
  }

  static Directory of(String path, Zone parentZone) {
    return IsolatedDirectory._(path, parentZone);
  }

  @override
  String toString() => 'IsolatedDirectory{path: $path}';

  @override
  Directory get absolute {
    final wd = Directory.current.path;
    return _parentZone.run(() => Directory(p.join(wd, path)));
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
  Future<Directory> createTemp([String? prefix]) {
    return absolute.createTemp(prefix);
  }

  @override
  Directory createTempSync([String? prefix]) {
    return absolute.createTempSync(prefix);
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    absolute.delete(recursive: recursive);
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
      {bool recursive = false, bool followLinks = true}) {
    return absolute.list(recursive: recursive, followLinks: followLinks);
  }

  @override
  List<FileSystemEntity> listSync(
      {bool recursive = false, bool followLinks = true}) {
    return absolute.listSync(recursive: recursive, followLinks: followLinks);
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
