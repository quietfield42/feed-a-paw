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

String _kit(String name) {
  final text = File('kit/$name').readAsStringSync();
  const marker = '// DO NOT REMOVE OR MODIFY THE CODE ABOVE!';
  final at = text.indexOf(marker);
  return at < 0 ? text.trim() : text.substring(at + marker.length).trim();
}

void buildStarterEditFlow(App app) {
  // A photograph from a stop (29 Sep 2026).
  //
  // The round is the story: who was there, what they were fed. A driver can
  // now take a picture at the stop, see it before saving, and it goes with
  // the stop into feed-photos. The chain is cleared before it is rewritten,
  // because ensureActions leaves an existing one alone.

  final st = ff.Pages.stopPage.state;

  app.editPage(ff.Pages.stopPage, (page) {
    page.ensureInsertedBefore(
      page.findByKey('Button_6xdknv8c'),
      Column(
        name: 'StopPhotographBlock',
        key: 'stop-photograph-block',
        crossAxis: CrossAxis.start,
        spacing: 8,
        children: [
          Image(
            State(st.photoUrl),
            name: 'StopPhotoPreview',
            key: 'stop-photo-preview',
            height: 180,
            borderRadius: 12,
            visible: Not(Equals(State(st.photoUrl), '')),
          ),
          Button(
            'Take a photograph',
            name: 'StopPhotoButton',
            key: 'stop-photo-button',
            onTap: [
              const UploadData(
                key: 'stop-photo-upload',
                actionName: 'stopPhoto',
                destination: UploadDestination.supabase,
              ),
              SetState(st.photoUrl,
                  const ActionResult.uploadUrl('stop-photo-upload'),
                  key: 'keep-stop-photo'),
            ],
          ),
        ],
      ),
    );

    page.removeTrigger(
        page.findByKey('Button_6xdknv8c'), FFActionTriggerType.ON_TAP);
    page.ensureActions(
      page.findByKey('Button_6xdknv8c'),
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        PostgresCreate(
          ff.Tables.feedRunStops,
          key: 'save-stop',
          fields: {
            'run_id': State(st.runId),
            'spot_id': State(st.spotId),
            'meals_served': State(st.meals),
            'animals_seen': State(st.seen),
            'note': State(st.note),
            'photo_path': State(st.photoUrl),
            'arrived_at': const Global(GlobalProperty.currentTimestamp),
          },
          outputAs: 'rows',
        ),
        Snackbar('Stop saved.', key: 'stop-saved-note'),
        const NavigateBack(key: 'stop-saved-back'),
      ],
    );
  });
}
