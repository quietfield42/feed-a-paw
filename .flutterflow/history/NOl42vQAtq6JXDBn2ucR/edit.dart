library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
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
  // The chosen skin's scenery behind every page (1 Oct 2026).
  //
  // The kit wraps its own screens in apawBackground; a FlutterFlow page cannot
  // be wrapped from outside, so the scenery goes in as the bottom layer of a
  // stack and the page's own content sits on top. The stack is built in the
  // floating-button slot, the content is moved into it, and then the stack
  // takes the body — a page body holds one thing, so it has to be done in that
  // order.
  //
  // The sign-in screen is left alone: the kit's front door paints its own.

  app.raw((project) {
    updateCustomWidget(project, name: 'FeedIcons', code: _kit('feed_icons.dart'));
  });

  final skin = app.customWidget(
    'FeedSkin',
    parameters: {'scene': string},
    description: "The chosen skin's scenery, behind a page.",
    code: _kit('feed_skin.dart'),
  );

  app.editPage(ff.Pages.driverPage, (page) {
    page.ensureInsertedInto(
      page.root,
      Stack(
        name: 'DriverSkin',
        key: 'driver-skin',
        alignment: Alignment.topCenter,
        children: [
          skin(name: 'DriverBackdrop', scene: 'paws'),
          Container(
            name: 'DriverContent',
            key: 'driver-content',
            width: double.infinity,
            height: double.infinity,
          ),
        ],
      ),
      slot: 'floatingActionButton',
    );
    page.ensureMovedTo(
      page.findByKey('Container_9fa9vthk'),
      page.findByKey('driver-content'),
    );
    page.ensureMovedTo(
      page.findByKey('driver-skin'),
      page.root,
      slot: 'body',
    );
  });
  app.editPage(ff.Pages.storiesPage, (page) {
    page.ensureInsertedInto(
      page.root,
      Stack(
        name: 'StoriesSkin',
        key: 'stories-skin',
        alignment: Alignment.topCenter,
        children: [
          skin(name: 'StoriesBackdrop', scene: 'paws'),
          Container(
            name: 'StoriesContent',
            key: 'stories-content',
            width: double.infinity,
            height: double.infinity,
          ),
        ],
      ),
      slot: 'floatingActionButton',
    );
    page.ensureMovedTo(
      page.findByKey('Column_tapxo0rg'),
      page.findByKey('stories-content'),
    );
    page.ensureMovedTo(
      page.findByKey('stories-skin'),
      page.root,
      slot: 'body',
    );
  });
  app.editPage(ff.Pages.aboutPage, (page) {
    page.ensureInsertedInto(
      page.root,
      Stack(
        name: 'AboutSkin',
        key: 'about-skin',
        alignment: Alignment.topCenter,
        children: [
          skin(name: 'AboutBackdrop', scene: 'paws'),
          Container(
            name: 'AboutContent',
            key: 'about-content',
            width: double.infinity,
            height: double.infinity,
          ),
        ],
      ),
      slot: 'floatingActionButton',
    );
    page.ensureMovedTo(
      page.findByKey('Container_a4mf6bd3'),
      page.findByKey('about-content'),
    );
    page.ensureMovedTo(
      page.findByKey('about-skin'),
      page.root,
      slot: 'body',
    );
  });
  app.editPage(ff.Pages.pickupPage, (page) {
    page.ensureInsertedInto(
      page.root,
      Stack(
        name: 'PickupSkin',
        key: 'pickup-skin',
        alignment: Alignment.topCenter,
        children: [
          skin(name: 'PickupBackdrop', scene: 'paws'),
          Container(
            name: 'PickupContent',
            key: 'pickup-content',
            width: double.infinity,
            height: double.infinity,
          ),
        ],
      ),
      slot: 'floatingActionButton',
    );
    page.ensureMovedTo(
      page.findByKey('Container_8betwhp6'),
      page.findByKey('pickup-content'),
    );
    page.ensureMovedTo(
      page.findByKey('pickup-skin'),
      page.root,
      slot: 'body',
    );
  });
  app.editPage(ff.Pages.stopPage, (page) {
    page.ensureInsertedInto(
      page.root,
      Stack(
        name: 'StopSkin',
        key: 'stop-skin',
        alignment: Alignment.topCenter,
        children: [
          skin(name: 'StopBackdrop', scene: 'paws'),
          Container(
            name: 'StopContent',
            key: 'stop-content',
            width: double.infinity,
            height: double.infinity,
          ),
        ],
      ),
      slot: 'floatingActionButton',
    );
    page.ensureMovedTo(
      page.findByKey('Container_3y45sqpe'),
      page.findByKey('stop-content'),
    );
    page.ensureMovedTo(
      page.findByKey('stop-skin'),
      page.root,
      slot: 'body',
    );
  });
}
