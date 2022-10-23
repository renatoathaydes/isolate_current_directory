import 'package:dartle/dartle_dart.dart';

import 'dartle-src/sequential_test_task.dart';

final dartleDart = DartleDart();

void main(List<String> args) {
  dartleDart.build.dependsOn(const {'sequentialTest'});
  run(args, tasks: {
    ...dartleDart.tasks,
    sequentialTestTask(),
  }, defaultTasks: {
    dartleDart.build
  });
}
