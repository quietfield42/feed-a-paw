import '/custom_code/widgets/feed_icons.dart'
    show apawCard, apawText, ApawColors;

/// The stories from the street, with a picture only where there is one.
///
/// A story written up without a photograph had nowhere to put one, and
/// FlutterFlow's image widget insists an address is there — the same grey
/// hole Adopt had. Drawn here instead, so a story is a story either way.
class FeedStoryList extends StatelessWidget {
  const FeedStoryList({
    super.key,
    this.width,
    this.height,
    this.items,
  });

  final double? width;
  final double? height;

  /// The stories, newest first.
  final List<dynamic>? items;

  String? _field(dynamic row, String name) {
    try {
      final v = row.data?[name] ?? row[name];
      return v?.toString();
    } catch (_) {
      return null;
    }
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  String _when(String? raw) {
    final d = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    if (d == null) return '';
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    return '${d.day} ${_months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = items ?? const [];
    if (rows.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final s = rows[i];
        final photo = _field(s, 'photo_path') ?? '';
        final where = [
          _field(s, 'area') ?? '',
          _when(_field(s, 'published_at')),
        ].where((x) => x.isNotEmpty).join(' · ');
        return apawCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      photo,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              if ((_field(s, 'title') ?? '').isNotEmpty)
                Text(_field(s, 'title')!,
                    style: apawText(
                        size: 17,
                        color: ApawColors.forest,
                        weight: FontWeight.w700)),
              if ((_field(s, 'words') ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_field(s, 'words')!,
                      style: apawText(size: 14.5, height: 1.5)),
                ),
              if (where.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(where,
                      style: apawText(size: 12.5, color: ApawColors.muted)),
                ),
            ],
          ),
        );
      },
    );
  }
}
