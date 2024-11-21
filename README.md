# isolate_current_directory

![GitHub Actions](https://github.com/renatoathaydes/isolate_current_directory/workflows/CI/badge.svg)
[![pub package](https://img.shields.io/pub/v/isolate_current_directory.svg)](https://pub.dev/packages/isolate_current_directory)

This library exports the `withCurrentDirectory` function, which can
change [`Directory.current`](https://api.dart.dev/stable/2.18.3/dart-io/Directory/current.html)
(the working directory) within the scope of a lambda, but not the global value.

That means that using this function, it's possible to write concurrent Dart code that executes in different
working directories without different scopes affecting each other.

## Using this library

To add a dependency on your pubspec:

```shell
dart pub add isolate_current_directory
```

Now, you can use `withCurrentDirectory`:

```dart
withCurrentDirectory('my-dir', () async {
  // this file resolves to my-dir/example.txt
  final file = File('example.txt');
  // use the file!
});
```

See [isolate_current_directory_example.dart](example/isolate_current_directory_example.dart) for a complete example.

## Motivation

Dart's [`Directory.current`](https://api.dart.dev/stable/2.18.3/dart-io/Directory/current.html)
is a global variable that can be changed at any time by any Dart code.

In asynchronous code, you could use a lock (see the [synchronized](https://pub.dev/packages/synchronized) package)
to try to avoid modifying the working directory while other async code is running, but that is impossible to
guarantee as any code that ignores the lock could still concurrently modify the working directory.

This problem is even more vexing in the presence of [`Isolate`](https://api.dart.dev/stable/2.18.3/dart-isolate/Isolate-class.html)s
because if any code in any `Isolate` changes the working directory, then all other `Isolate`s will see that but have
no way that I know of to synchronize access to `Directory.current`, because `Isolate`s are supposed to be, well,
isolated from each other so they cannot share the same lock!

By using [`IOOverrides`](https://api.dart.dev/stable/2.18.3/dart-io/IOOverrides-class.html),
this library leverages Dart [`Zone`](https://api.dart.dev/stable/2.18.3/dart-async/Zone-class.html)s to isolate
`Directory.current` to the scope of a function.
No matter how many functions are running concurrently, even across many `Isolate`s, each function has its own
working directory. It can change its own working directory without affecting any other code running in a different
scope.

## Caveats

### Process

Unfortunately, methods from `Process` do not honour the scoped `Directory.current` value by default.

For this reason, when using `Process`, you must pass in the `workingDirectory` argument explicitly:

```dart
Process.start('cmd', const ['args'], workingDirectory: Directory.current.path);
```

### Isolates

When starting a new Isolate, unfortunately, the new Isolate will not inherit the scoped current directory of the
calling code.

To work around that, wrap Isolate functions using `wrapWithCurrentDirectory` as follows:

```dart
// BEFORE
Isolate.run(myIsolateFunction);

// AFTER
Isolate.run(wrapWithCurrentDirectory(myIsolateFunction));  
```

### Performance

Another possible issue is performance. When a `FileSystemEntity` is created within the scope of `withCurrentDirectory`,
a custom implementation of the `dart:io` type (`File`, `Directory`, `Link`) is created which will check at each
operation what's the scoped value of `Directory.current`, which may have a non-negligible cost if this happens in
the hot path of an application.

### Link bugs

Links mostly work, but mysteriously, `exists()` doesn't seem to.

See [link_test.dart](test/link_test.dart).
