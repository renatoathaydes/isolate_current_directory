# isolate_current_directory

This library exports a single function, `withCurrentDirectory`, which can change `Directory.current`
(the working directory) within the scope of a lambda, but not the global value.

That means that using this function, it's possible to write concurrent Dart code that executes in different
working directories without different computations affecting each other.

This works even when using different `Isolate`s.

## Using this library

To add a dependency on your pubspec:

```shell
dart pub add isolate_current_directory
```

Now, you can use `withCurrentDirectory`:

```dart
withCurrentDirectory('my-dir', () async {
  // this file resolves to my-dir/example.txt
  final file = File('my-dir/example.txt');
  // use the file!
});
```

See [isolate_current_directory_example.dart](example/isolate_current_directory_example.dart) for a complete example.

## Motivation

Dart's `Directory.current` is a global variable that can be changed at any time by any Dart code. Its value is even
shared between different `Isolate`s, so it's very hard to write concurrent code that runs on different working
directories.

By using `IOOverrides`, this library uses Dart `Zone`s to isolate `Directory.current` to the scope of a function.
No matter how many functions are running concurrently, even across many `Isolate`s, each function has its own
working directory.

## Caveats

Unfortunately, methods from `Process` do not honour the scoped `Directory.current` value by default.

For this reason, when using `Process` you must pass in the `workingDirectory` argument explicitly:

```dart
Process.start('cmd', const ['args'], workingDirectory: Directory.current.path);
```
