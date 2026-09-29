import '/custom_code/widgets/feed_icons.dart'
    show apawEmptyState;

/// Says so when a list has nothing in it, using the pack's own drawing.
///
/// It takes the list itself rather than a flag, and decides for itself: a
/// screen cannot then get into the state where the list is empty and the
/// picture is hidden, or the other way round.
class FeedEmptyRounds extends StatefulWidget {
  const FeedEmptyRounds({
    super.key,
    this.width,
    this.height,
    required this.which,
    this.items,
  });

  final double? width;
  final double? height;

  /// Which empty state: the keys are in the map below.
  final String which;

  /// The list this stands in for. Null or empty means show the drawing.
  final List<dynamic>? items;

  @override
  State<FeedEmptyRounds> createState() => _FeedEmptyState();
}

class _FeedEmptyState extends State<FeedEmptyRounds> {
  static const _states = <String, List<String>>{
    'stories': ['feed-empty-no-stories', 'No stories yet',
        'When the truck goes out, the photographs and a few words from the round land here.'],
    'rounds': ['feed-empty-no-rounds', 'No round tonight',
        'Pick a route and start a round, and the places will tick off as they are fed.'],
  };

  @override
  Widget build(BuildContext context) {
    if ((widget.items ?? const []).isNotEmpty) return const SizedBox.shrink();
    final s = _states[widget.which] ?? _states.values.first;
    return apawEmptyState(s[0], s[1], s[2]);
  }
}
