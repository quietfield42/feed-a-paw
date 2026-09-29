library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:feedapaw/flutterflow_project.dart' as ff;

Future<void> main(List<String> args) async {
  if (Platform.environment['_FF_AI_DSL_LAUNCHER'] != '1') {
    stdout.writeln(
      'Tip: run this through `flutterflow ai run` (validated, faster)',
    );
  }
  final options = _parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildStarterEditFlow,
      apiKey: options.apiKey,
      baseUrl: options.baseUrl,
      projectName: options.projectName,
      projectId: options.projectId,
      findOrCreate: options.findOrCreate,
      allowNewProject: options.allowNewProject,
      dryRun: options.dryRun,
      commitMessage: options.commitMessage,
    );
  } catch (error, stackTrace) {
    stderr.writeln('Error: ${formatFlutterFlowAIError(error, stackTrace: stackTrace)}');
    exit(1);
  }
}

final class _CliOptions {
  const _CliOptions({
    this.apiKey,
    this.baseUrl,
    this.projectName,
    this.projectId,
    this.findOrCreate = false,
    this.allowNewProject = false,
    this.dryRun = false,
    this.commitMessage,
  });

  final String? apiKey;
  final String? baseUrl;
  final String? projectName;
  final String? projectId;
  final bool findOrCreate;
  final bool allowNewProject;
  final bool dryRun;
  final String? commitMessage;
}

_CliOptions _parseCliOptions(List<String> args) {
  String? apiKey;
  String? baseUrl;
  String? projectName;
  String? projectId;
  String? commitMessage;
  var findOrCreate = false;
  var allowNewProject = false;
  var dryRun = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--help':
      case '-h':
        _printUsage();
        exit(0);
      case '--api-key':
        apiKey = _requireValue(args, ++i, '--api-key');
      case '--base-url':
        baseUrl = _requireValue(args, ++i, '--base-url');
      case '--project-name':
        projectName = _requireValue(args, ++i, '--project-name');
      case '--project-id':
        projectId = _requireValue(args, ++i, '--project-id');
      case '--commit-message':
        commitMessage = _requireValue(args, ++i, '--commit-message');
      case '--find-or-create':
        findOrCreate = true;
      case '--allow-new-project':
        allowNewProject = true;
      case '--dry-run':
        dryRun = true;
      default:
        stderr.writeln('Unknown option: $arg');
        _printUsage();
        exit(64);
    }
  }

  return _CliOptions(
    apiKey: apiKey,
    baseUrl: baseUrl,
    projectName: projectName,
    projectId: projectId,
    findOrCreate: findOrCreate,
    allowNewProject: allowNewProject,
    dryRun: dryRun,
    commitMessage: commitMessage,
  );
}

String _requireValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    stderr.writeln('Missing value for $flag.');
    _printUsage();
    exit(64);
  }
  return args[index];
}

void _printUsage() {
  stdout.writeln('''
Run the starter FlutterFlow AI edit flow.

Usage:
  flutterflow ai validate dsl/edit.dart [options]
  flutterflow ai run dsl/edit.dart [options]

Options:
  --api-key <key>           FlutterFlow API key. Defaults to FF_API_KEY.
  --base-url <url>          Override the FlutterFlow API base URL.
  --project-name <name>     Create a new project with this name.
  --project-id <id>         Push into an existing project by ID.
  --find-or-create          Retry by reusing a same-name project before creating.
  --allow-new-project       Bypass the workspace binding guard and create a different project.
  --commit-message <text>   Commit message for the push.
  --dry-run                 Compile and validate without pushing.
  --help, -h                Show this help.
''');
}

void buildStarterEditFlow(App app) {
  // The a-Paw house style, applied (29 Sep 2026).

  app.supabase(
    url: 'https://bxoboypzumjdfkpszbkt.supabase.co',
    anonKey: 'sb_publishable_g3AquYaNa0cwXs8jxqidqg_p1FwQCWJ',
  );

  // ---------------------------------------------------------------------
  // The a-Paw house style. Identical in every app in the family, taken from
  // Care-a-Paw so the seven look like one thing rather than seven.
  //
  // Forest carries the app, orange is the paw and the call to action, ivory
  // is the paper everything sits on. Fraunces for anything that is a heading,
  // Figtree for anything that is read.
  // ---------------------------------------------------------------------
  app.themeColor('primary', 0xFF1F5148);
  app.themeColor('secondary', 0xFFFF7900);
  app.themeColor('tertiary', 0xFFB08D57);
  app.themeColor('alternate', 0xFFE6DFD1);
  app.themeColor('primaryText', 0xFF1F5148);
  app.themeColor('secondaryText', 0xFF55625D);
  app.themeColor('primaryBackground', 0xFFF6F1E7);
  app.themeColor('secondaryBackground', 0xFFFFFFFF);
  app.themeColor('accent1', 0xFFDDEBE3);
  app.themeColor('accent2', 0xFFFFE7D1);
  app.themeColor('accent3', 0xFFF2EBDD);
  app.themeColor('accent4', 0xCCFFFFFF);
  app.themeColor('success', 0xFF2E7D32);
  app.themeColor('warning', 0xFFB85200);
  app.themeColor('error', 0xFFB3261E);
  app.themeColor('info', 0xFF1F5148);

  app.typography('displayLarge',
      fontFamily: 'Fraunces', fontSize: 64, fontWeight: 600);
  app.typography('displayMedium',
      fontFamily: 'Fraunces', fontSize: 44, fontWeight: 600);
  app.typography('displaySmall',
      fontFamily: 'Fraunces', fontSize: 36, fontWeight: 700);
  app.typography('headlineLarge',
      fontFamily: 'Fraunces', fontSize: 32, fontWeight: 600);
  app.typography('headlineMedium',
      fontFamily: 'Fraunces', fontSize: 32, fontWeight: 700);
  app.typography('headlineSmall',
      fontFamily: 'Fraunces', fontSize: 24, fontWeight: 700);
  app.typography('titleLarge',
      fontFamily: 'Fraunces', fontSize: 20, fontWeight: 700);
  app.typography('titleMedium',
      fontFamily: 'Fraunces', fontSize: 16, fontWeight: 600);
  app.typography('titleSmall',
      fontFamily: 'Fraunces', fontSize: 16, fontWeight: 600);
  app.typography('labelLarge',
      fontFamily: 'Figtree', fontSize: 16, fontWeight: 400);
  app.typography('labelMedium',
      fontFamily: 'Figtree', fontSize: 14, fontWeight: 400);
  app.typography('labelSmall',
      fontFamily: 'Figtree', fontSize: 12, fontWeight: 400);
  app.typography('bodyLarge',
      fontFamily: 'Figtree', fontSize: 17, fontWeight: 400);
  app.typography('bodyMedium',
      fontFamily: 'Figtree', fontSize: 15, fontWeight: 400);
  app.typography('bodySmall',
      fontFamily: 'Figtree', fontSize: 13, fontWeight: 400);
}
