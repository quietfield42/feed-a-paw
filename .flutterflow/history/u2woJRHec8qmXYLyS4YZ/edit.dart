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

  // Made before the driver's page links to them: pages are created in reverse
  // navigation order.
  final stopPage = app.page(
    'StopPage',
    route: '/stop',
    description: 'What was served at one place.',
    state: {
      'runId': string.withDefault(''),
      'spotId': string.withDefault(''),
      'meals': int_.withDefault(0),
      'seen': int_.withDefault(0),
      'note': string.withDefault(''),
    },
    body: Scaffold(
      appBar: AppBar(title: 'A stop'),
      body: Container(
        padding: 20,
        child: Column(
          crossAxis: CrossAxis.start,
          spacing: 14,
          children: [
            Text(
              'Log it as you leave, while it is fresh.',
              name: 'StopWords',
              color: Colors.secondaryText,
            ),
            TextField(
              name: 'SpotField',
              label: 'Which place',
              onChanged: SetState('spotId', const TextValue()),
            ),
            TextField(
              name: 'MealsField',
              label: 'Meals served',
              keyboard: Keyboard.number,
              onChanged: SetState('meals', const TextValue()),
            ),
            TextField(
              name: 'SeenField',
              label: 'Animals seen',
              keyboard: Keyboard.number,
              onChanged: SetState('seen', const TextValue()),
            ),
            TextField(
              name: 'StopNoteField',
              label: 'Anything worth saying',
              onChanged: SetState('note', const TextValue()),
            ),
            Button(
              'Save this stop',
              name: 'SaveStopButton',
              onTap: [
                PostgresCreate(
                  ff.Tables.feedRunStops,
                  fields: {
                    'run_id': State('runId'),
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
            ),
          ],
        ),
      ),
    ),
  );

  final pickupPage = app.page(
    'PickupPage',
    route: '/pickup',
    description: 'Meat collected on the way.',
    state: {
      'runId': string.withDefault(''),
      'butcher': string.withDefault(''),
      'kilos': double_.withDefault(0),
      'note': string.withDefault(''),
    },
    body: Scaffold(
      appBar: AppBar(title: 'A pickup'),
      body: Container(
        padding: 20,
        child: Column(
          crossAxis: CrossAxis.start,
          spacing: 14,
          children: [
            Text(
              'What the butcher put aside this morning.',
              name: 'PickupWords',
              color: Colors.secondaryText,
            ),
            TextField(
              name: 'ButcherField',
              label: 'Which butcher',
              onChanged: SetState('butcher', const TextValue()),
            ),
            TextField(
              name: 'KilosField',
              label: 'Kilos',
              keyboard: Keyboard.number,
              onChanged: SetState('kilos', const TextValue()),
            ),
            TextField(
              name: 'PickupNoteField',
              label: 'Note',
              onChanged: SetState('note', const TextValue()),
            ),
            Button(
              'Save the pickup',
              name: 'SavePickupButton',
              onTap: [
                PostgresCreate(
                  ff.Tables.feedCollections,
                  fields: {
                    'run_id': State('runId'),
                    'butcher_name': State('butcher'),
                    'kilos': State('kilos'),
                    'collected_by': const AuthUser(AuthUserField.userId),
                    'note': State('note'),
                  },
                ),
                Snackbar('Pickup saved.'),
                const NavigateBack(),
              ],
            ),
          ],
        ),
      ),
    ),
  );


  // Signing in is for the team only: drivers, feeders, whoever writes the
  // stories. A supporter never needs an account.
  final signIn = app.page(
    'SignInPage',
    route: '/sign-in',
    description: 'For the team. Supporters never need an account.',
    state: {'email': string, 'password': string},
    body: Scaffold(
      appBar: AppBar(title: 'Sign in'),
      body: Container(
        padding: 24,
        child: Column(
          crossAxis: CrossAxis.start,
          spacing: 16,
          children: [
            Text(
              'Only the team signs in: drivers, feeders, and whoever writes '
              'the stories. Everyone else can just watch the work.',
              name: 'SignInWords',
              color: Colors.secondaryText,
            ),
            TextField(
              name: 'EmailField',
              label: 'Email',
              keyboard: Keyboard.email,
              onChanged: SetState('email', const TextValue()),
            ),
            TextField(
              name: 'PasswordField',
              label: 'Password',
              obscureText: true,
              onChanged: SetState('password', const TextValue()),
            ),
            Button(
              'Sign in',
              name: 'SignInButton',
              onTap: [LoginEmailPassword(State('email'), State('password'))],
            ),
            Button(
              'Back to the feeding',
              name: 'BackToTodayButton',
              onTap: Navigate(ff.Pages.todayPage),
            ),
          ],
        ),
      ),
    ),
  );

  final driver = app.page(
    'DriverPage',
    route: '/driver',
    description: 'The round, as the driver works it.',
    state: {
      'runId': string.withDefault(''),
      'onTheRoad': bool_.withDefault(false),
    },
    body: Scaffold(
      appBar: AppBar(title: 'Today'),
      body: Container(
        padding: 20,
        child: Column(
          crossAxis: CrossAxis.start,
          spacing: 16,
          children: [
            Text(
              'The round',
              name: 'RoundHeading',
              style: Styles.headlineSmall,
              color: Colors.primary,
            ),
            Text(
              'Start the day, then log each stop as you go.',
              name: 'RoundWords',
              color: Colors.secondaryText,
            ),
            Button(
              'Start the round',
              name: 'StartRunButton',
              visible: Not(State('onTheRoad')),
              onTap: [
                PostgresCreate(
                  ff.Tables.feedRuns,
                  outputAs: 'newRun',
                  fields: {
                    'driver_id': const AuthUser(AuthUserField.userId),
                    'status': 'running',
                    'started_at': const Global(GlobalProperty.currentTimestamp),
                  },
                ),
                // The row comes back as a list, so the day's run is read
                // straight back to get its id.
                PostgresRead(
                  ff.Tables.feedRuns,
                  outputAs: 'todayRun',
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
                SetState('runId', ActionOutput('todayRun')['id']),
                SetState('onTheRoad', true),
                Snackbar('The round has started.'),
              ],
            ),
            Button(
              'Log a stop',
              name: 'LogStopButton',
              visible: State('onTheRoad'),
              onTap: Navigate(stopPage),
            ),
            Button(
              'Log a pickup',
              name: 'LogPickupButton',
              visible: State('onTheRoad'),
              onTap: Navigate(pickupPage),
            ),
            Button(
              'Finish the round',
              name: 'FinishRunButton',
              visible: State('onTheRoad'),
              onTap: [
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
                        value: State('runId'),
                      ),
                    ],
                    isSingleRow: true,
                  ),
                ),
                SetState('onTheRoad', false),
                Snackbar('Round finished. Thank you.'),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  app.supabaseAuth(
    providers: const [SupabaseAuthProvider.email],
    homePage: driver,
    signInPage: signIn,
  );
}
