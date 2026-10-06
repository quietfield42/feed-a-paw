library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
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
  // A back button only where there is something to go back to (6 Oct 2026).
  //
  // The bar went onto every page that had an app bar, and one of those —
  // Adopt's Rescue — is a stop on the bottom bar, not a page you were pushed
  // to. The bottom bar navigates with `go`, which replaces the stack, so
  // nothing can be popped there and a back button would be a lie. The bar
  // asks the navigator: nothing to pop means the app's mark and the page's
  // name, which is the family header; something to pop means the button.

  app.raw((project) {
    updateCustomWidget(project, name: 'FeedTopBar', code: _kit('feed_topbar.dart'));
  });
}
