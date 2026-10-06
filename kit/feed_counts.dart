import '/custom_code/widgets/feed_icons.dart'
    show apawCard, apawDisplay, apawIcon, apawText, ApawColors;

/// The page's figures, as the family's own cards.
///
/// They were plain white boxes — and on Feed, loose lines of text — which is
/// the one thing on these pages that could not follow the skin: a colour set
/// on a FlutterFlow container is a fixed colour, while the kit's card tints
/// itself with the region's paper. Drawing them here puts them under the skin
/// and gives all three apps the same card.
class FeedCounts extends StatelessWidget {
  const FeedCounts({super.key, this.width, this.height, this.mealsToday, this.mealsAllTime});

  final double? width;
  final double? height;

  /// Meals handed out today.
  final int? mealsToday;

  /// Meals since the very first round.
  final int? mealsAllTime;

  // The gap report asked for the pack's own drawing on each figure, so a
  // glance tells you which number you are looking at.
  static Widget _one(String value, String label, String icon) => Expanded(
        child: apawCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              apawIcon(icon, size: 18, color: ApawColors.orange),
              const SizedBox(height: 6),
              Text(value, maxLines: 1, style: apawDisplay(size: 26)),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 2,
                  style: apawText(size: 12.5, color: ApawColors.muted)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _one('${mealsToday ?? 0}', 'Meals served today', 'feed-today-counter'),
            const SizedBox(width: 12),
            _one('${mealsAllTime ?? 0}', 'Meals since the first round', 'common-meals-funded'),
          ],
        ),
      );
}
