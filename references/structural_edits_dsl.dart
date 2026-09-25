// Forward-authoring example: structural edits preserve existing node identities.
// `page` is a generated page handle; `value` is its generated state-field handle.
import 'package:flutterflow_ai/flutterflow_ai.dart';

void editStructuralExample(
  App app,
  ProjectPageHandle page,
  ProjectStateFieldHandle value,
) {
  app.editPage(page, (edit) {
    // All move selectors resolve together at the first move. Create any new
    // destinations first. Explicit branch indices identify ConditionalBuilder
    // children; existing visibility conditions move with their children.
    edit.ensureMovedTo(edit.findByKey('shell'), edit.root, slot: 'body');
    edit.ensureMovedTo(edit.findByKey('switch'), edit.findByKey('shell'));
    edit.ensureMovedTo(
      edit.findByKey('content'),
      edit.findByKey('switch'),
      index: 0,
    );
    edit.ensureWrappedWith(
      edit.findByKey('content'),
      Container(name: 'Content frame', key: 'frame'),
    );

    // Define or replace a local block body. Preserve existing parameter names
    // and types when replacing; create a new block for a different signature.
    edit.actionBlock(
      'Apply drag',
      params: {'delta': double_},
      actions: [
        SetState(value, const ActionBlockParam('delta'), key: 'apply-delta'),
      ],
    );
    edit.ensureActions(
      edit.findByKey('frame'),
      triggerType: FFActionTriggerType.ON_PAN_UPDATE,
      actions: [
        ExecuteActionBlock(
          ActionBlock.named('Apply drag', scope: ActionBlockLookupScope.local),
          params: {'delta': GestureInput.deltaX},
          key: 'call-drag',
        ),
      ],
    );

    // Clear retains trigger metadata; removal deletes it. Both are idempotent.
    edit.ensureActions(
      edit.findByKey('frame'),
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [],
    );
    edit.removeTrigger(
      edit.findByKey('frame'),
      FFActionTriggerType.ON_DOUBLE_TAP,
    );
  });
}

void extractExistingLoad(
  App app,
  ProjectPageHandle page,
  ProjectParamHandle entry,
) {
  app.editPage(page, (edit) {
    // Copies the live chain, including opaque atoms. Reads of the supplied
    // expression (including longer field accesses) become block parameter reads.
    edit.extractToActionBlock(FFActionTriggerType.ON_INIT_STATE, 'Load entry', {
      'entry': Param(entry),
    });
  });
}
