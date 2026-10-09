import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '/backend/supabase/supabase.dart';
import '/custom_code/widgets/feed_icons.dart'
    show
        apawIconChips,
        apawPaper,
        apawPrimary,
        apawText,
        ApawColors;

/// A feed somebody did on their own, away from the truck.
///
/// `feed_volunteer_feeds` has been in the schema since the first migration,
/// with its own insert, update and delete policies and a `feeder` role in
/// `feed_team` — and nothing in the app has ever written a row. A person could
/// be made a feeder and then had nothing whatever to do.
///
/// It is worse than an idle table. The public counter is built like this:
///
/// ```sql
/// create or replace view public.feed_meals_daily as
///   select r.day, s.meals_served from feed_runs r join feed_run_stops s ...
///   union all
///   select (v.fed_at ...)::date, v.meals_served from feed_volunteer_feeds v
/// ```
///
/// The number on Tonight — the one the whole app is built around — was
/// designed to include the meals volunteers hand out, and that half has
/// always been zero. Every meal given out away from the truck went uncounted,
/// which is the opposite of what Feed-a-Paw is for.
///
/// The form deliberately mirrors the round's stop form, because it is the same
/// job done by one person: which spot, how many meals, how many animals, a
/// note, a photograph. What it does not need is a run — a volunteer has no
/// round to belong to, and the spot list is every active spot rather than a
/// route's.
class FeedVolunteerForm extends StatefulWidget {
  const FeedVolunteerForm({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<FeedVolunteerForm> createState() => _FeedVolunteerFormState();
}

class _FeedVolunteerFormState extends State<FeedVolunteerForm> {
  List<Map<String, dynamic>> _spots = [];
  String _spotId = '';
  final _meals = TextEditingController(text: '0');
  final _seen = TextEditingController(text: '0');
  final _note = TextEditingController();
  String _photo = '';
  bool _looking = true;
  bool _uploading = false;
  bool _saving = false;
  bool _allowed = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _meals.dispose();
    _seen.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    // Only the team may write a feed, so only the team is shown the form.
    // Everybody else gets nothing at all rather than a form the database will
    // refuse — the same lesson as the round's dead Start button.
    try {
      final team = await SupaFlow.client.rpc('feed_is_team');
      if (mounted) setState(() => _allowed = team == true);
    } catch (_) {
      if (mounted) setState(() => _allowed = false);
    }
    if (!_allowed) {
      if (mounted) setState(() => _looking = false);
      return;
    }
    try {
      final got = await SupaFlow.client
          .from('feed_spots')
          .select('id, name')
          .eq('active', true)
          .order('name', ascending: true);
      if (mounted) {
        setState(() {
          _spots = [for (final r in got) Map<String, dynamic>.from(r)];
          _looking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _looking = false);
    }
  }

  Future<void> _takePhoto() async {
    if (_uploading) return;
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.camera, maxWidth: 1600);
      final shot = picked ??
          await ImagePicker()
              .pickImage(source: ImageSource.gallery, maxWidth: 1600);
      if (shot == null) return;
      setState(() {
        _uploading = true;
        _error = '';
      });
      final Uint8List bytes = await shot.readAsBytes();
      final me = SupaFlow.client.auth.currentUser?.id ?? 'anon';
      final ext = shot.name.contains('.')
          ? shot.name.split('.').last.toLowerCase()
          : 'jpg';
      final path = '$me/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await SupaFlow.client.storage.from('feed-photos').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
                contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
                upsert: true),
          );
      final url =
          SupaFlow.client.storage.from('feed-photos').getPublicUrl(path);
      if (mounted) setState(() => _photo = url);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'That photograph did not upload. Try again.');
      }
    }
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _save() async {
    if (_saving) return;
    final me = SupaFlow.client.auth.currentUser?.id;
    if (me == null) {
      setState(() => _error = 'Sign in first.');
      return;
    }
    if (_spotId.isEmpty) {
      setState(() => _error = 'Which spot was it?');
      return;
    }
    final meals = int.tryParse(_meals.text.trim()) ?? 0;
    if (meals <= 0) {
      setState(() => _error = 'How many meals did you hand out?');
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      await SupaFlow.client.from('feed_volunteer_feeds').insert({
        'spot_id': _spotId,
        'fed_by': me,
        'meals_served': meals,
        'animals_seen': int.tryParse(_seen.text.trim()) ?? 0,
        'note': _note.text.trim(),
        if (_photo.isNotEmpty) 'photo_path': _photo,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Counted. Thank you for going out.')));
        setState(() {
          _spotId = '';
          _meals.text = '0';
          _seen.text = '0';
          _note.clear();
          _photo = '';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'That did not save. Try again in a moment.');
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  InputDecoration _box(String label) => InputDecoration(
        labelText: label,
        labelStyle: apawText(size: 13, color: ApawColors.muted),
        isDense: true,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    if (_looking) return const SizedBox.shrink();
    // Not on the team: the round screen already explains why, and a second
    // panel saying the same thing twice helps nobody.
    if (!_allowed) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        apawPaper(
          title: 'Fed some animals yourself?',
          icon: 'feed-role-feeder',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Away from the truck still counts. What you put down here '
                  'adds to the total for tonight with everything else.',
                  style: apawText(size: 13.5, color: ApawColors.muted),
                ),
              ),
              if (_spots.isEmpty)
                Text('No feeding spots yet.',
                    style: apawText(size: 13.5, color: ApawColors.muted))
              else
                apawIconChips<String>(
                  {
                    for (final s in _spots)
                      s['id'].toString(): (
                        (s['name'] ?? '').toString(),
                        'feed-map-feeding-spot' as Object?
                      )
                  },
                  _spotId,
                  (v) => setState(() => _spotId = v),
                ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _meals,
                    keyboardType: TextInputType.number,
                    decoration: _box('Meals'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _seen,
                    keyboardType: TextInputType.number,
                    decoration: _box('Animals seen'),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              TextField(
                controller: _note,
                maxLines: 2,
                decoration: _box('Anything worth knowing'),
              ),
              const SizedBox(height: 10),
              apawPrimary(
                _uploading
                    ? 'Sending the photograph…'
                    : (_photo.isEmpty ? 'Add a photograph' : 'Photograph added'),
                _uploading ? null : _takePhoto,
                icon: 'common-camera',
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error,
                      style: apawText(size: 13, color: ApawColors.lost)),
                ),
              const SizedBox(height: 10),
              apawPrimary(
                _saving ? 'Counting…' : 'Count this feed',
                _saving ? null : _save,
                busy: _saving,
                icon: 'common-done',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
