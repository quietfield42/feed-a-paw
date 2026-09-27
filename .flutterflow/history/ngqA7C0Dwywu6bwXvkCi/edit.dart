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
  // Tonight's route, on the driver's screen (28 Sep 2026).
  //
  // Pick the route, and the places appear in the order they are driven. The
  // round records which route it followed, so a week later it is clear what
  // was covered and what was not.

  app.supabase(
    url: 'https://bxoboypzumjdfkpszbkt.supabase.co',
    anonKey: 'sb_publishable_g3AquYaNa0cwXs8jxqidqg_p1FwQCWJ',
  );

  // The routes to choose from, and the places on the chosen one.
  app.editPageOnLoad(ff.Pages.driverPage, [
    PostgresQuery(
      ff.Tables.feedRoutes,
      outputAs: 'loadedRoutes',
      query: PostgresQuerySpec(
        filters: [
          PostgresFilter('active',
              relation: PostgresFilterRelation.equalTo, value: true),
        ],
        orderBys: const [PostgresOrderBy('name')],
      ),
    ),
    SetState(ff.Pages.driverPage.state.routes, ActionOutput('loadedRoutes')),
    PostgresQuery(
      ff.Tables.feedRoutePlan,
      outputAs: 'loadedPlan',
      query: PostgresQuerySpec(
        filters: [
          PostgresFilter('route_id',
              relation: PostgresFilterRelation.equalTo,
              value: AppState('currentRouteId')),
        ],
        orderBys: const [PostgresOrderBy('position')],
      ),
    ),
    SetState(ff.Pages.driverPage.state.plan, ActionOutput('loadedPlan')),
  ]);

  app.editPage(ff.Pages.driverPage, (page) {
    page.ensureInsertedBefore(
      ff.Pages.driverPage.widgets.byKey('Button_ox047bt4').single,
      Column(
        name: 'TonightsRoute',
        crossAxis: CrossAxis.start,
        spacing: 8,
        children: [
          Text(
            'Tonight you are driving',
            name: 'RouteLabel',
            style: Styles.labelMedium,
            color: Colors.secondaryText,
          ),
          Text(
            AppState('currentRouteName'),
            name: 'ChosenRouteText',
            style: Styles.titleMedium,
            color: Colors.primary,
          ),
          Container(
            height: 150,
            child: ListView(
              name: 'RoutesList',
              source: State(ff.Pages.driverPage.state.routes),
              spacing: 6,
              itemBuilder: (item) => Card(
                onTap: [
                  UpdateAppState.set('currentRouteId', item['id']),
                  UpdateAppState.set('currentRouteName', item['name']),
                  PostgresQuery(
                    ff.Tables.feedRoutePlan,
                    outputAs: 'pickedPlan',
                    query: PostgresQuerySpec(
                      filters: [
                        PostgresFilter('route_id',
                            relation: PostgresFilterRelation.equalTo,
                            value: item['id']),
                      ],
                      orderBys: const [PostgresOrderBy('position')],
                    ),
                  ),
                  SetState(ff.Pages.driverPage.state.plan,
                      ActionOutput('pickedPlan')),
                ],
                child: Container(
                  padding: 12,
                  child: Column(
                    crossAxis: CrossAxis.start,
                    spacing: 2,
                    children: [
                      Text(item['name'], style: Styles.bodyLarge),
                      Text(item['area'],
                          style: Styles.labelSmall,
                          color: Colors.secondaryText),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Text(
            'The places, in order',
            name: 'PlanLabel',
            style: Styles.labelMedium,
            color: Colors.secondaryText,
          ),
          ListView(
            name: 'RoutePlanList',
            source: State(ff.Pages.driverPage.state.plan),
            spacing: 6,
            shrinkWrap: true,
            itemBuilder: (item) => Card(
              child: Container(
                padding: 12,
                child: Row(
                  spacing: 10,
                  children: [
                    Text(item['position'],
                        style: Styles.titleMedium, color: Colors.secondary),
                    Column(
                      crossAxis: CrossAxis.start,
                      spacing: 2,
                      children: [
                        Text(item['spot_name'], style: Styles.bodyLarge),
                        Text(item['spot_area'],
                            style: Styles.labelSmall,
                            color: Colors.secondaryText),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
