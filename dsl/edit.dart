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
  // Splash: the app opens on its own paw (12 Oct 2026).
  //
  // Ash noticed FlutterFlow's project cards showing a blank FlutterFlow
  // picture — the card uses the app's splash image, and only Use It Fresh had
  // one. Care, Track and Snap were done today; this is the same for Feed. The
  // message is read-only, so it is copied, changed and assigned back.
  app.raw((p) {
    final settings = p.ensureAppSettings();
    final s = settings.splashImage.deepCopy()
      ..path = settings.appIconPath
      ..fit = FFBoxFit.FF_BOX_FIT_CONTAIN
      ..backgroundColor = FFColor(value: Int64(0xFF1F5148))
      ..preLoadingColor = FFColor(value: Int64(0xFF1F5148));
    settings.splashImage = s;
  });

  // F4: the lists that render blank, and F3: counters that always read 0.
  //
  // Today holds a ListView inside a Column that does not bound its height, so
  // it throws a RenderFlex error and draws nothing whenever there IS a story.
  // The review asks for `Expanded`, which is the better answer because it
  // keeps the list lazy — but the SDK has no way I can find to set that flag
  // on a Column child (it is not in the exported DSL, the raw node props, or
  // the docs). So the column scrolls and the list shrink-wraps, which is the
  // shape already proven on Mind's Clients and Invoices, and the laziness
  // concern is answered instead by F2's limit below: Today now asks for the
  // twenty newest stories rather than every story ever written.
  //
  // F3: `loadedTotals` was queried on every open and never read, so the two
  // counters above the stories always showed 0. The query was already paid
  // for; it is now used.
  app.editPage(ff.Pages.todayPage, (page) {
    page.mutateNode(page.findByKey('ListView_6t3c5h99'), (node) {
      node.props.listView.shrinkWrapValue = FFBooleanValue(inputValue: true);
    });
    page.mutateNode(page.findByKey('Column_8vemqkot'), (node) {
      node.props.column.scrollable = true;
    });
    page.removeTrigger(page.root, FFActionTriggerType.ON_INIT_STATE);
  });

  app.editPageOnLoad(ff.Pages.todayPage, [
    PostgresRead(
      ff.Tables.feedTotals,
      key: 'read-totals',
      outputAs: 'loadedTotals',
      query: PostgresQuerySpec(),
    ),
    SetState(ff.Pages.todayPage.state.mealsToday,
        const ActionOutput('loadedTotals')['meals_today'],
        key: 'keep-meals-today'),
    SetState(ff.Pages.todayPage.state.mealsAllTime,
        const ActionOutput('loadedTotals')['meals_all_time'],
        key: 'keep-meals-all-time'),
    PostgresQuery(
      ff.Tables.feedStories,
      key: 'read-stories',
      outputAs: 'loadedStories',
      query: PostgresQuerySpec(
        // F2: newest first and bounded. It was oldest-first and unbounded, so
        // Today showed every story ever written, in the wrong order.
        orderBys: [PostgresOrderBy('published_at', ascending: false)],
        limit: 20,
      ),
    ),
    SetState(ff.Pages.todayPage.state.stories,
        const ActionOutput('loadedStories'),
        key: 'keep-stories'),
  ]);

  // Stories: the same blank-list bug, but this one lives in the kit widget,
  // which now lays out for the height it is given.
  app.editCustomWidget(ff.CustomWidgets.feedStoryList, (w) {
    w.replaceCode(_kit('feed_story_list.dart'));
  });
}
