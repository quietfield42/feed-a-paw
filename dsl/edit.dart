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

  // A round follows the route the driver picked (9 Oct 2026).
  //
  // Picking a route on the driver screen already loads its stops in order and
  // sets `currentRouteId` — and the stop form ignored all of it and offered
  // every active spot in the city, alphabetically. The empty state on that
  // same screen promises "Pick a route and start a round, and the places will
  // tick off as they are fed". Nothing ticked off, and the route was
  // decoration.
  //
  // The form now asks `feed_route_plan` for tonight's spots in the order they
  // are driven, and marks the ones already logged on this run so a driver can
  // see what is left without holding the round in their head. A marked spot
  // stays tappable: a stop sometimes has to be logged twice, and refusing
  // would be worse than a duplicate. With no route it falls back to every
  // active spot, which is what an unplanned round needs.
  app.editCustomWidget(ff.CustomWidgets.feedStopForm, (widget) {
    widget.replaceCode(_kit('feed_stop_form.dart'));
  });

  // A meal given out away from the truck is counted (9 Oct 2026).
  //
  // `feed_volunteer_feeds` has been in the schema since the first migration,
  // with insert, update and delete policies and a `feeder` role in
  // `feed_team`, and nothing in the app has ever written a row. Somebody
  // could be made a feeder and then had nothing whatever to do — the same
  // shape as Adopt inviting people to foster animals it never showed.
  //
  // It is worse than an idle table. `feed_meals_daily`, which the public
  // counter on Tonight is built from, is a UNION of the round's stops and the
  // volunteers' feeds. The number the whole app is built around was designed
  // to include meals handed out away from the truck, and that half has always
  // been zero. Every such meal went uncounted, which is the opposite of what
  // Feed-a-Paw is for.
  //
  // The form sits under the round controls rather than on a page of its own:
  // the people who do this are the same people who drive, and a new tab for
  // one panel is a tab nobody looks at. It draws nothing at all for somebody
  // who is not on the team — the round screen already explains that once, and
  // the database would refuse the write anyway.
  final volunteerForm = app.customWidget(
    'FeedVolunteerForm',
    description:
        'Records a feed somebody did away from the truck, so it counts '
        'towards the day the same as a stop on a round.',
    code: _kit('feed_volunteer_form.dart'),
  );

  app.editPage(ff.Pages.driverPage, (page) {
    page.ensureInsertedAfter(
      page.findByKey('Button_ox047bt4'),
      volunteerForm(name: 'VolunteerFeed'),
    );
  });

  // A pickup records WHICH butcher, not a retyped name (9 Oct 2026).
  //
  // `feed_collections.butcher_id` has existed since the first migration and
  // every pickup left it null, because the form only ever asked for a typed
  // name. So `feed_butchers` — a table with its own policies and grants —
  // stayed permanently empty, "Hassan", "hassan butcher" and "Hassan's"
  // became three different suppliers, and nobody could answer the one
  // question worth asking of an operation running on donated meat: how much
  // does each butcher actually give us.
  //
  // The known butchers are chips now, with "Somebody new" revealing the text
  // field and adding them to the list, so the second pickup from the same
  // place is a tap rather than a retype. An empty list opens straight into
  // typing, because making somebody tap "Somebody new" first when there is no
  // list is a step for nothing.
  //
  // `butcher_name` is still written alongside the id on purpose: it is a
  // snapshot, and a butcher renamed next year should not rewrite what last
  // winter's pickups say.
  app.editCustomWidget(ff.CustomWidgets.feedPickupForm, (widget) {
    widget.replaceCode(_kit('feed_pickup_form.dart'));
  });

  // The project carries the unified paw (10 Oct 2026).
  //
  // Feed-a-Paw's launcher icon was still FlutterFlow's default, so the app on a
  // home screen — and the icon in the FlutterFlow editor — was not the app.
  // The Care agent's pack has had a 1024 master for each of the seven since
  // 30 Sep; the web builds have been using it, and only the projects
  // themselves were never told.
  //
  // Set through the proto because `appIconPath` has no typed helper. It takes
  // the storage path an upload returns, never a Flutter bundle path.
  app.raw((project) {
    project.appSettings.appIconPath =
        'projects/feeda-paw-hc0hpt/assets/61ef550ad0a62a8e/feed-app-icon-unified.png';
  });
}
