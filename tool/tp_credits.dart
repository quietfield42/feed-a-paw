// Show Test Pilot credit status for a project.  dart run tool/tp_credits.dart <projectId>
import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:flutterflow_ai/src/client/flutterflow_ai_client.dart';
import 'package:flutterflow_ai/src/config/config_resolver.dart';

Future<void> main(List<String> a) async {
  final env = loadMergedEnv();
  final sdk = FlutterFlowAI(apiKey: resolveApiKey(flagValue: null, env: env)!);
  print(await sdk.testPilot.creditStatus(a[0]));
}
