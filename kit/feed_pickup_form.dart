import '/app_state.dart';
import '/backend/supabase/supabase.dart';
import '/custom_code/widgets/feed_icons.dart'
    show apawPaper, apawPrimary, apawText, apawThemed, ApawColors;

/// Logging a pickup from a butcher, on the region's paper.
///
/// A driver with no round under way is told so, rather than filling the form
/// in and finding it cannot save: a collection belongs to a run, and without
/// one the database has nothing to attach it to.
class FeedPickupForm extends StatefulWidget {
  const FeedPickupForm({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<FeedPickupForm> createState() => _FeedPickupFormState();
}

class _FeedPickupFormState extends State<FeedPickupForm> {
  final _butcher = TextEditingController();
  final _kilos = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  String _error = '';

  @override
  void dispose() {
    _butcher.dispose();
    _kilos.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final run = FFAppState().currentRunId;
    if (run.isEmpty) {
      setState(() => _error = 'Start the round first, on the driver screen.');
      return;
    }
    if (_butcher.text.trim().isEmpty) {
      setState(() => _error = 'Which butcher was it?');
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      await SupaFlow.client.from('feed_collections').insert({
        'run_id': run,
        'butcher_name': _butcher.text.trim(),
        'kilos': num.tryParse(_kilos.text.trim()) ?? 0,
        'collected_by': SupaFlow.client.auth.currentUser?.id,
        'note': _note.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pickup logged.')));
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
  Widget build(BuildContext context) => apawThemed(Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          apawPaper(
            title: 'Where it came from',
            icon: 'feed-role-supplier',
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                  controller: _butcher,
                  decoration: _field('Which butcher')),
            ),
          ),
          apawPaper(
            title: 'How much',
            icon: 'feed-pickup-kilos',
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _kilos,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _field('Kilos'),
              ),
            ),
          ),
          apawPaper(
            title: 'Anything worth saying',
            icon: 'feed-stop-note',
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                  controller: _note, maxLines: 3, decoration: _field('Note')),
            ),
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_error,
                  textAlign: TextAlign.center,
                  style: apawText(size: 13.5, color: ApawColors.lost)),
            ),
          apawPrimary(_saving ? 'Saving…' : 'Save the pickup',
              _saving ? null : _save,
              busy: _saving, icon: 'feed-pickup-parcel'),
          const SizedBox(height: 10),
        ],
      ));
}
