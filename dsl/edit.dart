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
  // The round page offered a button it had just said would do nothing
  // (11 Oct 2026).
  //
  // Seen by driving the live build and looking at the screen, signed in as the
  // family demo account — which is not on the feeding team. The page reads:
  //
  //     Tonight you are driving
  //     [ a tall empty gap where the rounds would be ]
  //     "You are not on the feeding team yet ... until somebody adds you,
  //      starting a round here will not do anything."
  //     [ Start the round ]
  //
  // So the gate explains, in words, that the button below it is dead — and
  // then the button is drawn anyway. That is the exact dead control the gate
  // was built to replace. The heading has the same problem from the other
  // side: it announces a list that is not there.
  //
  // Both now depend on there being a round to drive. `routes` is empty for
  // anybody not on the team, because `feed_routes` is gated by
  // `feed_is_team()` in its own policy — so this needs no new query and no new
  // idea of who is on the team; it reuses the answer the database already
  // gave.
  //
  // The button keeps its existing condition as well: it must still disappear
  // once a round is running, which is what `onTheRoad` was already doing.
  // `bindVisible` replaces a condition rather than adding to it, so that part
  // is written into the expression instead of being lost.

  final hasRounds = CodeExpression(
    r'rounds.isNotEmpty',
    args: {'rounds': State(ff.Pages.driverPage.state.routes)},
    returns: bool_,
  );

  final canStart = CodeExpression(
    // Both arrive nullable in the generated code, whatever their declared
    // type on the page — the first attempt used `rounds.isNotEmpty` and
    // FlutterFlow accepted the push while the Dart would not compile
    // ("The property 'isNotEmpty' can't be unconditionally accessed because
    // the receiver can be 'null'"). So both are handled null-safely here.
    r'(onRoad != true) && (rounds?.isNotEmpty ?? false)',
    args: {
      'onRoad': State(ff.Pages.driverPage.state.onTheRoad),
      'rounds': State(ff.Pages.driverPage.state.routes),
    },
    returns: bool_,
  );

  app.editPage(ff.Pages.driverPage, (page) {
    page.bindVisible(page.findByKey('Text_rd5xgy0b'), hasRounds);   // the heading
    page.bindVisible(page.findByKey('Button_ox047bt4'), canStart);  // Start the round
  });
}
