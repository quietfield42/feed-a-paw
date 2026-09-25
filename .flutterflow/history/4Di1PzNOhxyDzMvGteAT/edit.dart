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
  app.supabase(
    url: 'https://bxoboypzumjdfkpszbkt.supabase.co',
    anonKey: 'sb_publishable_g3AquYaNa0cwXs8jxqidqg_p1FwQCWJ',
  );
  // ---- the family backend and the tables this edit touches ---------------
  final runs = app.table(
    'feed_runs',
    fields: {
      'id': const PostgresTableField(string,
          postgresType: 'uuid', isPrimaryKey: true, hasDefault: true),
      'truck_id': const PostgresTableField(string, postgresType: 'uuid'),
      'route_id': const PostgresTableField(string, postgresType: 'uuid'),
      'driver_id': const PostgresTableField(string,
          postgresType: 'uuid', isRequired: true),
      'day': const PostgresTableField(dateTime, postgresType: 'date', hasDefault: true),
      'status': const PostgresTableField(string, postgresType: 'text', hasDefault: true),
      'started_at': const PostgresTableField(dateTime, postgresType: 'timestamptz'),
      'ended_at': const PostgresTableField(dateTime, postgresType: 'timestamptz'),
      'note': const PostgresTableField(string, postgresType: 'text'),
    },
    description: 'One truck, one driver, one day.',
  );

  final stops = app.table(
    'feed_run_stops',
    fields: {
      'id': const PostgresTableField(string,
          postgresType: 'uuid', isPrimaryKey: true, hasDefault: true),
      'run_id': const PostgresTableField(string,
          postgresType: 'uuid', isRequired: true),
      'spot_id': const PostgresTableField(string, postgresType: 'uuid'),
      'position': const PostgresTableField(int_, postgresType: 'int4', hasDefault: true),
      'arrived_at': const PostgresTableField(dateTime, postgresType: 'timestamptz'),
      'meals_served': const PostgresTableField(int_, postgresType: 'int4', hasDefault: true),
      'animals_seen': const PostgresTableField(int_, postgresType: 'int4'),
      'note': const PostgresTableField(string, postgresType: 'text'),
      'skipped_reason': const PostgresTableField(string, postgresType: 'text'),
    },
    description: 'Each stop on a round: what was served, and what was seen.',
  );

  final spots = app.table(
    'feed_spots',
    fields: {
      'id': const PostgresTableField(string,
          postgresType: 'uuid', isPrimaryKey: true, hasDefault: true),
      'name': const PostgresTableField(string, postgresType: 'text', isRequired: true),
      'area': const PostgresTableField(string, postgresType: 'text'),
      'typical_count': const PostgresTableField(int_, postgresType: 'int4'),
      'active': const PostgresTableField(bool_, postgresType: 'bool', hasDefault: true),
    },
    description: 'The places that get fed.',
  );

  final collections = app.table(
    'feed_collections',
    fields: {
      'id': const PostgresTableField(string,
          postgresType: 'uuid', isPrimaryKey: true, hasDefault: true),
      'run_id': const PostgresTableField(string, postgresType: 'uuid'),
      'butcher_name': const PostgresTableField(string, postgresType: 'text'),
      'kilos': const PostgresTableField(double_, postgresType: 'numeric'),
      'collected_at': const PostgresTableField(dateTime,
          postgresType: 'timestamptz', hasDefault: true),
      'collected_by': const PostgresTableField(string, postgresType: 'uuid'),
      'note': const PostgresTableField(string, postgresType: 'text'),
    },
    description: 'Meat picked up from a butcher.',
  );

}
