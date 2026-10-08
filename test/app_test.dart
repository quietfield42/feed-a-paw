import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:test/test.dart';

import '../dsl/create.dart' as starter;

void main() {
  // Feed-a-Paw was created once and `buildStarterCreateFlow` was emptied
  // afterwards; every change since has gone through `dsl/edit.dart`. The test
  // that shipped with the workspace looked for a `StarterPage`, so it has been
  // failing since the day the app was built — asserting something that was
  // true of the template and never of this project.
  test('the create flow is spent, and still compiles', () {
    final project = compileApp(buildApp(starter.buildStarterCreateFlow)).project;
    expect(findPage(project, name: 'StarterPage'), isNull,
        reason: 'Feed-a-Paw is created; re-running create would duplicate it');
  });

  // The edit script reads its custom-widget sources off disk, so a kit file
  // that is renamed or moved fails at push time with a file-not-found deep in
  // a run. This catches it here instead, which costs nothing.
  test('every kit file the edit script reads exists', () {
    final edit = File('dsl/edit.dart').readAsStringSync();
    final wanted = RegExp(r"_kit\('([^']+)'\)")
        .allMatches(edit)
        .map((m) => 'kit/${m.group(1)!}')
        .toSet();

    expect(wanted, isNotEmpty,
        reason: 'the edit script should read its widgets through _kit()');
    for (final path in wanted) {
      expect(File(path).existsSync(), isTrue, reason: '$path is missing');
    }
  });
}
