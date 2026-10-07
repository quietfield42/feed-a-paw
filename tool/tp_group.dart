// Show a Test Pilot group's parameter names and whether values are set (never the values).
import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:flutterflow_ai/src/client/flutterflow_ai_client.dart';
import 'package:flutterflow_ai/src/config/config_resolver.dart';

Future<void> main(List<String> a) async {
  final env = loadMergedEnv();
  final sdk = FlutterFlowAI(apiKey: resolveApiKey(flagValue: null, env: env)!);
  for (final g in await sdk.testPilot.listGroups(a[0])) {
    if (g.id != a[1]) continue;
    final s = g.group.toProto3Json().toString();
    final masked = s.replaceAllMapped(RegExp(r'(value: )([^,}\]]*)'), (m) => '${m[1]}${m[2]!.trim().isEmpty ? "<empty>" : "<set>"}');
    print(masked.length > 1500 ? masked.substring(0, 1500) : masked);
  }
}
