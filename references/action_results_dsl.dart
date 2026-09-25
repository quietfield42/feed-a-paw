library;

import 'package:flutterflow_ai/flutterflow_ai.dart';

/// Upload widget-state results differ from ordinary ActionOutput values.
void buildActionResults(App app) {
  final people = app.collection(
    'Members',
    fields: {'photo': string, 'blur': string},
  );
  app.page('SignIn', route: '/sign-in', body: Text('Sign in'));
  app.page(
    'Editor',
    route: '/',
    body: Button(
      'Save',
      key: 'save',
      onTap: [
        const UploadData(
          key: 'upload',
          actionName: 'portrait',
          destination: UploadDestination.firebase,
          blurHash: true,
        ),
        FirestoreUpdate(
          const AuthUser(AuthUserField.documentReference),
          collection: people,
          key: 'update',
          fields: {
            'photo': const ActionResult.uploadUrl('upload'),
            'blur': const ActionResult.uploadBlurHash('upload'),
          },
        ),
        Disabled([Snackbar('Retained', key: 'notice')], key: 'disabled'),
        const CloseDialog(key: 'close'),
      ],
    ),
  );
  app.firebaseAuth(
    providers: [FirebaseAuthProvider.email],
    homePage: 'Editor',
    signInPage: 'SignIn',
    autoCreateUserDocument: true,
    userCollectionName: 'Members',
  );
}
