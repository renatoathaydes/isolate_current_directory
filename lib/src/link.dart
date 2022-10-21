import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'directory.dart';
import 'utils.dart';

class IsolatedLink implements Link {
  @override
  final String path;

  final Zone _parentZone;

  IsolatedLink._(this.path, this._parentZone);

  static Link of(String path, Zone parentZone) {
    return IsolatedLink._(path, parentZone);
  }

  @override
  String toString() => 'IsolatedLink{path: $path}';

  @override
  Link get absolute {
    final wd = Directory.current.path;
    return _parentZone.run(() => Link(p.join(wd, path)));
  }

  @override
  Future<Link> create(String target, {bool recursive = false}) async {
    await absolute.create(target, recursive: recursive);
    return this;
  }

  @override
  void createSync(String target, {bool recursive = false}) {
    absolute.createSync(target, recursive: recursive);
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
  Directory get parent => IsolatedDirectory.of(p.dirname(path), _parentZone);

  @override
  Future<Link> rename(String newPath) async {
    await absolute.rename(absPath(newPath));
    return IsolatedLink.of(newPath, _parentZone);
  }

  @override
  Link renameSync(String newPath) {
    absolute.renameSync(absPath(newPath));
    return IsolatedLink.of(newPath, _parentZone);
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
  Future<String> target() async {
    final target = await absolute.target();
    return absPath(target);
  }

  @override
  String targetSync() {
    final target = absolute.targetSync();
    return absPath(target);
  }

  @override
  Future<Link> update(String target) async {
    await absolute.update(target);
    return this;
  }

  @override
  void updateSync(String target) {
    absolute.updateSync(target);
  }

  @override
  Stream<FileSystemEvent> watch(
      {int events = FileSystemEvent.all, bool recursive = false}) {
    return absolute.watch(events: events, recursive: recursive);
  }
}
