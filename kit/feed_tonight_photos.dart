import '/backend/supabase/supabase.dart';
import '/custom_code/widgets/feed_icons.dart'
    show apawText, ApawColors;

/// The photographs taken on tonight's round, as they are taken.
///
/// A driver takes a picture at a stop and until now it went into the bucket
/// and was never seen again. This is the evening's own strip of them: proof
/// the food went out, and the stories the next day's posts are made from.
class FeedTonightPhotos extends StatefulWidget {
  const FeedTonightPhotos({
    super.key,
    this.width,
    this.height,
    this.runId,
  });

  final double? width;
  final double? height;

  /// The round being driven.
  final String? runId;

  @override
  State<FeedTonightPhotos> createState() => _FeedTonightPhotosState();
}

class _FeedTonightPhotosState extends State<FeedTonightPhotos> {
  List<String> _photos = [];
  String? _for;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FeedTonightPhotos old) {
    super.didUpdateWidget(old);
    if (old.runId != widget.runId) _load();
  }

  Future<void> _load() async {
    final run = widget.runId;
    _for = run;
    if (run == null || run.isEmpty) {
      if (mounted) setState(() => _photos = []);
      return;
    }
    try {
      final rows = await SupaFlow.client
          .from('feed_run_stops')
          .select('photo_path, position')
          .eq('run_id', run)
          .order('position', ascending: true);
      final found = <String>[];
      for (final r in rows) {
        final p = (r['photo_path'] ?? '').toString();
        if (p.isNotEmpty) found.add(p);
      }
      if (mounted && _for == run) setState(() => _photos = found);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text('Tonight, in pictures',
              style: apawText(size: 13, color: ApawColors.muted)),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _photos[i],
                width: 140,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
