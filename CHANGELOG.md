## 1.1.0

- Change Directory listing to list relative paths instead of absolute paths.

## 1.0.2

- Propagate errors on `Directory.delete` method (it was not awaiting, causing an unhandled exception). 

## 1.0.1

- Fixed `stat` and `statSync` to use updated Zone's `Directory.current`.

## 1.0.0

- Initial version.
