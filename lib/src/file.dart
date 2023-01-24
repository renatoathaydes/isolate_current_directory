import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:isolate_current_directory/src/directory.dart';
import 'package:path/path.dart' as p;

import 'utils.dart';

class IsolatedFile implements File {
  @override
  final String path;

  final Zone _parentZone;

  IsolatedFile._(this.path, this._parentZone);

  static File of(String path, Zone parentZone) {
    return IsolatedFile._(path, parentZone);
  }

  @override
  String toString() => 'IsolatedFile{path: $path}';

  @override
  File get absolute {
    final wd = Directory.current.path;
    return _parentZone.run(() => File(p.join(wd, path)));
  }

  @override
  Future<File> copy(String newPath) async {
    await absolute.copy(absPath(newPath));
    return IsolatedFile.of(newPath, _parentZone);
  }

  @override
  File copySync(String newPath) {
    absolute.copySync(absPath(newPath));
    return IsolatedFile.of(newPath, _parentZone);
  }

  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) async {
    await absolute.create(recursive: recursive, exclusive: false);
    return this;
  }

  @override
  void createSync({bool recursive = false, bool exclusive = false}) {
    absolute.createSync(recursive: recursive, exclusive: false);
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
  Future<DateTime> lastAccessed() {
    return absolute.lastAccessed();
  }

  @override
  DateTime lastAccessedSync() {
    return absolute.lastAccessedSync();
  }

  @override
  Future<DateTime> lastModified() {
    return absolute.lastModified();
  }

  @override
  DateTime lastModifiedSync() {
    return absolute.lastModifiedSync();
  }

  @override
  Future<int> length() {
    return absolute.length();
  }

  @override
  int lengthSync() {
    return absolute.lengthSync();
  }

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) {
    return absolute.open(mode: mode);
  }

  @override
  Stream<List<int>> openRead([int? start, int? end]) {
    return absolute.openRead(start, end);
  }

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) {
    return absolute.openSync(mode: mode);
  }

  @override
  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8}) {
    return absolute.openWrite(mode: mode, encoding: encoding);
  }

  @override
  Directory get parent => IsolatedDirectory.of(p.dirname(path), _parentZone);

  @override
  Future<Uint8List> readAsBytes() {
    return absolute.readAsBytes();
  }

  @override
  Uint8List readAsBytesSync() {
    return absolute.readAsBytesSync();
  }

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) {
    return absolute.readAsLines(encoding: encoding);
  }

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) {
    return absolute.readAsLinesSync(encoding: encoding);
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) {
    return absolute.readAsString(encoding: encoding);
  }

  @override
  String readAsStringSync({Encoding encoding = utf8}) {
    return absolute.readAsStringSync(encoding: encoding);
  }

  @override
  Future<File> rename(String newPath) async {
    await absolute.rename(absPath(newPath));
    return IsolatedFile.of(newPath, _parentZone);
  }

  @override
  File renameSync(String newPath) {
    absolute.renameSync(absPath(newPath));
    return IsolatedFile.of(newPath, _parentZone);
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
  Future setLastAccessed(DateTime time) {
    return absolute.setLastAccessed(time);
  }

  @override
  void setLastAccessedSync(DateTime time) {
    absolute.setLastAccessedSync(time);
  }

  @override
  Future setLastModified(DateTime time) {
    return absolute.setLastModified(time);
  }

  @override
  void setLastModifiedSync(DateTime time) {
    return absolute.setLastModifiedSync(time);
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

  @override
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) async {
    await absolute.writeAsBytes(bytes, mode: mode, flush: flush);
    return this;
  }

  @override
  void writeAsBytesSync(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) {
    absolute.writeAsBytesSync(bytes, mode: mode, flush: flush);
  }

  @override
  Future<File> writeAsString(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false}) async {
    await absolute.writeAsString(contents,
        mode: mode, encoding: encoding, flush: flush);
    return this;
  }

  @override
  void writeAsStringSync(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false}) {
    absolute.writeAsStringSync(contents,
        mode: mode, encoding: encoding, flush: flush);
  }
}
