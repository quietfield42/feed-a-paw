import '/custom_code/widgets/feed_icons.dart'
    show apawDisplay, apawIcon, apawLogo, apawText, ApawColors;

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
    // A page reached from the bottom bar was arrived at with `go`, which
    // replaces the stack, so there is nothing to pop and a back button would
    // be a lie. Those pages get the app's mark instead and this is simply the
    // family header. A page you were pushed to can pop, and gets the button.
    final canGoBack = Navigator.of(context).canPop();
    // The page's own padding already holds this off the edge, so the bar
    // takes none of its own on the sides and lines up with what follows.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        if (!canGoBack) apawLogo('feed', size: 38),
        if (canGoBack) Material(
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
