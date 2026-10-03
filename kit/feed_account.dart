import '/backend/supabase/supabase.dart';
import '/custom_code/widgets/feed_nav_bar.dart' show FeedNavBar;
import '/custom_code/widgets/feed_icons.dart'
    show
        apawBackground,
        apawCard,
        apawDisplay,
        apawHeader,
        apawIcon,
        apawIconChip,
        apawSecondary,
        apawSkinRow,
        apawText,
        ApawColors;

/// Your account: the look and feel, and the way out.
///
/// Every app in the family has the same screen, so the "Look & feel" picker
/// sits in the same place wherever somebody looks for it. The choice is kept
/// on the person's profile, so it follows them into the other apps.
class FeedAccount extends StatefulWidget {
  const FeedAccount({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<FeedAccount> createState() => _FeedAccountState();
}

class _FeedAccountState extends State<FeedAccount> {
  bool _leaving = false;

  Future<void> _signOut() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      await SupaFlow.client.auth.signOut();
    } catch (_) {}
    if (mounted) context.goNamed('SignInPage');
  }

  @override
  Widget build(BuildContext context) {
    final email = SupaFlow.client.auth.currentUser?.email ?? '';
    return apawBackground(
      scene: 'paws',
      child: Stack(children: [
      SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
          children: [
            apawHeader('feed', 'Your account'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (email.isNotEmpty)
                    apawCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(children: [
                        apawIconChip('common-settings', size: 40),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Signed in as',
                                  style: apawText(
                                      size: 13, color: ApawColors.muted)),
                              Text(email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: apawText(
                                      size: 15,
                                      color: ApawColors.forest,
                                      weight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  const SizedBox(height: 10),
                  apawSkinRow(context),
                  const SizedBox(height: 18),
                  Text('Feed-a-Paw is One Tail One Meal’s own app, feeding '
                      'street animals every day.',
                      style: apawText(size: 13, color: ApawColors.muted)),
                  const SizedBox(height: 10),
                  apawCard(
                    onTap: () => launchURL('https://spotapaw.github.io/care-a-paw-site/account/'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(children: [
                      apawIconChip('common-privacy', size: 40),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your a-Paw account',
                                style: apawText(
                                    size: 16,
                                    color: ApawColors.forest,
                                    weight: FontWeight.w700)),
                            Text('Change your email or password, or delete '
                                'your account for every a-Paw app.',
                                style: apawText(
                                    size: 13, color: ApawColors.muted)),
                          ],
                        ),
                      ),
                      apawIcon('common-open-website',
                          color: ApawColors.muted, size: 18),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  apawSecondary('Sign out', _signOut),
                ],
              ),
            ),
          ],
        ),
      ),
      const FeedNavBar(current: 'AccountPage'),
      ]),
    );
  }
}
