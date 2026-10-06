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

  Future<void> _loadSpots() async {
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
                ? Text('No feeding spots yet.',
                    style: apawText(size: 13.5, color: ApawColors.muted))
                : apawIconChips<String>(
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
