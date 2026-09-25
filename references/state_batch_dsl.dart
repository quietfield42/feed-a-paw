import 'package:flutterflow_ai/flutterflow_ai.dart';

/// One state atom can set and clear fields together. Disabled keeps that body
/// visible to inspect; enable it with the ordinary keyed edit operation.
void buildStateBatchExample(App app) {
  app.page(
    'Entry',
    route: '/',
    isInitial: true,
    state: {'invalid': bool_, 'notice': string},
    body: Scaffold(
      body: Form(
        name: 'EntryForm',
        child: Button(
          'Save',
          key: 'save',
          onTap: [
            Disabled([
              SetState.many(
                {'invalid': false},
                clear: ['notice'],
                key: 'reset',
              ),
            ], key: 'disabled-reset'),
            ValidateForm('EntryForm', key: 'validate'),
          ],
        ),
      ),
    ),
  );
}
