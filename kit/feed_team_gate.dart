import '/backend/supabase/supabase.dart';
import '/custom_code/widgets/feed_icons.dart'
    show apawIcon, apawPaper, apawText, ApawColors;

/// Says plainly when somebody is signed in but not on the feeding team.
///
/// Every table the round writes to, and the photograph bucket, are gated on
/// `feed_is_team()`, and only a lead can add somebody to `feed_team`. So a
/// person who signs up out of interest can read everything and publish
/// nothing — and until now the Round screen told them none of that. It
/// offered "Start the round", the insert was refused by the database, the
/// action chain stopped at that line, and the button simply did nothing.
///
/// A dead button with no message is the worst of the three possible answers.
/// This is the second best: say so before they press it. The best would be to
/// hide the button, which cannot be done without binding it to a condition,
/// and a condition on that screen is more likely to break than this is.
///
/// It renders nothing at all while it is asking, and nothing for a person who
/// is on the team, so the screen is unchanged for everyone who belongs there.
class FeedTeamGate extends StatefulWidget {
  const FeedTeamGate({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<FeedTeamGate> createState() => _FeedTeamGateState();
}

class _FeedTeamGateState extends State<FeedTeamGate> {
  /// Null while we do not yet know. Nothing is drawn in that state, so the
  /// panel never flashes at a driver who is about to be told they belong.
  bool? _onTheTeam;

  @override
  void initState() {
    super.initState();
    _ask();
  }

  Future<void> _ask() async {
    final me = SupaFlow.client.auth.currentUser;
    if (me == null) {
      // Signed out: the sign-in panel is already saying its piece.
      if (mounted) setState(() => _onTheTeam = true);
      return;
    }
    try {
      final got = await SupaFlow.client.rpc('feed_is_team');
      if (mounted) setState(() => _onTheTeam = got == true);
    } catch (_) {
      // A question we could not ask is not an answer of "no". Stay quiet
      // rather than tell somebody on the team that they are not.
      if (mounted) setState(() => _onTheTeam = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onTheTeam != false) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: apawPaper(
        title: 'You are not on the feeding team yet',
        icon: 'feed-role-feeder',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rounds are run by the team who drive them, and a lead adds '
              'people to it. Until somebody adds you, starting a round here '
              'will not do anything.',
              style: apawText(size: 14, color: ApawColors.ink),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child: apawIcon('feed-nav-stories',
                      size: 18, color: ApawColors.orange),
                ),
                Expanded(
                  child: Text(
                    'You can still follow every round: Tonight carries the '
                    'meal counts and Stories carries what happened out there.',
                    style: apawText(size: 13.5, color: ApawColors.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
