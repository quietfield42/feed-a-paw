import '/custom_code/widgets/feed_icons.dart' show apawNavBar;

/// The family's bottom bar: pack icons, labels, forest for the one you are on.
///
/// FlutterFlow's own bar carries an icon and nothing else — no labels, and no
/// way to give it the pack's drawings — so each main screen draws this one
/// instead. It sits at the bottom of the page's stack, over the scenery, and
/// the empty space above it passes taps through to the page.
class FeedNavBar extends StatelessWidget {
  const FeedNavBar({
    super.key,
    this.width,
    this.height,
    required this.current,
  });

  final double? width;
  final double? height;

  /// The page this bar is sitting on, e.g. 'TodayPage'.
  final String current;

  static const _places = <(String, String, String)>[
    ('feed-nav-today', 'Tonight', 'TodayPage'),
    ('feed-nav-stories', 'Stories', 'StoriesPage'),
    ('feed-nav-driver', 'Round', 'DriverPage'),
    ('feed-nav-about', 'About', 'AboutPage'),
    ('feed-role-feeder', 'Account', 'AccountPage'),
  ];

  @override
  Widget build(BuildContext context) {
    final here = _places.indexWhere((p) => p.$3 == current);
    return SizedBox.expand(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: apawNavBar(
          index: here < 0 ? 0 : here,
          onTap: (i) {
            if (_places[i].$3 == current) return;
            context.goNamed(_places[i].$3);
          },
          items: [for (final p in _places) (p.$1, p.$2)],
        ),
      ),
    );
  }
}
