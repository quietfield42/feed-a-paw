import '/custom_code/widgets/feed_icons.dart'
    show apawDisplay, apawIcon, apawText, ApawColors;

/// The top of a page you arrived at from somewhere else.
///
/// FlutterFlow's own bar draws its back arrow in a colour the project cannot
/// set — every field that would change it is marked legacy in the proto — and
/// on the regional papers that arrow comes out the same shade as the paper
/// behind it. So the bar goes, and this stands in its place: a round button
/// you can see on any of the skins, then the page's name in the family's
/// display face.
class FeedTopBar extends StatelessWidget {
  const FeedTopBar({
    super.key,
    this.width,
    this.height,
    required this.title,
    this.subtitle,
  });

  final double? width;
  final double? height;

  /// The page's name.
  final String title;

  /// An optional quiet line under it.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 6),
      child: Row(children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(side: BorderSide(color: ApawColors.sand)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).maybePop(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: apawIcon('common-back',
                    color: ApawColors.forest, size: 22),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: apawDisplay(size: 23)),
              if (sub != null && sub.isNotEmpty)
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: apawText(size: 13, color: ApawColors.muted)),
            ],
          ),
        ),
      ]),
    );
  }
}
