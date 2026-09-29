import '/custom_code/widgets/feed_icons.dart'
    show apawHeader;

/// The top of a main screen: the app's mark, then the screen's name in the
/// family's display face, left aligned.
///
/// Every app in the family has the same one, so moving between them feels
/// like moving between rooms rather than between buildings.
class FeedHeader extends StatefulWidget {
  const FeedHeader({
    super.key,
    this.width,
    this.height,
    required this.title,
    this.subtitle,
  });

  final double? width;
  final double? height;

  /// The screen's name.
  final String title;

  /// An optional quiet line under it.
  final String? subtitle;

  @override
  State<FeedHeader> createState() => _FeedHeaderState();
}

class _FeedHeaderState extends State<FeedHeader> {
  @override
  Widget build(BuildContext context) {
    final sub = widget.subtitle;
    return apawHeader(
      'feed',
      widget.title,
      subtitle: (sub == null || sub.isEmpty) ? null : sub,
    );
  }
}
