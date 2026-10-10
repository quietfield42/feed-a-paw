library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:flutterflow_ai/src/helpers/ensure_helpers.dart'
    show ensurePubDependency;
import 'package:flutterflow_ai/src/helpers/project_helpers.dart'
    show updateStateField;
import 'package:flutterflow_ai/src/helpers/nav_bar_helpers.dart'
    show setNavBarEnabled;
import 'package:flutterflow_ai/src/helpers/postgres_helpers.dart'
    show addTableField, findTableField;
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

String _kit(String name) {
  final text = File('kit/$name').readAsStringSync();
  const marker = '// DO NOT REMOVE OR MODIFY THE CODE ABOVE!';
  final at = text.indexOf(marker);
  return at < 0 ? text.trim() : text.substring(at + marker.length).trim();
}

/// Points an Upload action at a bucket by name.
///
/// The DSL's UploadData has no bucket of its own, so FlutterFlow generated
/// `bucketName: ''` and the photograph had nowhere to land. This reaches into
/// the action and names the bucket.
void _uploadToBucket(dynamic page, String nodeKey, String bucket) {
  page.mutateNode(page.findByKey(nodeKey), (node) {
    for (final trigger in node.triggerActions) {
      var step = trigger.rootAction;
      while (true) {
        if (step.action.hasUploadData()) {
          step.action.uploadData
              .ensureSupabase()
              .ensureStorageBucket()
              .ensureInputValue()
              .serializedValue = bucket;
        }
        if (!step.hasFollowUpAction()) break;
        step = step.followUpAction;
      }
    }
  });
}

void buildStarterEditFlow(App app) {
  // Nobody has ever been able to start a round (10 Oct 2026).
  //
  // Found by sweeping all three apps for local state that is read but never
  // assigned, after that fault turned out to be hiding the whole rescue half
  // of Adopt. On the Driver page it is worse than hiding a button: the list of
  // rounds, `routes`, was never loaded, and tapping a round in that list is
  // the **only** place in the entire app that sets `currentRunId`.
  //
  // So the page showed its "no rounds yet" state to everybody, forever, and
  // everything behind it — the places in order, logging a stop, the photos,
  // "Round finished. Thank you." — was unreachable. The feeding round is what
  // Feed-a-Paw is for.
  //
  // `feed_routes` has been sitting there with active, name and area, which is
  // exactly what the round card draws. Nothing ever read it.
  //
  // Two counters above the list, `stopsToday` and `mealsToday`, were in the
  // same state — read, never assigned, so permanently "0". `feed_run_totals`
  // already carries stops, meals and animals per run; the end-of-round
  // summary reads it correctly, which is how the live counters should have.

  app.editPage(ff.Pages.driverPage, (page) {
    page.removeTrigger(page.root, FFActionTriggerType.ON_INIT_STATE);
  });

  app.editPageOnLoad(ff.Pages.driverPage, [
    // The rounds somebody can drive tonight.
    PostgresQuery(
      ff.Tables.feedRoutes,
      key: 'read-routes',
      outputAs: 'allRoutes',
      query: PostgresQuerySpec(
        filters: [
          PostgresFilter('active',
              relation: PostgresFilterRelation.equalTo, value: true),
        ],
        orderBys: const [PostgresOrderBy('name')],
      ),
    ),
    SetState(ff.Pages.driverPage.state.routes, const ActionOutput('allRoutes'),
        key: 'keep-routes'),

    // Pick up a round already in progress rather than offering to start a
    // second one. `onTheRoad` is page state, so it resets to false every time
    // the page is opened — a driver whose phone locked mid-round came back to
    // the picker, and tapping a round there would have opened a *new* run and
    // orphaned the half-finished one.
    SetState(ff.Pages.driverPage.state.runId,
        AppState(ff.AppState.currentRunId),
        key: 'keep-run-id'),
    SetState(
      ff.Pages.driverPage.state.onTheRoad,
      CodeExpression(
        r'runId.isNotEmpty',
        args: {'runId': AppState(ff.AppState.currentRunId)},
        returns: bool_,
      ),
      key: 'keep-on-the-road',
    ),

    // Tonight so far, for the two counters at the top.
    PostgresRead(
      ff.Tables.feedRunTotals,
      key: 'read-live-totals',
      outputAs: 'liveTotals',
      query: PostgresQuerySpec(
        filters: [
          PostgresFilter('run_id',
              relation: PostgresFilterRelation.equalTo,
              value: AppState(ff.AppState.currentRunId)),
        ],
      ),
    ),
    SetState(ff.Pages.driverPage.state.stopsToday,
        const ActionOutput('liveTotals')['stops'],
        key: 'keep-stops-today'),
    SetState(ff.Pages.driverPage.state.mealsToday,
        const ActionOutput('liveTotals')['meals'],
        key: 'keep-meals-today'),

    // Unchanged: the places on tonight's round, in order.
    PostgresQuery(
      ff.Tables.feedTonight,
      key: 'read-tonight',
      outputAs: 'tonightsPlaces',
      query: PostgresQuerySpec(
        filters: [
          PostgresFilter('run_id',
              relation: PostgresFilterRelation.equalTo,
              value: AppState(ff.AppState.currentRunId)),
        ],
        orderBys: const [PostgresOrderBy('position')],
      ),
    ),
    SetState(ff.Pages.driverPage.state.tonight,
        const ActionOutput('tonightsPlaces'),
        key: 'keep-tonight'),
  ]);
}
