/// LinkDrop — a FlutterFlow Dynamic Links showcase in the FlutterFlow AI DSL.
///
/// Demonstrates the whole round trip:
///
/// * enabling FlutterFlow Dynamic Links and the app identity the verification
///   files are built from (`app.dynamicLinks`),
/// * minting a link to the current page, parameters included
///   (`GenerateCurrentPageLink`),
/// * sharing and copying that link (`Share` / `CopyToClipboard` reading the
///   action output),
/// * receiving an incoming link — a deep link opens `ProductDetailPage`
///   directly with its route parameters, which is what routing delivers.
///
/// The link host is not configured here: the links service assigns each
/// project its own, and codegen reads it back to build the App Link and
/// Universal Link verification. Register the app to get one.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

Future<void> main(List<String> args) async {
  final options = _parseCliOptions(args);
  await flutterFlowAI(
    buildDynamicLinksShowcase,
    apiKey: options.apiKey,
    baseUrl: options.baseUrl,
    projectName: options.projectName,
    projectId: options.projectId,
    findOrCreate: options.findOrCreate,
    dryRun: options.dryRun,
    commitMessage: options.commitMessage,
  );
}

void buildDynamicLinksShowcase(App app) {
  // ===================== DYNAMIC LINKS ====================
  //
  // App identity. Without it a link still redirects, but iOS and Android
  // decline to hand it to the app. None of these are secrets — they are
  // published in the verification files. The host itself is assigned by the
  // links service on registration, so it is not set here.
  app.dynamicLinks(
    iosTeamId: 'A1B2C3D4E5',
    iosAppStoreId: '123456789',
    androidSha256Fingerprints: const [
      'AB:CD:EF:01:23:45:67:89:AB:CD:EF:01:23:45:67:89:'
          'AB:CD:EF:01:23:45:67:89:AB:CD:EF:01:23:45:67:89',
    ],
    webFallbackUrl: 'https://flutterflow.io',
  );

  app.constant('appName', 'LinkDrop');

  // ====================== PRODUCT LIST ====================

  app.page(
    'ProductListPage',
    route: '/',
    isInitial: true,
    body: Scaffold(
      appBar: AppBar(title: 'LinkDrop'),
      body: Container(
        color: Colors.primaryBackground,
        padding: 24,
        child: Column(
          crossAxis: CrossAxis.start,
          spacing: 12,
          children: [
            Text(
              'Tap a product, then share its link.',
              style: Styles.bodyMedium,
            ),
            _productTile(id: 'p-001', name: 'Aeropress Go', price: '\$39.00'),
            _productTile(id: 'p-002', name: 'Hario Grinder', price: '\$54.00'),
            _productTile(id: 'p-003', name: 'Fellow Kettle', price: '\$95.00'),
          ],
        ),
      ),
    ),
  );

  // ===================== PRODUCT DETAIL ===================
  //
  // This is both the link *target* and the link *source*: an incoming dynamic
  // link opens this page with `productId` / `name` already populated, and the
  // share buttons mint a link back to whatever the page is currently showing.
  app.page(
    'ProductDetailPage',
    route: '/product',
    // Defaulted, not required. A cold-entry deep link is exactly the case
    // where a required param arrives null and the page throws on build — and
    // that is the case this app exists to demonstrate.
    params: {
      'productId': string.withDefault(''),
      'name': string.withDefault(''),
      'price': string.withDefault(''),
    },
    state: {'lastLink': string},
    // Proves the incoming link's parameters arrived with the route: on a cold
    // open from a dynamic link this fires with the id encoded in the link.
    onLoad: [Snackbar(PageParam('productId'))],
    body: Scaffold(
      appBar: AppBar(title: 'Product'),
      body: Container(
        color: Colors.primaryBackground,
        padding: 24,
        child: Column(
          crossAxis: CrossAxis.start,
          spacing: 16,
          children: [
            Text(PageParam('name'), style: Styles.headlineMedium),
            Text(PageParam('price'), style: Styles.titleLarge),
            Row(
              spacing: 4,
              children: [
                Text('Product id:', style: Styles.bodySmall),
                Text(PageParam('productId'), style: Styles.bodySmall),
              ],
            ),

            // --- Share: mint a link, stash it for display, open the sheet ---
            Button(
              'Share this product',
              onTap: [
                GenerateCurrentPageLink(
                  title: PageParam('name'),
                  description: 'Found this on LinkDrop',
                  previewImageUrl: 'https://picsum.photos/seed/linkdrop/600',
                  forceRedirect: false,
                  outputAs: 'link',
                ),
                SetState('lastLink', ActionOutput('link')),
                Share(ActionOutput('link')),
              ],
            ),

            // --- Copy: same link, straight to the clipboard ---
            Button(
              'Copy link',
              onTap: [
                GenerateCurrentPageLink(
                  title: PageParam('name'),
                  outputAs: 'link',
                ),
                SetState('lastLink', ActionOutput('link')),
                CopyToClipboard(ActionOutput('link')),
                Snackbar('Link copied'),
              ],
            ),

            // --- The generated URL, so the demo is visible on screen ---
            Text(State('lastLink'), style: Styles.bodySmall),
          ],
        ),
      ),
    ),
  );
}

/// One tappable product row that navigates into the link target page.
DslWidget _productTile({
  required String id,
  required String name,
  required String price,
}) => Container(
  onTap: Navigate(
    'ProductDetailPage',
    params: {'productId': id, 'name': name, 'price': price},
  ),
  color: Colors.secondaryBackground,
  padding: 16,
  borderRadius: 12,
  child: Row(
    mainAxis: MainAxis.spaceBetween,
    children: [
      Text(name, style: Styles.titleMedium),
      Text(price, style: Styles.titleSmall),
    ],
  ),
);

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

final class _CliOptions {
  const _CliOptions({
    this.apiKey,
    this.baseUrl,
    this.projectName,
    this.projectId,
    this.findOrCreate = false,
    this.dryRun = false,
    this.commitMessage,
  });

  final String? apiKey;
  final String? baseUrl;
  final String? projectName;
  final String? projectId;
  final bool findOrCreate;
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
  var dryRun = false;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
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
      case '--dry-run':
        dryRun = true;
      default:
        stderr.writeln('Unknown option: ${args[i]}');
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
    dryRun: dryRun,
    commitMessage: commitMessage,
  );
}

String _requireValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    stderr.writeln('Missing value for $flag');
    exit(64);
  }
  return args[index];
}

void _printUsage() {
  stdout.writeln('''
Run the LinkDrop Dynamic Links showcase and push it to FlutterFlow.

Usage:
  dart run specs/dsl/dynamic_links_showcase_dsl.dart [options]

Options:
  --api-key <key>         FlutterFlow API key. Defaults to FF_API_KEY.
  --base-url <url>        Override the FlutterFlow API base URL.
  --project-name <name>   Create a new project with this name.
  --project-id <id>       Push into an existing project by ID.
  --find-or-create        Find by project name before creating.
  --commit-message <msg>  Commit message for the push.
  --dry-run               Compile and validate without pushing.
  --help, -h              Show this help.
''');
}
