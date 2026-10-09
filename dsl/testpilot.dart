// Test Pilot: Feed-a-Paw core flows.
//
// Written 8 Oct 2026 from briefs/TEST-PILOT.md. Five tests, because a free
// project has five credits and a run costs one per enabled test.
//
// The demo login is a group parameter, never in this file. Ash fills it in on
// FlutterFlow -> the project -> Test Pilot -> the group.
//
// IDS (created 8 Oct 2026). Running this file without them makes a second
// copy of the group and every test.
//   group  NZIPuD6S87dZdjXURrRQ
//   Anyone can look without an account                 JNLnhMIQ9HnSPrdU22P6
//   Stories open                                       T7oovl7ghmBCjE1SrejG
//   About says follow the truck, and asks for nothing  nYXxRPyUXkxv5fsy4pBk
//   The driver round opens for a signed-in person      85vvPr7lOUlgJCXgyiaT
//   Account tools work                                 X6hIL4AFnFzwnaH5gbYa

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
      buildFeedTests,
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

// ---------------------------------------------------------------------------
// Test Pilot: end-to-end tests for Track-a-Paw (written 7 Oct 2026). Run ONCE with
//   flutterflow ai run dsl/testpilot.dart --project-id track-a-paw-mxv4up
// after Ash moves the Test Pilot credit pass to Track. Then record the group
// DONE 7 Oct: group EFQ2ejSQe70PxpVCj9rQ. Tests: sign-in neCF4bHLqOZY2Uot67JE, lost form 9Eaj1e9WOrtrIq4Y7mO4,
// tag JrEPk1AyHg42ZzoyXS3X, messages 2JBA3LGk37GrEJGkF6dW, account L42NELmV9mqQWxqaV0ic, sign-up MArvFqPfoo6fhVjBLW61.
// Do NOT run again without ids (it would duplicate).
// No test posts a real alert: alerts are public to people nearby.
void buildFeedTests(App app) {
  const signIn = r'On the welcome screen tap "I already have an account". Enter $email in the Email field and '
      r'$password in the Password field, then tap the "Sign in" button. Wait for the "Tonight" screen.';
  app.testGroup(
    'Feed-a-Paw core flows',
    id: 'NZIPuD6S87dZdjXURrRQ',
    environment: TestEnvironment.production,
    device: TestDevice.iPhone15,
    parameters: const [
      TestParam('email', label: 'Demo email'),
      TestParam('password', label: 'Demo password', isSecret: true),
    ],
    tests: [
      app.qaTest('Anyone can look without an account',
          id: 'JNLnhMIQ9HnSPrdU22P6',
          instructions: 'On the welcome screen tap "Look around first". Wait for the Tonight screen and read it.',
          expectedOutcome: 'Today opens without asking anyone to sign in. It shows two cards of figures, '
              '"Meals served today" and "Meals since the first round", each with a number, and a bottom bar. '
              'No blank screen and no error.',
          restartBeforeTest: true),
      app.qaTest('Stories open',
          id: 'T7oovl7ghmBCjE1SrejG',
          instructions: 'On the welcome screen tap "Look around first". In the bottom bar tap "Stories".',
          expectedOutcome: 'The Stories tab shows either a list of stories or a picture saying there are none '
              'yet. It is not blank and shows no error.',
          restartBeforeTest: true),
      app.qaTest('About says follow the truck, and asks for nothing',
          id: 'nYXxRPyUXkxv5fsy4pBk',
          instructions: 'On the welcome screen tap "Look around first". In the bottom bar tap "About" and read '
              'the whole page, scrolling to the bottom.',
          expectedOutcome: 'About SCROLLS all the way to the bottom — nothing is cut off at the screen edge. '
              'It explains the rounds and says to follow the truck on onetailonemeal.com. '
              'Nowhere does it ask for money, and the words donation, charity and tax deductible do not appear.',
          restartBeforeTest: true),
      app.qaTest('The driver round opens for a signed-in person',
          id: '85vvPr7lOUlgJCXgyiaT',
          instructions: '$signIn In the bottom bar tap "Round". Read the WHOLE screen, scrolling to the '
              'bottom, and say exactly what panels you can see.',
          expectedOutcome: 'ONE of two things, and say which. EITHER this account is on the feeding team, and '
              'the screen offers a round to start (or the stops for tonight if one is running) and, lower down, a '
              'panel headed "Fed some animals yourself?" with a spot chooser, Meals and Animals seen boxes and '
              'a "Count this feed" button. OR this account is NOT on the team, and a panel says so in words — '
              '"You are not on the feeding team yet" — explaining that a lead adds people and that starting a '
              'round here will not do anything. The second is correct behaviour, not a failure: what would be '
              'wrong is a Start button that silently does nothing. The page scrolls either way.',
          restartBeforeTest: true),
      app.qaTest('Account tools work',
          id: 'X6hIL4AFnFzwnaH5gbYa',
          instructions: '$signIn In the bottom bar tap "Account". Tap "Look & feel", choose "Egyptian", then '
              'tap "Done". Tap "Contact support", check the form opens, then close it without sending. '
              'Finally tap "Privacy".',
          expectedOutcome: 'Look & feel closes after Done and the screen takes the Egyptian look. Contact '
              'support shows a topic chooser and a message box. Privacy opens the Feed-a-Paw privacy policy.',
          restartBeforeTest: true),
    ],
  );
}
