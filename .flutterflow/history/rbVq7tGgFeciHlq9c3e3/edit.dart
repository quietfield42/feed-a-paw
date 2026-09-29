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
  // Stories, rebuilt around its header (29 Sep 2026).
  //
  // The whole page was the list, and a page body holds one thing. Asking for
  // a header above it left two widgets hanging off the screen where nothing
  // draws them — they were in the file and invisible in the app. So the body
  // becomes a column: the header, the line for when there is nothing yet,
  // and the list filling what is left.

  final header = app.customWidget(
    'FeedHeader',
    parameters: {'title': string, 'subtitle': string},
    description: "The app's mark and the screen's name, at the top of a main screen.",
    code: _kit('feed_header.dart'),
  );

  final empty = app.customWidget(
    'FeedEmpty',
    parameters: {'which': string, 'items': listOf(ff.Tables.feedStories)},
    description: 'Empty-state drawing from the pack, for a bare list.',
    code: _kit('feed_empty.dart'),
  );

  app.editPage(ff.Pages.storiesPage, (page) {
    page.ensureRemoved(
        ff.Pages.storiesPage.widgets.byKey('Container_bfvcdhoa').single);
    page.ensureRemoved(
        ff.Pages.storiesPage.widgets.byKey('Container_5loexhpl').single);
    page.ensureReplaced(
      ff.Pages.storiesPage.widgets.byKey('ListView_8ryng321').single,
      Column(
        name: 'StoriesBody',
        crossAxis: CrossAxis.start,
        spacing: 12,
        children: [
          header(name: 'StoriesHeader', title: 'From the street', subtitle: ''),
          empty(
            name: 'StoriesEmpty',
            which: 'stories',
            items: State(ff.Pages.storiesPage.state.stories),
          ),
          Expanded(
            ListView(
              name: 'StoryList',
              source: State(ff.Pages.storiesPage.state.stories),
              spacing: 14,
              itemBuilder: (item) => Card(
                child: Column(
                  crossAxis: CrossAxis.start,
                  spacing: 8,
                  children: [
                    Image(item['photo_path'], height: 180, fit: ImageFit.cover,
                        borderRadius: 12),
                    Text(item['title'], style: Styles.titleMedium),
                    Text(item['words'], style: Styles.bodyMedium),
                    Text(item['area'],
                        style: Styles.labelSmall, color: Colors.secondaryText),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
