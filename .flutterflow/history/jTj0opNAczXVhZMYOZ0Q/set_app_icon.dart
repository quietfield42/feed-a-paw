// Uploads an a-Paw app's icon PNGs and sets them as the FlutterFlow app icon
// and Android adaptive icon (forest background), like Spot a Paw's settings.
// Usage (from the app's workspace): dart run .ffai_staging/set_app_icon.dart <app> <projectId>
import 'dart:io';
import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:flutterflow_ai/src/config/config_resolver.dart';
import 'package:flutterflow_ai/src/client/flutterflow_ai_client.dart' show FlutterFlowAI;

const pack =
    r'C:\Users\ashel\OneDrive\Documents\9. One Tail One Meal\a-paw-family\0. Design\a-paw-icon-pack\app-icons';

Future<void> main(List<String> args) async {
  final app = args[0], projectId = args[1];
  final env = loadMergedEnv();
  final key = resolveApiKey(flagValue: null, env: env);
  if (key == null || key.isEmpty) throw StateError('no FlutterFlow API key found');
  final sdk = FlutterFlowAI(apiKey: key, baseUrl: resolveBaseUrl(flagValue: null, env: env));
  final icon = await sdk.assets.uploadFile(projectId, File('$pack/$app/$app-app-1024.png'));
  final fg = await sdk.assets.uploadFile(projectId, File('$pack/$app/$app-adaptive-foreground.png'));
  stdout.writeln('uploaded ${icon.storagePath} ${fg.storagePath}');

  await flutterFlowAI((App a) {
    a.raw((project) {
      final s = project.ensureAppSettings();
      s.appIconPath = icon.storagePath;
      s.androidAdaptiveIcon = FFAndroidAdaptiveIcon(
        foregroundImagePath: fg.storagePath,
        backgroundColor: FFColor()..mergeFromProto3Json({'value': '4280242504'}), // #FF1F5148 forest
      );
    });
  }, projectId: projectId, commitMessage: 'App icon from the a-Paw icon pack');
}
