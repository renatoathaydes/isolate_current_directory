## 2.1.0

- Support using `#workingDir` Zone variable to compute working directory.
- Don't wrap result in `Future` if action given to `withCurrentDirectory` is not async.

## 2.0.0

- Dart 3.0 requirement.

## 1.2.0

- Upgraded Dart to 2.19.0 (contains breaking changes).
- Libraries updates.

## 1.1.0

- Change Directory listing to list relative paths instead of absolute paths.

## 1.0.2

- Propagate errors on `Directory.delete` method (it was not awaiting, causing an unhandled exception). 

## 1.0.1

- Fixed `stat` and `statSync` to use updated Zone's `Directory.current`.

## 1.0.0

- Initial version.
