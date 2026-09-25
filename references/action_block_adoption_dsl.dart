import 'package:flutterflow_ai/flutterflow_ai.dart';

/// Move an existing trigger into a same-name placeholder block. Compatible
/// parameter identities and opaque atoms survive; stale result reads repair.
void extractExistingFlow(
  App app,
  ProjectPageHandle page,
  ProjectParamHandle input,
) {
  app.editPage(page, (edit) {
    edit.extractToActionBlock(
      FFActionTriggerType.ON_INIT_STATE,
      'ProcessEntry',
      {'input': Param(input)},
    );
  });
}
