import '/custom_code/widgets/feed_icons.dart' show apawBackground;

/// The chosen skin's scenery, to sit behind a page.
///
/// The kit's own pages wrap themselves in `apawBackground(child: ...)`, but a
/// FlutterFlow page cannot be wrapped from the outside, so the scenery goes in
/// as the bottom layer of a stack and the page's own content sits on top of it.
///
/// Only three scenes are light enough for dark lettering in every region —
/// paws, rescues and onboarding — and the kit falls back to paws for anything
/// else, so passing the wrong one is safe.
class FeedSkin extends StatefulWidget {
  const FeedSkin({
    super.key,
    this.width,
    this.height,
    this.scene = 'paws',
  });

  final double? width;
  final double? height;

  /// 'paws', 'rescues' or 'onboarding'.
  final String scene;

  @override
  State<FeedSkin> createState() => _FeedSkinState();
}

class _FeedSkinState extends State<FeedSkin> {
  @override
  Widget build(BuildContext context) => SizedBox.expand(
        child: apawBackground(
          scene: widget.scene,
          child: const SizedBox.expand(),
        ),
      );
}
