import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '/app_state.dart';
import '/backend/supabase/supabase.dart';
import '/custom_code/widgets/feed_icons.dart'
    show
        apawIconChips,
        apawPaper,
        apawPrimary,
        apawSecondary,
        apawText,
        apawThemed,
        ApawColors;

/// Logging a stop on the round, on the region's paper.
///
/// The spot is picked from chips rather than a list of plain rows, the counts
/// and the note each sit on their own paper, and the photograph is taken,
/// uploaded and recorded in one place.
///
/// The spot list is the feeding spots that are still active; a driver with no
/// run under way is told so rather than shown an empty form that cannot save.
class FeedStopForm extends StatefulWidget {
  const FeedStopForm({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<FeedStopForm> createState() => _FeedStopFormState();
}

class _FeedStopFormState extends State<FeedStopForm> {
  List<Map<String, dynamic>> _spots = [];
  String _spotId = '';
  final _meals = TextEditingController(text: '0');
  final _seen = TextEditingController(text: '0');
  final _note = TextEditingController();
  String _photo = '';
  bool _looking = true;

  /// Spots already logged on tonight's run.
  Set<String> _fed = <String>{};
  bool _uploading = false;
  bool _saving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadSpots();
  }

  @override
  void dispose() {
    _meals.dispose();
    _seen.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Which spots this driver is being asked about tonight.
  ///
  /// Picking a route on the driver screen loads its stops in order and sets
  /// `currentRouteId`, and this form then ignored all of it and offered every
  /// active spot in the city, alphabetically. The empty state on that screen
  /// promises "Pick a route and start a round, and the places will tick off as
  /// they are fed"; nothing ticked off and the route was decoration.
  ///
  /// Now it asks the route plan for tonight's spots **in the order they are
  /// driven**, and marks the ones already logged on this run. Without a route
  /// it falls back to every active spot, which is what a driver running an
  /// unplanned round needs.
  Future<void> _loadSpots() async {
    final route = FFAppState().currentRouteId;
    try {
      List<Map<String, dynamic>> spots;
      if (route.isNotEmpty) {
        final got = await SupaFlow.client
            .from('feed_route_plan')
            .select('spot_id, spot_name, position')
            .eq('route_id', route)
            .order('position', ascending: true);
        spots = [
          for (final r in got)
            {'id': r['spot_id'], 'name': r['spot_name']}
        ];
      } else {
        final got = await SupaFlow.client
            .from('feed_spots')
            .select('id, name')
            .eq('active', true)
            .order('name', ascending: true);
        spots = [for (final r in got) Map<String, dynamic>.from(r)];
      }

      // The ones already fed tonight, so a driver can see what is left
      // without remembering it.
      var done = <String>{};
      final run = FFAppState().currentRunId;
      if (run.isNotEmpty) {
        try {
          final got = await SupaFlow.client
              .from('feed_run_stops')
              .select('spot_id')
              .eq('run_id', run);
          done = {
            for (final r in got)
              if ((r['spot_id'] ?? '').toString().isNotEmpty)
                r['spot_id'].toString()
          };
        } catch (_) {
          // A tick missing is better than a form that will not open.
        }
      }

      if (mounted) {
        setState(() {
          _spots = spots;
          _fed = done;
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
    final run = FFAppState().currentRunId;
    if (run.isEmpty) {
      setState(() => _error = 'Start the round first, on the driver screen.');
      return;
    }
    if (_spotId.isEmpty) {
      setState(() => _error = 'Which spot is this?');
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      await SupaFlow.client.from('feed_run_stops').insert({
        'run_id': run,
        'spot_id': _spotId,
        'meals_served': int.tryParse(_meals.text.trim()) ?? 0,
        'animals_seen': int.tryParse(_seen.text.trim()) ?? 0,
        'note': _note.text.trim(),
        'photo_path': _photo,
        'arrived_at': DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stop logged.')));
        Navigator.of(context).maybePop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'That did not save. Try again in a moment.');
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  InputDecoration _field(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ApawColors.sand),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ApawColors.sand),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_looking) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
              width: 22, height: 22, child: CircularProgressIndicator()),
        ),
      );
    }

    return apawThemed(Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        apawPaper(
          title: 'Which spot',
          icon: 'feed-map-feeding-spot',
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _spots.isEmpty
                ? Text(
                    FFAppState().currentRouteId.isEmpty
                        ? 'No feeding spots yet.'
                        : 'This route has no spots on it yet.',
                    style: apawText(size: 13.5, color: ApawColors.muted))
                : apawIconChips<String>(
                    {
                      // A spot already logged tonight carries the finished
                      // drawing and says so, so a driver can see what is left
                      // without holding the round in their head. Still
                      // tappable: a stop sometimes has to be logged twice,
                      // and refusing would be worse than a duplicate.
                      for (final s in _spots)
                        s['id'].toString(): (
                          _fed.contains(s['id'].toString())
                              ? '${(s['name'] ?? '').toString()} · fed'
                              : (s['name'] ?? '').toString(),
                          (_fed.contains(s['id'].toString())
                              ? 'feed-team-finish-filled'
                              : 'feed-map-feeding-spot') as Object?
                        )
                    },
                    _spotId,
                    (v) => setState(() => _spotId = v),
                  ),
          ),
        ),
        apawPaper(
          title: 'What happened here',
          icon: 'feed-today-counter',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                  controller: _meals,
                  keyboardType: TextInputType.number,
                  decoration: _field('Meals served')),
              const SizedBox(height: 10),
              TextField(
                  controller: _seen,
                  keyboardType: TextInputType.number,
                  decoration: _field('Animals seen')),
              const SizedBox(height: 10),
              TextField(
                  controller: _note,
                  maxLines: 3,
                  decoration: _field('Anything worth saying')),
              const SizedBox(height: 10),
            ],
          ),
        ),
        apawPaper(
          title: 'A photograph',
          icon: 'common-camera',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_photo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_photo,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  ),
                ),
              apawSecondary(
                _uploading
                    ? 'Uploading…'
                    : (_photo.isEmpty
                        ? 'Take a photograph'
                        : 'Take a different one'),
                _uploading ? null : _takePhoto,
                icon: 'common-camera',
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        if (_error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_error,
                textAlign: TextAlign.center,
                style: apawText(size: 13.5, color: ApawColors.lost)),
          ),
        apawPrimary(_saving ? 'Saving…' : 'Save this stop',
            _saving ? null : _save,
            busy: _saving, icon: 'common-done'),
        const SizedBox(height: 10),
      ],
    ));
  }
}
