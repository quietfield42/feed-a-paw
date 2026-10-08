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
  // A stranger who signs up is told so, instead of pressing a dead button
  // (8 Oct 2026).
  //
  // Every writable Feed table and the photograph bucket are gated on
  // `feed_is_team()`, and only a lead can add somebody to `feed_team`. So a
  // person who signs up out of interest can read everything and publish
  // nothing — which is right. What was wrong is that nothing said so. The
  // Round screen offered "Start the round", the insert was refused by the
  // database, the action chain stopped at that line, and the button did
  // nothing at all. No message, no error, no clue.
  //
  // `FeedTeamGate` asks the database whether this person is on the team and,
  // only when the answer is no, says so above the button. It draws nothing
  // while it is asking and nothing for somebody on the team, so the screen is
  // unchanged for everyone who belongs there.
  //
  // The previous run's `ensureMovedTo` is deliberately not repeated: it pins
  // the button to index 3, which is where the panel now goes, and re-running
  // it would put the button back above its own explanation.

  final teamGate = app.customWidget(
    'FeedTeamGate',
    description:
        'Says so when somebody is signed in but not on the feeding team, so '
        'the round controls are explained rather than silently dead.',
    code: _kit('feed_team_gate.dart'),
  );

  app.editPage(ff.Pages.driverPage, (page) {
    page.ensureInsertedBefore(
      page.findByKey('Button_ox047bt4'),
      teamGate(name: 'TeamGate'),
    );
  });
  // Every long form in the family was clipped (8 Oct 2026).
  //
  // Found from Ash's note that Mind's new-client form would not scroll. It is
  // not one screen: all six form pages across Feed, Adopt and Mind are a Stack
  // holding a double.infinity Container, a Padding and a Column, with no
  // scroll view anywhere. Whatever does not fit the screen simply cannot be
  // reached — on Feed that is the note and the Save button at the bottom of a
  // stop.
  //
  // FlutterFlow's Column carries its own `scrollable`, which codegen turns
  // into the SingleChildScrollView the page should have had. Setting it on the
  // page's Column is a smaller and safer change than wrapping the tree.
  for (final (page, column) in [
    (ff.Pages.stopPage, 'Column_m8c03tk5'),
    (ff.Pages.pickupPage, 'Column_i93rfsuo'),
    (ff.Pages.aboutPage, 'Column_grza0aw7'),
  ]) {
    app.editPage(page, (p) {
      p.mutateNode(p.findByKey(column), (node) {
        node.props.column.scrollable = true;
      });
    });
  }
}
