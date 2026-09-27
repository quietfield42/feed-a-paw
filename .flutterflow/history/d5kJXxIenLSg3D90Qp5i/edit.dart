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
  // Tonight's route (28 Sep 2026).
  //
  // A round is no longer a loose list of stops: the driver picks a route, the
  // places appear in the order they are driven, and the round remembers which
  // route it followed. The idea is Spot-a-Paw's; this is it made for a truck.

  app.supabase(
    url: 'https://bxoboypzumjdfkpszbkt.supabase.co',
    anonKey: 'sb_publishable_g3AquYaNa0cwXs8jxqidqg_p1FwQCWJ',
  );

  final routes = app.table(
    'feed_routes',
    fields: {
      'id': const PostgresTableField(string,
          postgresType: 'uuid', isPrimaryKey: true, hasDefault: true),
      'name': const PostgresTableField(string,
          postgresType: 'text', isRequired: true),
      'area': const PostgresTableField(string, postgresType: 'text'),
      'note': const PostgresTableField(string, postgresType: 'text'),
      'active': const PostgresTableField(bool_,
          postgresType: 'bool', hasDefault: true),
    },
    description: 'The runs the truck drives, each an ordered set of places.',
  );

  final routePlan = app.table(
    'feed_route_plan',
    fields: {
      'route_id': const PostgresTableField(string,
          postgresType: 'uuid', isPrimaryKey: true),
      'route_name': const PostgresTableField(string, postgresType: 'text'),
      'route_area': const PostgresTableField(string, postgresType: 'text'),
      'position': const PostgresTableField(int_, postgresType: 'int4'),
      'spot_id': const PostgresTableField(string, postgresType: 'uuid'),
      'spot_name': const PostgresTableField(string, postgresType: 'text'),
      'spot_area': const PostgresTableField(string, postgresType: 'text'),
      'spot_note': const PostgresTableField(string, postgresType: 'text'),
    },
    description: 'A route\'s places, in the order they are driven.',
  );

  app.state('currentRouteId', string, persisted: true);
  app.state('currentRouteName', string, persisted: true);

  app.editPageState(ff.Pages.driverPage, (state) {
    state.ensureField('routes', listOf(routes));
    state.ensureField('plan', listOf(routePlan));
  });
}
