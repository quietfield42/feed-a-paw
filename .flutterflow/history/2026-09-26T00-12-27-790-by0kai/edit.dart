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
  // A stop and a pickup belong to the round the driver is actually on, which
  // the phone remembers. Before this they were saved against nothing.
  app.editPage(ff.Pages.stopPage, (page) {
    page.ensureActions(
      ff.Pages.stopPage.widgets.byKey('Button_6xdknv8c').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        PostgresCreate(
          ff.Tables.feedRunStops,
          fields: {
            'run_id': AppState('currentRunId'),
            'spot_id': State('spotId'),
            'meals_served': State('meals'),
            'animals_seen': State('seen'),
            'note': State('note'),
            'arrived_at': const Global(GlobalProperty.currentTimestamp),
          },
        ),
        Snackbar('Stop saved.'),
        const NavigateBack(),
      ],
    );
  });

  app.editPage(ff.Pages.pickupPage, (page) {
    page.ensureActions(
      ff.Pages.pickupPage.widgets.byKey('Button_h50rc8xs').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        PostgresCreate(
          ff.Tables.feedCollections,
          fields: {
            'run_id': AppState('currentRunId'),
            'butcher_name': State('butcher'),
            'kilos': State('kilos'),
            'collected_by': const AuthUser(AuthUserField.userId),
            'note': State('note'),
          },
        ),
        Snackbar('Pickup saved.'),
        const NavigateBack(),
      ],
    );
  });

  // Starting a round now also remembers it on the phone.
  app.editPage(ff.Pages.driverPage, (page) {
    page.ensureActions(
      ff.Pages.driverPage.widgets.byKey('Button_ox047bt4').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        PostgresCreate(
          ff.Tables.feedRuns,
          fields: {
            'driver_id': const AuthUser(AuthUserField.userId),
            'status': 'running',
            'started_at': const Global(GlobalProperty.currentTimestamp),
          },
        ),
        PostgresRead(
          ff.Tables.feedRuns,
          outputAs: 'startedRun',
          query: PostgresQuerySpec(
            filters: [
              PostgresFilter(
                'driver_id',
                relation: PostgresFilterRelation.equalTo,
                value: const AuthUser(AuthUserField.userId),
              ),
              PostgresFilter(
                'status',
                relation: PostgresFilterRelation.equalTo,
                value: 'running',
              ),
            ],
            isSingleRow: true,
          ),
        ),
        UpdateAppState.set('currentRunId', ActionOutput('startedRun')['id']),
        SetState('runId', ActionOutput('startedRun')['id']),
        SetState('onTheRoad', true),
        Snackbar('The round has started.'),
      ],
    );

    page.ensureActions(
      ff.Pages.driverPage.widgets.byKey('Button_zfzjqb0v').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        PostgresUpdate(
          ff.Tables.feedRuns,
          fields: {
            'status': 'done',
            'ended_at': const Global(GlobalProperty.currentTimestamp),
          },
          query: PostgresQuerySpec(
            filters: [
              PostgresFilter(
                'id',
                relation: PostgresFilterRelation.equalTo,
                value: AppState('currentRunId'),
              ),
            ],
            isSingleRow: true,
          ),
        ),
        UpdateAppState.set('currentRunId', ''),
        SetState('onTheRoad', false),
        Snackbar('Round finished. Thank you.'),
      ],
    );
  });
}
