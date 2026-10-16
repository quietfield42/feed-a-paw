library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:flutterflow_ai/src/helpers/ensure_helpers.dart'
    show ensurePubDependency;
import 'package:flutterflow_ai/src/helpers/project_helpers.dart'
    show updateStateField;
import 'package:fixnum/fixnum.dart' show Int64;
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
  // The Manage account and Contact support cards sat welded together
  // (Ash, 13 Oct 2026).
  //
  // Every other row in that column is followed by a 10pt gap; those two were
  // not, because the comment had been written where the spacer should have
  // been. Ash saw it on Adopt and Mind, and Feed had it too — the same three
  // lines in all three account screens.
  //
  // It reads as a wrapping bug, since "Password, email and your data, on the
  // web" runs to two lines and makes the seam obvious, but the gap was never
  // there at any width. The shared kit is innocent: `apawManageAccountRow` and
  // `apawSupportRow` are plain cards with no margin, exactly like every other
  // row, and the page supplies the spacing.
  app.editCustomWidget(ff.CustomWidgets.feedAccount, (w) {
    w.replaceCode(_kit('feed_account.dart'));
  });

  // 16 Oct 2026: iPhone build. The pickers close the app on iPhone without
  // these usage texts; iOS only, so Android keeps declaring no camera permission.
  final plist = app.nativeFile(NativeFile.infoPlist);
  plist..hook(NativeFileHook.infoPlistProperty, name: 'Camera usage',
      content: '<key>NSCameraUsageDescription</key><string>Feed-a-Paw uses the camera to photograph the animals fed at a stop.</string>');
  plist..hook(NativeFileHook.infoPlistProperty, name: 'Photo library usage',
      content: '<key>NSPhotoLibraryUsageDescription</key><string>Feed-a-Paw lets you choose a photo of a stop from your library.</string>');
  // TestFlight/App Store: HTTPS only, so the app is exempt from export rules.
  plist..hook(NativeFileHook.infoPlistProperty, name: 'Export compliance',
      content: '<key>ITSAppUsesNonExemptEncryption</key><false/>');
  // Apple ITMS-90683 (16 Oct): a bundled library references location, so the key must exist.
  plist..hook(NativeFileHook.infoPlistProperty, name: 'Location when in use',
      content: '<key>NSLocationWhenInUseUsageDescription</key><string>Feed-a-Paw does not use your location.</string>');
}
