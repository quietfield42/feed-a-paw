// Start or read a Test Pilot run (the CLI's run command is broken in this SDK build).
//   dart run tool/tp_run.dart start <projectId> <groupId>
//   dart run tool/tp_run.dart get <projectId> <runId>
import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:flutterflow_ai/src/client/flutterflow_ai_client.dart';
import 'package:flutterflow_ai/src/config/config_resolver.dart';

Future<void> main(List<String> a) async {
  final env = loadMergedEnv();
  final sdk = FlutterFlowAI(apiKey: resolveApiKey(flagValue: null, env: env)!);
  if (a[0] == 'start') {
    final c = await sdk.testPilot.creditStatus(a[1]);
    print('credits: $c');
    final e = await sdk.testPilot.startRun(a[1], groupId: a[2], environment: TestEnvironment.production.toProto());
    print('started: $e');
  } else {
    final r = await sdk.testPilot.getRun(a[1], a[2]);
    print(r.run); for (final t in r.results) { print(t.result); }
  }
}
