library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

Future<void> main(List<String> args) async {
  if (Platform.environment['_FF_AI_DSL_LAUNCHER'] != '1') {
    stdout.writeln(
      'Tip: run this through `flutterflow ai run` (validated, faster)',
    );
  }
  final options = _parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildStarterCreateFlow,
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
Run the starter FlutterFlow AI create flow.

Usage:
  flutterflow ai validate dsl/create.dart [options]
  flutterflow ai run dsl/create.dart [options]

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

void buildStarterCreateFlow(App app) {
  // ---- the family look: forest, orange, ivory ----------------------------
  app.themeColor('primary', 0xFF1F5148);
  app.themeColor('secondary', 0xFFFF7900);
  app.themeColor('tertiary', 0xFF2E7D5B);
  app.themeColor('alternate', 0xFFE4DFD0);
  app.themeColor('primaryBackground', 0xFFF2EBDD);
  app.themeColor('secondaryBackground', 0xFFFFFDF7);
  app.themeColor('primaryText', 0xFF1B2420);
  app.themeColor('secondaryText', 0xFF5A6560);

  // ---- the family backend ------------------------------------------------
  app.supabase(
    url: 'https://bxoboypzumjdfkpszbkt.supabase.co',
    anonKey: 'sb_publishable_g3AquYaNa0cwXs8jxqidqg_p1FwQCWJ',
  );

  // The counter a supporter reads: one row of numbers.
  final totals = app.table(
    'feed_totals',
    fields: {
      'meals_all_time': const PostgresTableField(int_, postgresType: 'int8'),
      'meals_today': const PostgresTableField(int_, postgresType: 'int8'),
      'meals_week': const PostgresTableField(int_, postgresType: 'int8'),
      'kilos_collected':
          const PostgresTableField(double_, postgresType: 'numeric'),
      'runs_done': const PostgresTableField(int_, postgresType: 'int8'),
      'spots_active': const PostgresTableField(int_, postgresType: 'int8'),
    },
    description: 'Meals served, kilos collected, rounds done.',
  );

  final stories = app.table(
    'feed_stories',
    fields: {
      'id': const PostgresTableField(string,
          postgresType: 'uuid', isPrimaryKey: true, hasDefault: true),
      'title': const PostgresTableField(string, postgresType: 'text'),
      'words':
          const PostgresTableField(string, postgresType: 'text', isRequired: true),
      'photo_path': const PostgresTableField(string, postgresType: 'text'),
      'area': const PostgresTableField(string, postgresType: 'text'),
      'published_at':
          const PostgresTableField(dateTime, postgresType: 'timestamptz'),
    },
    description: 'Photographs and words from the street; published ones only.',
  );

  final fund = app.table(
    'feed_fund',
    fields: {
      'id': const PostgresTableField(string,
          postgresType: 'uuid', isPrimaryKey: true, hasDefault: true),
      'name':
          const PostgresTableField(string, postgresType: 'text', isRequired: true),
      'target': const PostgresTableField(double_,
          postgresType: 'numeric', isRequired: true),
      'raised': const PostgresTableField(double_, postgresType: 'numeric'),
      'currency': const PostgresTableField(string, postgresType: 'text'),
      'open': const PostgresTableField(bool_, postgresType: 'bool'),
    },
    description: 'The truck fund: what it needs and what it has.',
  );

  // ---- what a supporter lands on -----------------------------------------
  app.page(
    'HomePage',
    route: '/',
    isInitial: true,
    description: 'The feeding, as it stands today.',
    state: {
      'mealsToday': int_.withDefault(0),
      'mealsAllTime': int_.withDefault(0),
      'stories': listOf(stories),
    },
    onLoad: [
      PostgresQuery(totals, outputAs: 'loadedTotals'),
      PostgresQuery(
        stories,
        outputAs: 'loadedStories',
        query: PostgresQuerySpec(
          orderBys: const [PostgresOrderBy('published_at', ascending: false)],
        ),
      ),
      SetState('stories', ActionOutput('loadedStories')),
    ],
    body: Scaffold(
      body: Container(
        padding: 20,
        child: Column(
          crossAxis: CrossAxis.start,
          spacing: 18,
          children: [
            Text(
              'One tail. One meal. Every day.',
              name: 'PromiseText',
              style: Styles.headlineMedium,
              color: Colors.primary,
            ),
            Text(
              'Meals served today',
              name: 'TodayLabel',
              style: Styles.labelMedium,
              color: Colors.secondaryText,
            ),
            Text(
              State('mealsToday'),
              name: 'MealsTodayText',
              style: Styles.headlineMedium,
              color: Colors.secondary,
            ),
            Text(
              'Since the first round',
              name: 'AllTimeLabel',
              style: Styles.labelMedium,
              color: Colors.secondaryText,
            ),
            Text(
              State('mealsAllTime'),
              name: 'MealsAllTimeText',
              style: Styles.headlineSmall,
            ),
            Button(
              'Support the truck',
              name: 'SupportButton',
              onTap: LaunchUrl('https://onetailonemeal.com'),
            ),
            Text('From the street', name: 'StoriesHeading', style: Styles.titleMedium),
            ListView(
              source: State('stories'),
              spacing: 12,
              itemBuilder: (_) => Card(
                child: Column(
                  crossAxis: CrossAxis.start,
                  spacing: 6,
                  children: [
                    Text(ItemRef()['title'], style: Styles.titleSmall),
                    Text(ItemRef()['words'], maxLines: 4),
                    Text(
                      ItemRef()['area'],
                      style: Styles.labelSmall,
                      color: Colors.secondaryText,
                    ),
                  ],
                ),
              ),
            ),
            Button(
              'Where the money goes',
              name: 'AboutButton',
              onTap: Navigate('AboutPage'),
            ),
          ],
        ),
      ),
    ),
  );

  // ---- what this is, said plainly ----------------------------------------
  app.page(
    'AboutPage',
    route: '/about',
    description: 'What this is, and where the money goes.',
    state: {'fund': listOf(fund)},
    onLoad: [
      PostgresQuery(fund, outputAs: 'loadedFund'),
      SetState('fund', ActionOutput('loadedFund')),
    ],
    body: Scaffold(
      appBar: AppBar(title: 'About'),
      body: Container(
        padding: 20,
        child: Column(
          crossAxis: CrossAxis.start,
          spacing: 14,
          children: [
            Text(
              'No stray should go hungry.',
              name: 'AboutHeading',
              style: Styles.headlineSmall,
              color: Colors.primary,
            ),
            Text(
              'A truck collects meat trimmings from partner butchers each '
              'morning, cooks them on board, and follows the same round through '
              'the streets where the colonies live. This app shows that work as '
              'it happens.',
              name: 'AboutWords',
            ),
            Text(
              'Giving happens on onetailonemeal.com, never inside the app. What '
              'is given there funds meals for street animals. One Tail One Meal '
              'is not a registered charity, so gifts are not tax deductible.',
              name: 'AboutMoney',
              style: Styles.bodySmall,
              color: Colors.secondaryText,
            ),
            Button(
              'Give on the website',
              name: 'GiveButton',
              onTap: LaunchUrl('https://onetailonemeal.com'),
            ),
          ],
        ),
      ),
    ),
  );
}
