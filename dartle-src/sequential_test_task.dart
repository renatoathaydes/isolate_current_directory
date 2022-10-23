import 'dart:io';

import 'package:dartle/dartle.dart';

Task sequentialTestTask() => Task(sequentialTest,
    description:
        'Run the sequential tests (tests that cannot run in parallel).',
    dependsOn: const {'test'});

Future<void> sequentialTest(_) async {
  await exec(Process.start(
      'dart', const ['test', 'test-sequential', '--concurrency=1']));
}
